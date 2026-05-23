<?php

namespace App\Services;

use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Support\StaffLoginHelper;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class TenantProvisioningService
{
    /**
     * Create a new garage tenant with owner account and trial subscription.
     */
    public function createGarage(
        string $phone,
        string $firstName,
        string $businessName,
        ?string $lastName = null,
        ?string $email = null,
        ?string $planSlug = null,
        string $businessType = 'single', // single | multi_location
    ): array {
        $phone = StaffLoginHelper::normalizePhone($phone);

        if (User::where('phone', $phone)->exists()) {
            throw new \InvalidArgumentException('PHONE_ALREADY_REGISTERED');
        }

        $plan = SubscriptionPlan::where('status', 'active')
            ->when($planSlug, fn ($q) => $q->where('slug', $planSlug))
            ->orderBy('price')
            ->first();

        if (!$plan) {
            $plan = SubscriptionPlan::where('status', 'active')->orderBy('price')->firstOrFail();
        }

        return DB::transaction(function () use ($phone, $firstName, $lastName, $businessName, $email, $plan, $businessType) {
            $tenant = Tenant::create([
                'business_name' => $businessName,
                'business_type' => $businessType,
                'status'        => 'active',
                'currency'      => 'INR',
                'timezone'      => 'Asia/Kolkata',
                'country_code'  => 'IN',
                'phone'         => $phone,
                'email'         => $email,
                'setup_step'    => 'welcome',
            ]);

            $trialDays = max(1, (int) $plan->trial_days);
            TenantSubscription::create([
                'tenant_id'            => $tenant->id,
                'plan_id'              => $plan->id,
                'status'               => 'trialing',
                'current_period_start' => now(),
                'current_period_end'   => now()->addDays($trialDays),
                'price_at_signup'      => $plan->price,
                'currency_at_signup'   => 'INR',
            ]);

            $owner = User::create([
                'tenant_id'          => $tenant->id,
                'first_name'         => $firstName,
                'last_name'          => $lastName ?? '',
                'phone'              => $phone,
                'email'              => $email,
                'role'               => 'owner',
                'pin_hash'           => Hash::make(Str::random(40)),
                'requires_pin_setup' => true,
            ]);

            return ['tenant' => $tenant->fresh(), 'owner' => $owner, 'plan' => $plan];
        });
    }
}
