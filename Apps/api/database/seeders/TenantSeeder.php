<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Models\SubscriptionPlan;
use App\Models\TenantSubscription;
use Illuminate\Database\Seeder;

class TenantSeeder extends Seeder
{
    public function run(): void
    {
        $plan = SubscriptionPlan::where('slug', 'pro')->first()
            ?? SubscriptionPlan::create([
                'name'          => 'Pro',
                'slug'          => 'pro',
                'price'         => 2999.00,
                'billing_cycle' => 'monthly',
                'trial_days'    => 14,
                'max_locations' => 3,
                'max_users'     => 20,
                'status'        => 'active',
                'features'      => ['jobs', 'invoices', 'inventory', 'loyalty', 'reports'],
            ]);

        $tenant = Tenant::create([
            'business_name' => 'Patel Auto Works',
            'business_type' => 'single',
            'status'        => 'active',
            'currency'      => 'INR',
            'timezone'      => 'Asia/Kolkata',
            'country_code'  => 'IN',
            'phone'         => '+919876543210',
            'email'         => 'contact@patelautworks.in',
            'address'       => '12, Industrial Estate, Ring Road',
            'city'          => 'Surat',
            'state'         => 'Gujarat',
            'pincode'       => '395002',
            'gst_number'    => '24AABCP1234A1Z5',
        ]);

        TenantSubscription::create([
            'tenant_id'            => $tenant->id,
            'plan_id'              => $plan->id,
            'status'               => 'active',
            'current_period_start' => now(),
            'current_period_end'   => now()->addMonths(1),
        ]);
    }
}
