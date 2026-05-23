<?php

namespace App\Http\Controllers\Api\Platform;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Services\TenantOperationalResetService;
use App\Services\TenantProvisioningService;
use App\Support\StaffLoginHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class PlatformTenantController extends Controller
{
    public function __construct(
        private TenantProvisioningService $provisioning,
        private TenantOperationalResetService $resetService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Tenant::with(['activeSubscription.plan', 'users' => fn ($q) => $q->where('role', 'owner')->limit(1)])
            ->orderByDesc('created_at');

        if ($search = $request->query('search')) {
            $query->where(fn ($q) => $q
                ->where('business_name', 'like', "%{$search}%")
                ->orWhere('phone', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%"));
        }

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $tenants = $query->paginate($request->integer('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $tenants->map(fn (Tenant $t) => $this->formatTenant($t)),
            'meta'    => [
                'current_page' => $tenants->currentPage(),
                'per_page'     => $tenants->perPage(),
                'total'        => $tenants->total(),
                'last_page'    => $tenants->lastPage(),
            ],
        ]);
    }

    public function show(string $uuid): JsonResponse
    {
        $tenant = Tenant::with(['activeSubscription.plan', 'users'])->where('uuid', $uuid)->firstOrFail();

        return response()->json(['success' => true, 'data' => $this->formatTenant($tenant, true)]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone'         => ['required', 'string'],
            'first_name'    => ['required', 'string', 'max:100'],
            'last_name'     => ['nullable', 'string', 'max:100'],
            'business_name' => ['required', 'string', 'max:200'],
            'email'         => ['nullable', 'email'],
            'plan_slug'     => ['nullable', 'string'],
            'status'        => ['nullable', 'in:active,suspended,pending'],
        ]);

        try {
            $result = $this->provisioning->createGarage(
                phone: $data['phone'],
                firstName: $data['first_name'],
                businessName: $data['business_name'],
                lastName: $data['last_name'] ?? null,
                email: $data['email'] ?? null,
                planSlug: $data['plan_slug'] ?? null,
            );
        } catch (\InvalidArgumentException $e) {
            if ($e->getMessage() === 'PHONE_ALREADY_REGISTERED') {
                return response()->json([
                    'success' => false,
                    'error'   => ['code' => 'PHONE_ALREADY_REGISTERED', 'message' => 'Phone already in use.'],
                ], 409);
            }
            throw $e;
        }

        if (!empty($data['status']) && $data['status'] !== 'active') {
            $result['tenant']->update(['status' => $data['status']]);
        }

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($result['tenant']->fresh(['activeSubscription.plan', 'users']), true),
        ], 201);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $uuid)->firstOrFail();

        $data = $request->validate([
            'business_name' => ['sometimes', 'string', 'max:200'],
            'business_type' => ['sometimes', 'in:single,multi_location'],
            'status'        => ['sometimes', 'in:active,suspended,pending'],
            'phone'         => ['sometimes', 'string', 'max:20'],
            'email'         => ['nullable', 'email'],
            'address'       => ['nullable', 'string'],
            'city'          => ['nullable', 'string', 'max:100'],
            'state'         => ['nullable', 'string', 'max:100'],
            'pincode'       => ['nullable', 'string', 'max:10'],
            'gst_number'    => ['nullable', 'string', 'max:20'],
            'setup_step'    => ['sometimes', 'in:welcome,details,bays,done'],
            'setup_bay_count' => ['nullable', 'integer', 'min:0'],
        ]);

        if (array_key_exists('setup_step', $data) && $data['setup_step'] === 'done') {
            $data['setup_completed_at'] = now();
        }

        $tenant->update($data);

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($tenant->fresh(['activeSubscription.plan', 'users']), true),
        ]);
    }

    public function updateSubscription(Request $request, string $uuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $uuid)->firstOrFail();

        $data = $request->validate([
            'plan_slug'  => ['required', 'string'],
            'status'     => ['required', 'in:trialing,active,past_due,canceled'],
            'period_end' => ['nullable', 'date'],
        ]);

        $plan = SubscriptionPlan::where('slug', $data['plan_slug'])->firstOrFail();
        $sub = TenantSubscription::where('tenant_id', $tenant->id)
            ->whereIn('status', ['trialing', 'active', 'past_due'])
            ->latest()
            ->first();

        $payload = [
            'plan_id'              => $plan->id,
            'status'               => $data['status'],
            'current_period_start' => now(),
            'current_period_end'   => isset($data['period_end'])
                ? \Carbon\Carbon::parse($data['period_end'])
                : now()->addMonth(),
        ];

        if ($sub) {
            $sub->update($payload);
        } else {
            TenantSubscription::create(array_merge($payload, ['tenant_id' => $tenant->id]));
        }

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($tenant->fresh(['activeSubscription.plan', 'users']), true),
        ]);
    }

    public function resetOperationalData(Request $request, string $uuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $uuid)->firstOrFail();
        $resetOnboarding = $request->boolean('reset_onboarding', false);

        $this->resetService->reset($tenant, $resetOnboarding);

        return response()->json([
            'success' => true,
            'message' => 'Operational data cleared for this garage.',
        ]);
    }

    public function destroy(string $uuid): JsonResponse
    {
        $tenant = Tenant::where('uuid', $uuid)->firstOrFail();
        $this->resetService->reset($tenant, false);
        User::where('tenant_id', $tenant->id)->delete();
        TenantSubscription::where('tenant_id', $tenant->id)->delete();
        $tenant->delete();

        return response()->json(['success' => true, 'message' => 'Garage tenant removed.']);
    }

    private function formatTenant(Tenant $tenant, bool $detailed = false): array
    {
        $owner = $tenant->users->firstWhere('role', 'owner') ?? $tenant->users->first();
        $sub = $tenant->activeSubscription;

        $base = [
            'uuid'           => $tenant->uuid,
            'business_name'  => $tenant->business_name,
            'business_type'  => $tenant->business_type,
            'status'         => $tenant->status,
            'phone'          => $tenant->phone,
            'email'          => $tenant->email,
            'setup_step'     => $tenant->setup_step ?? 'welcome',
            'setup_complete' => $tenant->setup_completed_at !== null,
            'created_at'     => $tenant->created_at?->toIso8601String(),
            'owner'          => $owner ? [
                'uuid'       => $owner->uuid,
                'name'       => $owner->full_name,
                'phone'      => $owner->phone,
                'email'      => $owner->email,
                'requires_pin_setup' => $owner->requires_pin_setup,
            ] : null,
            'subscription'   => $sub ? [
                'status'             => $sub->status,
                'plan_name'          => $sub->plan?->name,
                'plan_slug'          => $sub->plan?->slug,
                'current_period_end' => $sub->current_period_end?->toIso8601String(),
            ] : null,
        ];

        if ($detailed) {
            $base['address'] = $tenant->address;
            $base['city'] = $tenant->city;
            $base['state'] = $tenant->state;
            $base['pincode'] = $tenant->pincode;
            $base['gst_number'] = $tenant->gst_number;
            $base['setup_bay_count'] = $tenant->setup_bay_count;
            $base['staff_count'] = User::where('tenant_id', $tenant->id)->count();
        }

        return $base;
    }
}
