<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Services\TenantProvisioningService;
use App\Support\StaffLoginHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;

class OwnerSignupController extends Controller
{
    public function __construct(private TenantProvisioningService $provisioning) {}

    /**
     * GET /subscription-plans — public list of active plans for signup.
     */
    public function plans(): JsonResponse
    {
        $plans = SubscriptionPlan::where('status', 'active')
            ->orderBy('price')
            ->get()
            ->map(fn (SubscriptionPlan $p) => $this->formatPlan($p));

        return response()->json(['success' => true, 'data' => $plans]);
    }

    /**
     * POST /auth/owner/signup — self-service garage registration.
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone'          => ['required', 'string', 'min:10', 'max:15'],
            'first_name'     => ['required', 'string', 'max:100'],
            'last_name'      => ['nullable', 'string', 'max:100'],
            'business_name'  => ['required', 'string', 'max:200'],
            'email'          => ['nullable', 'email', 'max:255'],
            'plan_slug'      => ['nullable', 'string', 'max:50'],
            'business_type'  => ['nullable', 'in:single,multi_location'],
        ]);

        $key = 'owner-signup:' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json([
                'success' => false,
                'error'   => [
                    'code'                => 'RATE_LIMITED',
                    'message'             => "Too many signup attempts. Wait {$seconds} seconds.",
                    'retry_after_seconds' => $seconds,
                ],
            ], 429);
        }

        try {
            $result = $this->provisioning->createGarage(
                phone: $data['phone'],
                firstName: $data['first_name'],
                businessName: $data['business_name'],
                lastName: $data['last_name'] ?? null,
                email: $data['email'] ?? null,
                planSlug: $data['plan_slug'] ?? null,
                businessType: $data['business_type'] ?? 'single',
            );
        } catch (\InvalidArgumentException $e) {
            if ($e->getMessage() === 'PHONE_ALREADY_REGISTERED') {
                RateLimiter::hit($key, 900);
                return response()->json([
                    'success' => false,
                    'error'   => [
                        'code'    => 'PHONE_ALREADY_REGISTERED',
                        'message' => 'This phone number is already registered. Sign in or use a different number.',
                    ],
                ], 409);
            }
            throw $e;
        }

        RateLimiter::hit($key, 900);

        $owner = $result['owner'];
        $login = StaffLoginHelper::normalizePhone($data['phone']);

        return response()->json([
            'success' => true,
            'data'    => [
                'message'       => 'Garage created. Verify your phone via WhatsApp to set your 6-digit PIN.',
                'login'         => $login,
                'tenant_uuid'   => $result['tenant']->uuid,
                'business_name' => $result['tenant']->business_name,
                'plan'          => $this->formatPlan($result['plan']),
                'requires_pin_setup' => true,
            ],
        ], 201);
    }

    private function formatPlan(SubscriptionPlan $plan): array
    {
        return [
            'uuid'              => $plan->uuid,
            'name'              => $plan->name,
            'slug'              => $plan->slug,
            'price'             => (float) $plan->price,
            'billing_cycle'     => $plan->billing_cycle,
            'trial_days'        => (int) $plan->trial_days,
            'max_locations'     => (int) $plan->max_locations,
            'max_users'         => (int) $plan->max_users,
            'max_jobs_per_month'=> (int) $plan->max_jobs_per_month,
            'features'          => $plan->features ?? [],
        ];
    }
}
