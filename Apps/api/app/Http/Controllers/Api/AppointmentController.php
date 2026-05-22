<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\ServiceBay;
use App\Models\ServiceCategory;
use App\Models\ServiceJob;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AppointmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = Appointment::where('tenant_id', $tenantId)
            ->with([
                'customer:id,uuid,first_name,last_name,phone_primary',
                'vehicle:id,uuid,registration_number,maker,model',
                'serviceCategory:id,uuid,name',
                'assignedTechnician:id,uuid,first_name,last_name',
            ]);

        if ($date = $request->query('date')) {
            $query->whereDate('scheduled_date', $date);
        }

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        } elseif ($request->query('upcoming') === '1') {
            $query->whereIn('status', ['booked', 'confirmed'])
                ->whereDate('scheduled_date', '>=', now()->toDateString());
        }

        $appointments = $query
            ->orderBy('scheduled_date')
            ->orderBy('start_time')
            ->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $appointments->map(fn ($a) => $this->formatAppointment($a)),
            'meta'    => [
                'current_page' => $appointments->currentPage(),
                'per_page'     => $appointments->perPage(),
                'total'        => $appointments->total(),
                'last_page'    => $appointments->lastPage(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data     = $request->validate([
            'customer_uuid'            => ['required', 'string', 'exists:customers,uuid'],
            'vehicle_uuid'             => ['required', 'string', 'exists:vehicles,uuid'],
            'service_category_uuid'    => ['nullable', 'string', 'exists:service_categories,uuid'],
            'scheduled_date'           => ['required', 'date', 'after_or_equal:today'],
            'start_time'               => ['required', 'date_format:H:i'],
            'end_time'                 => ['nullable', 'date_format:H:i'],
            'assigned_technician_uuid' => ['nullable', 'string', 'exists:users,uuid'],
            'assigned_bay_uuid'        => ['nullable', 'string', 'exists:service_bays,uuid'],
            'source'                   => ['nullable', 'in:walk_in,phone,app,web,whatsapp'],
            'notes'                    => ['nullable', 'string', 'max:1000'],
        ]);

        $customer = Customer::where('uuid', $data['customer_uuid'])->firstOrFail();
        $vehicle  = Vehicle::where('uuid', $data['vehicle_uuid'])
            ->where('customer_id', $customer->id)
            ->firstOrFail();

        $categoryId = null;
        if (!empty($data['service_category_uuid'])) {
            $categoryId = ServiceCategory::where('uuid', $data['service_category_uuid'])
                ->where('tenant_id', $tenantId)
                ->value('id');
        }

        $technicianId = null;
        if (!empty($data['assigned_technician_uuid'])) {
            $technicianId = User::where('uuid', $data['assigned_technician_uuid'])
                ->where('tenant_id', $tenantId)
                ->value('id');
        }

        $bayId = null;
        if (!empty($data['assigned_bay_uuid'])) {
            $bayId = ServiceBay::where('uuid', $data['assigned_bay_uuid'])
                ->where('tenant_id', $tenantId)
                ->value('id');
        }

        $startTime = $data['start_time'] . ':00';
        $endTime   = ($data['end_time'] ?? $this->defaultEndTime($data['start_time'])) . ':00';

        $appointment = Appointment::create([
            'tenant_id'              => $tenantId,
            'customer_id'            => $customer->id,
            'vehicle_id'             => $vehicle->id,
            'service_category_id'    => $categoryId,
            'scheduled_date'         => $data['scheduled_date'],
            'start_time'             => $startTime,
            'end_time'               => $endTime,
            'status'                 => 'booked',
            'source'                 => $data['source'] ?? 'phone',
            'assigned_technician_id' => $technicianId,
            'assigned_bay_id'        => $bayId,
            'notes'                  => $data['notes'] ?? null,
            'created_by'             => $request->user()->id,
        ]);

        AuditLog::record('appointment.created', 'appointments', $appointment->id);

        $appointment->load(['customer', 'vehicle', 'serviceCategory', 'assignedTechnician']);

        return response()->json([
            'success' => true,
            'data'    => $this->formatAppointment($appointment),
            'message' => 'Appointment booked.',
        ], 201);
    }

    public function checkIn(Request $request, string $uuid): JsonResponse
    {
        $tenantId    = $request->user()->tenant_id;
        $appointment = Appointment::where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->with(['customer', 'vehicle', 'serviceCategory'])
            ->firstOrFail();

        if ($appointment->converted_job_id) {
            throw ValidationException::withMessages([
                'appointment' => ['This appointment was already checked in.'],
            ]);
        }

        if (!in_array($appointment->status, ['booked', 'confirmed'], true)) {
            throw ValidationException::withMessages([
                'appointment' => ['Only booked or confirmed appointments can be checked in.'],
            ]);
        }

        $data = $request->validate([
            'odometer_at_intake' => ['nullable', 'integer', 'min:0'],
            'fuel_level'         => ['nullable', 'in:empty,quarter,half,three_quarter,full'],
        ]);

        $job = ServiceJob::withoutGlobalScope('tenant')->create([
            'tenant_id'              => $tenantId,
            'customer_id'            => $appointment->customer_id,
            'vehicle_id'             => $appointment->vehicle_id,
            'status'                 => 'checked_in',
            'odometer_at_intake'     => $data['odometer_at_intake'] ?? $appointment->vehicle?->odometer_reading,
            'fuel_level'             => $data['fuel_level'] ?? null,
            'primary_technician_id'  => $appointment->assigned_technician_id,
            'assigned_bay_id'        => $appointment->assigned_bay_id,
            'customer_complaint'     => $appointment->notes,
            'created_by'             => $request->user()->id,
            'scheduled_start_at'     => $appointment->scheduled_date->format('Y-m-d') . ' ' . $appointment->start_time,
        ]);

        if ($appointment->service_category_id) {
            $job->serviceCategories()->sync([$appointment->service_category_id]);
        }

        $appointment->update([
            'status'           => 'checked_in',
            'converted_job_id' => $job->id,
        ]);

        AuditLog::record('appointment.checked_in', 'appointments', $appointment->id, [], [
            'job_id' => $job->id,
        ]);

        $job->load(['customer', 'vehicle']);

        return response()->json([
            'success' => true,
            'data'    => [
                'appointment_uuid'   => $appointment->uuid,
                'appointment_status' => $appointment->status,
                'job'                => [
                    'uuid'       => $job->uuid,
                    'job_number' => $job->job_number,
                    'status'     => $job->status,
                ],
            ],
            'message' => "Customer checked in. Job {$job->job_number} created.",
        ]);
    }

    private function defaultEndTime(string $startTime): string
    {
        [$h, $m] = array_map('intval', explode(':', $startTime));
        $h += 2;

        return sprintf('%02d:%02d', min($h, 23), $m);
    }

    private function formatAppointment(Appointment $appointment): array
    {
        return [
            'uuid'                  => $appointment->uuid,
            'appointment_number'    => $appointment->appointment_number,
            'status'                => $appointment->status,
            'scheduled_date'        => $appointment->scheduled_date?->format('Y-m-d'),
            'start_time'            => substr((string) $appointment->start_time, 0, 5),
            'end_time'              => substr((string) $appointment->end_time, 0, 5),
            'source'                => $appointment->source,
            'notes'                 => $appointment->notes,
            'customer_acknowledged' => (bool) $appointment->customer_acknowledged,
            'converted_job_uuid'    => $appointment->convertedJob?->uuid,
            'customer'              => $appointment->customer ? [
                'uuid'  => $appointment->customer->uuid,
                'name'  => $appointment->customer->full_name,
                'phone' => $appointment->customer->phone_primary,
            ] : null,
            'vehicle'               => $appointment->vehicle ? [
                'uuid'                 => $appointment->vehicle->uuid,
                'registration_number'  => $appointment->vehicle->registration_number,
                'display'                => $appointment->vehicle->display_name,
            ] : null,
            'service_category'      => $appointment->serviceCategory ? [
                'uuid' => $appointment->serviceCategory->uuid,
                'name' => $appointment->serviceCategory->name,
            ] : null,
            'assigned_technician'   => $appointment->assignedTechnician ? [
                'uuid' => $appointment->assignedTechnician->uuid,
                'name' => $appointment->assignedTechnician->full_name,
            ] : null,
        ];
    }
}
