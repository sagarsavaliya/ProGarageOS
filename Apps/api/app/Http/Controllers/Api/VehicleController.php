<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use App\Models\VehicleMileageLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = Vehicle::where('is_active', true)
            ->whereHas('customer.garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId));

        if ($customerId = $request->query('customer_uuid')) {
            $query->whereHas('customer', fn ($q) => $q->where('uuid', $customerId));
        }

        if ($search = $request->query('search')) {
            $query->where(fn ($q) => $q
                ->where('registration_number', 'like', "%{$search}%")
                ->orWhere('maker', 'like', "%{$search}%")
                ->orWhere('model', 'like', "%{$search}%")
            );
        }

        $vehicles = $query->with('customer:id,uuid,first_name,last_name,phone_primary')
            ->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $vehicles->map(fn ($v) => $this->formatVehicle($v)),
            'meta'    => [
                'current_page' => $vehicles->currentPage(),
                'per_page'     => $vehicles->perPage(),
                'total'        => $vehicles->total(),
                'last_page'    => $vehicles->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $vehicle  = $this->resolveVehicle($request, $uuid, $tenantId)
            ->with(['customer:id,uuid,first_name,last_name,phone_primary', 'documents', 'mileageLogs' => fn ($q) => $q->limit(10)])
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $this->formatVehicle($vehicle, true)]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'customer_uuid'         => ['required', 'string', 'exists:customers,uuid'],
            'registration_number'   => ['required', 'string', 'max:50'],
            'maker'                 => ['required', 'string', 'max:100'],
            'model'                 => ['required', 'string', 'max:100'],
            'fuel_type'             => ['nullable', 'in:petrol,diesel,electric,cng,lpg,hybrid'],
            'year'                  => ['nullable', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'color'                 => ['nullable', 'string', 'max:50'],
            'chassis_number'        => ['nullable', 'string', 'max:100'],
            'engine_number'         => ['nullable', 'string', 'max:100'],
            'odometer_reading'      => ['nullable', 'integer', 'min:0'],
            'gps_tracking_consent'  => ['nullable', 'boolean'],
        ]);

        $customer = \App\Models\Customer::where('uuid', $data['customer_uuid'])->firstOrFail();
        unset($data['customer_uuid']);
        $data['customer_id'] = $customer->id;

        $vehicle = Vehicle::create($data);

        return response()->json(['success' => true, 'data' => $this->formatVehicle($vehicle)], 201);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $vehicle  = $this->resolveVehicle($request, $uuid, $tenantId);
        $data = $request->validate([
            'maker'            => ['sometimes', 'string', 'max:100'],
            'model'            => ['sometimes', 'string', 'max:100'],
            'variant'          => ['nullable', 'string', 'max:100'],
            'year'             => ['nullable', 'integer'],
            'color'            => ['nullable', 'string', 'max:50'],
            'fuel_type'        => ['nullable', 'in:petrol,diesel,electric,cng,lpg,hybrid'],
            'odometer_reading' => ['nullable', 'integer', 'min:0'],
            'nickname'         => ['nullable', 'string', 'max:100'],
            'is_active'            => ['sometimes', 'boolean'],
            'gps_tracking_consent' => ['sometimes', 'boolean'],
        ]);
        $vehicle->update($data);
        return response()->json(['success' => true, 'data' => $this->formatVehicle($vehicle->fresh())]);
    }

    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $vehicle  = $this->resolveVehicle($request, $uuid, $tenantId);
        $vehicle->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'data'    => ['uuid' => $vehicle->uuid, 'is_active' => false],
        ]);
    }

    public function updateOdometer(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $vehicle  = $this->resolveVehicle($request, $uuid, $tenantId);
        $data = $request->validate([
            'odometer_value_km' => ['required', 'integer', 'min:0'],
            'source'            => ['required', 'in:customer_manual_correct,job_intake,admin_override'],
        ]);

        VehicleMileageLog::create([
            'vehicle_id'         => $vehicle->id,
            'recorded_at'        => now(),
            'odometer_value_km'  => $data['odometer_value_km'],
            'previous_value_km'  => $vehicle->odometer_reading,
            'source'             => $data['source'],
            'review_status'      => 'confirmed',
        ]);

        $vehicle->update([
            'odometer_reading'       => $data['odometer_value_km'],
            'odometer_review_status' => 'approved',
        ]);

        return response()->json(['success' => true, 'data' => ['odometer_reading' => $data['odometer_value_km']]]);
    }

    private function formatVehicle(Vehicle $vehicle, bool $full = false): array
    {
        $base = [
            'uuid'                => $vehicle->uuid,
            'registration_number' => $vehicle->registration_number,
            'display_name'        => $vehicle->display_name,
            'maker'               => $vehicle->maker,
            'model'               => $vehicle->model,
            'variant'             => $vehicle->variant,
            'year'                => $vehicle->year,
            'fuel_type'           => $vehicle->fuel_type,
            'color'               => $vehicle->color,
            'odometer_reading'    => $vehicle->odometer_reading,
            'gps_tracking_consent' => (bool) $vehicle->gps_tracking_consent,
            'is_active'           => $vehicle->is_active,
            'customer'            => $vehicle->customer ? [
                'uuid'  => $vehicle->customer->uuid,
                'name'  => $vehicle->customer->full_name,
                'phone' => $vehicle->customer->phone_primary,
            ] : null,
        ];

        if ($full) {
            $base['chassis_number']     = $vehicle->chassis_number;
            $base['engine_number']      = $vehicle->engine_number;
            $base['insurance_expiry']   = $vehicle->insurance_expiry?->format('Y-m-d');
            $base['documents']          = $vehicle->documents->map(fn ($d) => [
                'type'        => $d->document_type,
                'expiry_date' => $d->expiry_date?->format('Y-m-d'),
                'is_expired'  => $d->isExpired(),
            ]);
            $base['mileage_logs']       = $vehicle->mileageLogs->map(fn ($m) => [
                'km'          => $m->odometer_value_km,
                'source'      => $m->source,
                'recorded_at' => $m->recorded_at->toIso8601String(),
            ]);
        }

        return $base;
    }

    private function resolveVehicle(Request $request, string $uuid, int $tenantId): Vehicle
    {
        return Vehicle::where('uuid', $uuid)
            ->whereHas('customer.garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId))
            ->firstOrFail();
    }
}
