<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\GarageCustomer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = Customer::whereHas('garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId))
            ->with(['garageProfiles' => fn ($q) => $q->where('tenant_id', $tenantId)])
            ->with('vehicles');

        if ($search = $request->query('search')) {
            $query->where(fn ($q) => $q
                ->where('first_name', 'like', "%{$search}%")
                ->orWhere('last_name', 'like', "%{$search}%")
                ->orWhere('phone_primary', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%")
            );
        }

        $customers = $query->orderBy('first_name')
            ->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $customers->map(fn ($c) => $this->formatCustomer($c, $tenantId)),
            'meta'    => [
                'current_page' => $customers->currentPage(),
                'per_page'     => $customers->perPage(),
                'total'        => $customers->total(),
                'last_page'    => $customers->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $customer = Customer::where('uuid', $uuid)
            ->whereHas('garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId))
            ->with([
                'garageProfiles' => fn ($q) => $q->where('tenant_id', $tenantId)->with('preferredTechnician'),
                'vehicles' => fn ($q) => $q->where('is_active', true),
                'serviceJobs' => fn ($q) => $q->where('tenant_id', $tenantId)->latest()->limit(10),
            ])
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $this->formatCustomer($customer, $tenantId, true)]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data = $request->validate([
            'phone_primary'     => ['required', 'string', 'max:20'],
            'first_name'        => ['required', 'string', 'max:100'],
            'last_name'         => ['nullable', 'string', 'max:100'],
            'email'             => ['nullable', 'email'],
            'phone_secondary'   => ['nullable', 'string', 'max:20'],
            'marketing_opt_in'  => ['boolean'],
            'internal_notes'    => ['nullable', 'string'],
        ]);

        $customer = Customer::firstOrCreate(
            ['phone_primary' => $data['phone_primary']],
            array_filter([
                'first_name' => $data['first_name'],
                'last_name'  => $data['last_name'] ?? null,
                'email'      => $data['email'] ?? null,
            ])
        );

        GarageCustomer::firstOrCreate(
            ['customer_id' => $customer->id, 'tenant_id' => $tenantId],
            ['internal_notes' => $data['internal_notes'] ?? null]
        );

        return response()->json([
            'success' => true,
            'data'    => $this->formatCustomer($customer->load('garageProfiles'), $tenantId),
        ], 201);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $customer = Customer::where('uuid', $uuid)->firstOrFail();

        $data = $request->validate([
            'first_name'       => ['sometimes', 'string', 'max:100'],
            'last_name'        => ['nullable', 'string', 'max:100'],
            'email'            => ['nullable', 'email'],
            'phone_secondary'  => ['nullable', 'string', 'max:20'],
            'marketing_opt_in' => ['boolean'],
            'internal_notes'   => ['nullable', 'string'],
        ]);

        $customer->update(array_intersect_key($data, array_flip(['first_name', 'last_name', 'email', 'phone_secondary', 'marketing_opt_in'])));

        $garageProfile = GarageCustomer::where('customer_id', $customer->id)
            ->where('tenant_id', $tenantId)
            ->first();
        if ($garageProfile && isset($data['internal_notes'])) {
            $garageProfile->update(['internal_notes' => $data['internal_notes']]);
        }

        return response()->json(['success' => true, 'data' => $this->formatCustomer($customer->fresh('garageProfiles'), $tenantId)]);
    }

    public function vehicles(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $customer = Customer::where('uuid', $uuid)
            ->whereHas('garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId))
            ->firstOrFail();

        $vehicles = $customer->vehicles()->where('is_active', true)->orderBy('registration_number')->get();

        return response()->json([
            'success' => true,
            'data'    => $vehicles->map(fn ($v) => [
                'uuid'                => $v->uuid,
                'registration_number' => $v->registration_number,
                'maker'               => $v->maker,
                'model'               => $v->model,
                'year'                => $v->year,
                'fuel_type'           => $v->fuel_type,
                'color'               => $v->color,
                'odometer_reading'    => $v->odometer_reading,
            ]),
        ]);
    }

    public function serviceHistory(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $customer = Customer::where('uuid', $uuid)
            ->whereHas('garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId))
            ->firstOrFail();

        $jobs = $customer->serviceJobs()
            ->where('tenant_id', $tenantId)
            ->with('vehicle:id,uuid,registration_number,maker,model')
            ->latest()
            ->limit(50)
            ->get();

        $invoices = \App\Models\Invoice::where('tenant_id', $tenantId)
            ->where('customer_id', $customer->id)
            ->latest()
            ->limit(50)
            ->get(['uuid', 'invoice_number', 'status', 'grand_total', 'created_at', 'job_id']);

        $timeline = collect();

        foreach ($jobs as $job) {
            $timeline->push([
                'type'       => 'job',
                'uuid'       => $job->uuid,
                'title'      => $job->job_number,
                'subtitle'   => $job->vehicle?->registration_number,
                'status'     => $job->status,
                'amount'     => $job->estimated_amount ? (float) $job->estimated_amount : null,
                'occurred_at'=> $job->created_at->toIso8601String(),
            ]);
        }

        foreach ($invoices as $inv) {
            $timeline->push([
                'type'       => 'invoice',
                'uuid'       => $inv->uuid,
                'title'      => $inv->invoice_number,
                'subtitle'   => $inv->status,
                'status'     => $inv->status,
                'amount'     => (float) $inv->grand_total,
                'occurred_at'=> $inv->created_at->toIso8601String(),
            ]);
        }

        $sorted = $timeline->sortByDesc('occurred_at')->values();

        return response()->json(['success' => true, 'data' => $sorted]);
    }

    private function formatCustomer(Customer $customer, int $tenantId, bool $full = false): array
    {
        $garage = $customer->garageProfiles->firstWhere('tenant_id', $tenantId);
        $base   = [
            'uuid'          => $customer->uuid,
            'phone_primary' => $customer->phone_primary,
            'first_name'    => $customer->first_name,
            'last_name'     => $customer->last_name,
            'email'         => $customer->email,
            'garage_profile' => $garage ? [
                'loyalty_points'    => $garage->loyalty_points,
                'total_spent'       => (float) $garage->total_spent,
                'visit_count'       => $garage->visit_count,
                'last_visited_at'   => $garage->last_visited_at?->toIso8601String(),
                'internal_notes'    => $garage->internal_notes,
            ] : null,
        ];

        if ($full) {
            $base['vehicles'] = $customer->vehicles->map(fn ($v) => [
                'uuid'                => $v->uuid,
                'registration_number' => $v->registration_number,
                'maker'               => $v->maker,
                'model'               => $v->model,
                'year'                => $v->year,
                'fuel_type'           => $v->fuel_type,
                'color'               => $v->color,
                'odometer_reading'    => $v->odometer_reading,
            ]);
            $base['recent_jobs'] = $customer->serviceJobs->map(fn ($j) => [
                'uuid'       => $j->uuid,
                'job_number' => $j->job_number,
                'status'     => $j->status,
                'created_at' => $j->created_at?->toIso8601String(),
            ]);
        }

        return $base;
    }
}
