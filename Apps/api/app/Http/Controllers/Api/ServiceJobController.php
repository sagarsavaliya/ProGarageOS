<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceJob;
use App\Models\ServiceCategory;
use App\Models\Customer;
use App\Models\Vehicle;
use App\Models\AuditLog;
use App\Models\User;
use App\Models\InspectionTemplate;
use App\Models\JobInspectionRecord;
use App\Jobs\GenerateInspectionSummaryJob;
use App\Services\InspectionMediaService;
use App\Services\PushNotificationService;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceJobController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = ServiceJob::where('tenant_id', $tenantId)->withoutGlobalScope('tenant')
            ->with([
                'customer:id,uuid,first_name,last_name,phone_primary',
                'vehicle:id,uuid,maker,model,registration_number',
                'primaryTechnician:id,uuid,first_name,last_name',
                'assignedBay:id,uuid,name,code',
            ]);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($priority = $request->query('priority')) {
            $query->where('priority', $priority);
        }

        if ($search = $request->query('search')) {
            $query->where(fn ($q) => $q
                ->where('job_number', 'like', "%{$search}%")
                ->orWhereHas('customer', fn ($q2) => $q2->where('first_name', 'like', "%{$search}%")->orWhere('phone_primary', 'like', "%{$search}%"))
                ->orWhereHas('vehicle', fn ($q2) => $q2->where('registration_number', 'like', "%{$search}%"))
            );
        }

        $sort      = $request->query('sort', 'created_at');
        $direction = $request->query('direction', 'desc');
        $jobs      = $query->orderBy($sort, $direction)->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $jobs->map(fn ($j) => $this->formatJob($j)),
            'meta'    => [
                'current_page' => $jobs->currentPage(),
                'per_page'     => $jobs->perPage(),
                'total'        => $jobs->total(),
                'last_page'    => $jobs->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $job      = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->with([
                'customer', 'vehicle', 'primaryTechnician',
                'assignedBay', 'tasks.serviceItem', 'tasks.assignedTechnician',
                'invoice', 'serviceCategories', 'inspectionRecords',
            ])
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $this->formatJob($job, true)]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data = $request->validate([
            'customer_uuid'        => ['required', 'string', 'exists:customers,uuid'],
            'vehicle_uuid'         => ['required', 'string', 'exists:vehicles,uuid'],
            'priority'             => ['in:low,normal,urgent,critical'],
            'customer_complaint'   => ['nullable', 'string'],
            'odometer_at_intake'   => ['nullable', 'integer', 'min:0'],
            'fuel_level'           => ['nullable', 'in:empty,quarter,half,three_quarter,full'],
            'delivery_method'      => ['in:pickup,drop,doorstep'],
            'scheduled_start_at'   => ['nullable', 'date'],
            'service_category_uuids' => ['nullable', 'array'],
            'service_category_uuids.*' => ['string', 'exists:service_categories,uuid'],
            'is_insurance_job'       => ['boolean'],
            'insurance_company'      => ['nullable', 'string', 'max:150'],
            'claim_number'           => ['nullable', 'string', 'max:100'],
            'insurance_survey_at'    => ['nullable', 'date'],
        ]);

        $customer = Customer::where('uuid', $data['customer_uuid'])->firstOrFail();
        $vehicle  = Vehicle::where('uuid', $data['vehicle_uuid'])->where('customer_id', $customer->id)->firstOrFail();

        $categoryIds = $this->resolveCategoryIds($tenantId, $data['service_category_uuids'] ?? []);
        unset($data['service_category_uuids'], $data['customer_uuid'], $data['vehicle_uuid']);

        $isInsuranceCategory = $this->hasInsuranceCategory($tenantId, $categoryIds);
        if ($isInsuranceCategory) {
            $data['is_insurance_job'] = true;
            $data['insurance_claim_status'] = 'survey_pending';
        } elseif (! empty($data['is_insurance_job'])) {
            $data['insurance_claim_status'] = 'survey_pending';
        } else {
            unset($data['is_insurance_job'], $data['insurance_company'], $data['claim_number'], $data['insurance_survey_at']);
        }

        $job = ServiceJob::create([
            ...$data,
            'tenant_id'   => $tenantId,
            'customer_id' => $customer->id,
            'vehicle_id'  => $vehicle->id,
            'created_by'  => $request->user()->id,
        ]);

        if ($categoryIds !== []) {
            $job->serviceCategories()->sync($categoryIds);
        }

        AuditLog::record('job.created', 'service_jobs', $job->id, [], ['status' => 'draft', 'job_number' => $job->job_number]);

        $job->load(['customer', 'vehicle']);
        $this->pushJobAlert(
            $tenantId,
            'job_created',
            'New job created',
            "{$job->job_number} — {$job->vehicle?->registration_number}",
            ['job_uuid' => $job->uuid, 'type' => 'job'],
        );

        return response()->json(['success' => true, 'data' => $this->formatJob($job)], 201);
    }

    public function updateStatus(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data = $request->validate([
            'status' => ['required', 'in:draft,checked_in,inspecting,estimate_pending,estimate_approved,estimate_rejected,in_progress,quality_check,ready_for_delivery,delivered,cancelled,on_hold'],
            'notes'  => ['nullable', 'string'],
        ]);

        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        if (
            $data['status'] === 'ready_for_delivery'
            && config('progarageos.require_delivery_inspection', true)
        ) {
            $hasDelivery = JobInspectionRecord::where('job_id', $job->id)
                ->where('inspection_phase', 'delivery')
                ->exists();

            if (! $hasDelivery) {
                throw ValidationException::withMessages([
                    'status' => ['Complete the delivery inspection before marking ready for delivery.'],
                ]);
            }
        }

        $oldStatus = $job->status;
        $updates   = ['status' => $data['status']];

        if ($data['status'] === 'in_progress' && !$job->actual_start_at) {
            $updates['actual_start_at'] = now();
        }
        if ($data['status'] === 'delivered') {
            $updates['actual_completion_at'] = now();
        }
        if (isset($data['notes'])) {
            $updates['handover_notes'] = $data['notes'];
        }

        $job->update($updates);
        AuditLog::record('job.status_changed', 'service_jobs', $job->id, ['status' => $oldStatus], ['status' => $data['status']]);

        $job->load(['vehicle', 'primaryTechnician']);
        $statusLabel = str_replace('_', ' ', $data['status']);
        $this->pushJobAlert(
            $tenantId,
            'job_status_changed',
            "Job {$job->job_number} updated",
            "Status: " . ucwords($statusLabel),
            ['job_uuid' => $job->uuid, 'status' => $data['status'], 'type' => 'job'],
            $job->primary_technician_id ? User::find($job->primary_technician_id) : null,
        );

        return response()->json(['success' => true, 'data' => ['uuid' => $job->uuid, 'status' => $job->status]]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $data = $request->validate([
            'priority'                    => ['in:low,normal,urgent,critical'],
            'customer_complaint'          => ['nullable', 'string'],
            'primary_technician_uuid'     => ['nullable', 'string', 'exists:users,uuid'],
            'assigned_bay_uuid'           => ['nullable', 'string', 'exists:service_bays,uuid'],
            'scheduled_start_at'          => ['nullable', 'date'],
            'estimated_completion_at'     => ['nullable', 'date'],
            'delivery_method'             => ['in:pickup,drop,doorstep'],
            'handover_notes'              => ['nullable', 'string'],
            'service_category_uuids'      => ['nullable', 'array'],
            'service_category_uuids.*'    => ['string', 'exists:service_categories,uuid'],
        ]);

        if (isset($data['primary_technician_uuid'])) {
            $tech = \App\Models\User::where('uuid', $data['primary_technician_uuid'])->first();
            $data['primary_technician_id'] = $tech?->id;
            unset($data['primary_technician_uuid']);
        }

        if (isset($data['assigned_bay_uuid'])) {
            $bay = \App\Models\ServiceBay::where('uuid', $data['assigned_bay_uuid'])->first();
            $data['assigned_bay_id'] = $bay?->id;
            unset($data['assigned_bay_uuid']);
        }

        $categoryIds = null;
        if (array_key_exists('service_category_uuids', $data)) {
            $categoryIds = $this->resolveCategoryIds($tenantId, $data['service_category_uuids'] ?? []);
            unset($data['service_category_uuids']);
        }

        $job->update($data);

        if ($categoryIds !== null) {
            $job->serviceCategories()->sync($categoryIds);
        }

        AuditLog::record('job.updated', 'service_jobs', $job->id, [], $data);

        return response()->json([
            'success' => true,
            'data'    => $this->formatJob($job->fresh(['customer', 'vehicle', 'primaryTechnician', 'assignedBay', 'serviceCategories'])),
        ]);
    }

    public function updateInsuranceClaim(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $data = $request->validate([
            'insurance_claim_status'     => ['sometimes', 'in:none,survey_pending,estimate_submitted,approved,rejected,settled'],
            'insurance_company'          => ['nullable', 'string', 'max:150'],
            'claim_number'               => ['nullable', 'string', 'max:100'],
            'insurance_survey_at'        => ['nullable', 'date'],
            'customer_liability_amount'  => ['nullable', 'numeric', 'min:0'],
            'job_insurance_claim_amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        if (isset($data['insurance_claim_status']) && $data['insurance_claim_status'] !== 'none') {
            $data['is_insurance_job'] = true;
        }

        $job->update($data);

        AuditLog::record('job.insurance_updated', 'service_jobs', $job->id, [], $data);

        return response()->json([
            'success' => true,
            'data'    => $this->formatJob($job->fresh(['customer', 'vehicle', 'serviceCategories']), true),
        ]);
    }

    private function resolveCategoryIds(int $tenantId, array $uuids): array
    {
        if ($uuids === []) {
            return [];
        }

        return ServiceCategory::where('tenant_id', $tenantId)
            ->whereIn('uuid', $uuids)
            ->pluck('id')
            ->all();
    }

    private function hasInsuranceCategory(int $tenantId, array $categoryIds): bool
    {
        if ($categoryIds === []) {
            return false;
        }

        return ServiceCategory::where('tenant_id', $tenantId)
            ->whereIn('id', $categoryIds)
            ->whereIn('code', ['ACCIDENT_RPR', 'BODY_WORK'])
            ->exists();
    }

    /**
     * GET saved intake/delivery inspection for a job.
     */
    public function showInspection(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $phase    = $request->query('phase', 'intake');

        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $records = JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', $phase)
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $this->formatInspectionPayload($records, $request),
        ]);
    }

    public function compareInspections(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $job      = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $intakeRecords = JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', 'intake')
            ->get();
        $deliveryRecords = JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', 'delivery')
            ->get();

        $intakePayload   = $this->formatInspectionPayload($intakeRecords, $request);
        $deliveryPayload = $this->formatInspectionPayload($deliveryRecords, $request);

        $intakeConditions = collect($intakePayload['items'] ?? [])
            ->keyBy('component_key');
        $newDamage = [];

        foreach ($deliveryPayload['items'] ?? [] as $item) {
            $key    = $item['component_key'];
            $before = $intakeConditions->get($key);
            $after  = $item['condition_status'];
            $rank   = ['good' => 0, 'fair' => 1, 'poor' => 2, 'damaged' => 3, 'missing' => 4, 'na' => -1];
            $beforeRank = $rank[$before['condition_status'] ?? 'good'] ?? 0;
            $afterRank  = $rank[$after] ?? 0;
            if ($afterRank > $beforeRank) {
                $newDamage[] = [
                    'component_key'  => $key,
                    'component_name' => $item['component_name'],
                    'intake_status'  => $before['condition_status'] ?? 'unknown',
                    'delivery_status'=> $after,
                ];
            }
        }

        $intakeZones = collect($intakePayload['damage_zones'] ?? [])->pluck('zone');
        foreach ($deliveryPayload['damage_zones'] ?? [] as $zone) {
            if (! $intakeZones->contains($zone['zone'])) {
                $newDamage[] = [
                    'component_key'  => $zone['zone'],
                    'component_name' => $zone['zone'],
                    'intake_status'  => 'none',
                    'delivery_status'=> 'damaged',
                    'type'           => 'new_zone',
                ];
            }
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'intake'     => $intakePayload,
                'delivery'   => $deliveryPayload,
                'new_damage' => $newDamage,
            ],
        ]);
    }

    public function inspectionPdf(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $phase    = $request->query('phase', 'intake');

        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        GenerateInspectionSummaryJob::dispatchSync($job->id, $phase);

        $path = "inspections/{$job->tenant_id}/{$job->uuid}-{$phase}.html";
        $url  = Storage::disk('public')->exists($path)
            ? Storage::disk('public')->url($path)
            : null;

        return response()->json([
            'success' => true,
            'data'    => [
                'url'   => $url ? url($url) : null,
                'phase' => $phase,
            ],
        ]);
    }

    /**
     * Upload a single inspection photo (multipart). Call before or during save.
     */
    public function uploadInspectionPhoto(
        Request $request,
        string $uuid,
        InspectionMediaService $media,
    ): JsonResponse {
        $tenantId = $request->user()->tenant_id;
        $job      = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $data = $request->validate([
            'photo' => ['required', 'image', 'mimes:jpeg,jpg,png,webp', 'max:10240'],
            'slot'  => ['required', 'string', 'max:50'],
            'label' => ['nullable', 'string', 'max:100'],
        ]);

        $stored = $media->storePhoto(
            $tenantId,
            $job->uuid,
            $request->file('photo'),
            $data['slot'],
        );

        $publicUrl = url($stored['url']);

        return response()->json([
            'success' => true,
            'data'    => [
                'slot'  => $data['slot'],
                'label' => $data['label'] ?? $data['slot'],
                'path'  => $stored['path'],
                'url'   => $publicUrl,
            ],
        ], 201);
    }

    /**
     * Persist intake/delivery inspection checklist for a job.
     */
    public function storeInspection(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $job      = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $data = $request->validate([
            'inspection_phase'      => ['in:intake,delivery'],
            'notes'                 => ['nullable', 'string'],
            'customer_acknowledged' => ['boolean'],
            'items'                 => ['required', 'array', 'min:1'],
            'items.*.component_key' => ['required', 'string', 'max:100'],
            'items.*.component_name' => ['required', 'string'],
            'items.*.category'      => ['nullable', 'string', 'max:100'],
            'items.*.condition_status' => ['required', 'in:good,fair,poor,damaged,missing,na'],
            'items.*.severity'      => ['in:none,minor,moderate,severe'],
            'damage_zones'          => ['nullable', 'array'],
            'damage_zones.*.zone'   => ['required', 'string'],
            'damage_zones.*.severity' => ['required', 'in:minor,moderate,severe'],
            'photos'                => ['nullable', 'array'],
            'photos.*.slot'         => ['required', 'string', 'max:50'],
            'photos.*.label'        => ['nullable', 'string', 'max:100'],
            'photos.*.url'          => ['required', 'string', 'max:500'],
            'photos.*.path'         => ['nullable', 'string', 'max:500'],
        ]);

        $phase = $data['inspection_phase'] ?? 'intake';

        $template = InspectionTemplate::where('tenant_id', $tenantId)
            ->where('component_category', $phase)
            ->where('is_active', true)
            ->first();

        if (! $template) {
            $template = InspectionTemplate::create([
                'tenant_id'          => $tenantId,
                'name'               => ucfirst($phase) . ' Checklist',
                'code'               => "{$phase}-meta",
                'component_name'     => 'Checklist',
                'component_category' => $phase,
                'is_mandatory'       => false,
                'sort_order'         => 0,
                'is_active'          => true,
            ]);
        }

        JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', $phase)
            ->delete();

        foreach ($data['items'] as $item) {
            JobInspectionRecord::create([
                'job_id'                => $job->id,
                'template_id'           => $template->id,
                'inspection_phase'      => $phase,
                'component_name'        => $item['component_name'],
                'category'              => 'item:' . $item['component_key'],
                'condition_status'      => $item['condition_status'],
                'severity'              => $item['severity'] ?? 'none',
                'notes'                 => $data['notes'] ?? null,
                'inspected_by'          => $request->user()->id,
                'customer_acknowledged' => (bool) ($data['customer_acknowledged'] ?? false),
                'acknowledged_at'       => ($data['customer_acknowledged'] ?? false) ? now() : null,
            ]);
        }

        foreach ($data['damage_zones'] ?? [] as $zone) {
            JobInspectionRecord::create([
                'job_id'           => $job->id,
                'template_id'      => $template->id,
                'inspection_phase' => $phase,
                'component_name'   => $zone['zone'],
                'category'         => 'damage_map',
                'condition_status' => 'damaged',
                'severity'         => $zone['severity'],
                'inspected_by'     => $request->user()->id,
            ]);
        }

        if (!empty($data['photos'])) {
            JobInspectionRecord::create([
                'job_id'           => $job->id,
                'template_id'      => $template->id,
                'inspection_phase' => $phase,
                'component_name'   => 'Vehicle photos',
                'category'         => 'photos',
                'condition_status' => 'good',
                'media_urls'       => $data['photos'],
                'inspected_by'     => $request->user()->id,
            ]);
        }

        AuditLog::record('job.inspection_saved', 'service_jobs', $job->id, [], ['phase' => $phase]);

        if ($phase === 'delivery') {
            $job->update(['status' => 'quality_check']);
        }

        GenerateInspectionSummaryJob::dispatch($job->id, $phase)->afterResponse();

        $records = JobInspectionRecord::where('job_id', $job->id)
            ->where('inspection_phase', $phase)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => array_merge(
                ['uuid' => $job->uuid],
                $this->formatInspectionPayload($records, $request),
            ),
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, JobInspectionRecord>  $records
     * @return array<string, mixed>
     */
    private function formatInspectionPayload($records, Request $request): array
    {
        $items        = [];
        $damageZones  = [];
        $photos       = [];
        $notes        = null;
        $acknowledged = false;

        foreach ($records as $record) {
            if (str_starts_with((string) $record->category, 'item:')) {
                $key = substr($record->category, 5);
                $items[] = [
                    'component_key'    => $key,
                    'component_name'   => $record->component_name,
                    'condition_status' => $record->condition_status,
                    'severity'         => $record->severity,
                ];
                if ($record->notes) {
                    $notes = $record->notes;
                }
                if ($record->customer_acknowledged) {
                    $acknowledged = true;
                }
            } elseif ($record->category === 'damage_map') {
                $damageZones[] = [
                    'zone'     => $record->component_name,
                    'severity' => $record->severity,
                ];
            } elseif ($record->category === 'photos' && is_array($record->media_urls)) {
                foreach ($record->media_urls as $photo) {
                    $url = $photo['url'] ?? '';
                    if ($url !== '' && str_starts_with($url, '/')) {
                        $url = url($url);
                    }
                    $photos[] = [
                        'slot'  => $photo['slot'] ?? '',
                        'label' => $photo['label'] ?? '',
                        'url'   => $url,
                        'path'  => $photo['path'] ?? null,
                    ];
                }
            }
        }

        return [
            'inspection_phase'      => $records->first()?->inspection_phase ?? 'intake',
            'notes'                 => $notes,
            'customer_acknowledged' => $acknowledged,
            'items'                 => $items,
            'damage_zones'          => $damageZones,
            'photos'                => $photos,
            'saved_at'              => $records->max('updated_at')?->toIso8601String(),
        ];
    }

    private function formatJob(ServiceJob $job, bool $full = false): array
    {
        $base = [
            'uuid'        => $job->uuid,
            'job_number'  => $job->job_number,
            'status'      => $job->status,
            'priority'    => $job->priority,
            'customer'    => $job->customer ? [
                'uuid'  => $job->customer->uuid,
                'name'  => $job->customer->full_name,
                'phone' => $job->customer->phone_primary,
            ] : null,
            'vehicle'     => $job->vehicle ? [
                'uuid'                => $job->vehicle->uuid,
                'display'             => $job->vehicle->display_name,
                'registration_number' => $job->vehicle->registration_number,
                'fuel_type'           => $job->vehicle->fuel_type,
            ] : null,
            'technician'          => $job->primaryTechnician ? [
                'uuid' => $job->primaryTechnician->uuid,
                'name' => $job->primaryTechnician->full_name,
            ] : null,
            'primary_technician'  => $job->primaryTechnician ? [
                'uuid' => $job->primaryTechnician->uuid,
                'name' => $job->primaryTechnician->full_name,
            ] : null,
            'bay'                => $job->assignedBay ? ['uuid' => $job->assignedBay->uuid, 'name' => $job->assignedBay->name] : null,
            'estimated_amount'   => $job->estimated_amount ? (float) $job->estimated_amount : null,
            'scheduled_start_at' => $job->scheduled_start_at?->toIso8601String(),
            'actual_start_at'    => $job->actual_start_at?->toIso8601String(),
            'eta'                => $job->estimated_completion_at?->toIso8601String(),
            'created_at'         => $job->created_at->toIso8601String(),
            'insurance_claim'    => $this->formatInsuranceClaim($job),
        ];

        if ($full) {
            $base['customer_complaint'] = $job->customer_complaint;
            $base['odometer_at_intake'] = $job->odometer_at_intake;
            $base['fuel_level']         = $job->fuel_level;
            $base['tasks']              = $job->tasks->map(fn ($t) => [
                'id'                         => $t->id,
                'uuid'                       => (string) $t->id,
                'name'                       => $t->name,
                'description'                => $t->description,
                'status'                     => $t->status,
                'source'                     => $t->source,
                'estimated_price'            => (float) $t->estimated_price,
                'final_price'                => (float) $t->final_price,
                'labor_minutes'              => $t->labor_minutes,
                'requires_customer_approval' => $t->requires_customer_approval,
                'is_billable'                => $t->is_billable,
                'technician'                 => $t->assignedTechnician ? [
                    'uuid' => $t->assignedTechnician->uuid,
                    'name' => $t->assignedTechnician->full_name,
                ] : null,
            ]);
            $base['service_categories'] = $job->serviceCategories->map(fn ($c) => [
                'uuid' => $c->uuid,
                'name' => $c->name,
            ])->values();
            $base['invoice']            = $job->invoice ? ['uuid' => $job->invoice->uuid, 'status' => $job->invoice->status, 'grand_total' => (float) $job->invoice->grand_total] : null;
            $intakeRecords              = $job->relationLoaded('inspectionRecords')
                ? $job->inspectionRecords->where('inspection_phase', 'intake')
                : collect();
            $base['inspection_summary'] = $intakeRecords->isNotEmpty()
                ? $this->formatInspectionPayload($intakeRecords, request())
                : ['completed' => false];
            if ($intakeRecords->isNotEmpty()) {
                $base['inspection_summary']['completed'] = true;
            }
            $deliveryRecords = $job->relationLoaded('inspectionRecords')
                ? $job->inspectionRecords->where('inspection_phase', 'delivery')
                : collect();
            $base['delivery_inspection_completed'] = $deliveryRecords->isNotEmpty();
            $base['estimate'] = [
                'approval_status'      => $job->approval_status,
                'estimated_amount'     => $job->estimated_amount ? (float) $job->estimated_amount : null,
                'customer_approved_at' => $job->customer_approved_at?->toIso8601String(),
            ];
        }

        return $base;
    }

    private function formatInsuranceClaim(ServiceJob $job): array
    {
        return [
            'is_insurance_job'           => (bool) $job->is_insurance_job,
            'insurance_company'          => $job->insurance_company,
            'claim_number'               => $job->claim_number,
            'status'                     => $job->insurance_claim_status ?? 'none',
            'insurance_survey_at'        => $job->insurance_survey_at?->toIso8601String(),
            'customer_liability_amount'  => $job->customer_liability_amount !== null
                ? (float) $job->customer_liability_amount
                : null,
            'insurance_claim_amount'     => $job->job_insurance_claim_amount !== null
                ? (float) $job->job_insurance_claim_amount
                : null,
        ];
    }

    private function pushJobAlert(
        int $tenantId,
        string $eventCode,
        string $title,
        string $body,
        array $data,
        ?User $primaryTechnician = null,
    ): void {
        // Defer inbox + FCM so API responses return immediately (especially on mobile).
        dispatch(function () use ($tenantId, $eventCode, $title, $body, $data, $primaryTechnician) {
            $push = app(PushNotificationService::class);

            if ($primaryTechnician) {
                $push->notifyStaff($primaryTechnician, $eventCode, $title, $body, $data);
            }

            $push->notifyTenantStaff(
                $tenantId,
                $eventCode,
                $title,
                $body,
                $data,
                $primaryTechnician?->id,
            );
        })->afterResponse();
    }
}
