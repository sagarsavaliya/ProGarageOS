<?php

namespace Database\Seeders;

use App\Models\SubscriptionPlan;
use Illuminate\Database\Seeder;

class SubscriptionPlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'name'              => 'Starter',
                'slug'              => 'starter',
                'price'             => 999,
                'billing_cycle'     => 'monthly',
                'trial_days'        => 14,
                'max_locations'     => 1,
                'max_users'         => 5,
                'max_jobs_per_month'=> 100,
                'features'          => ['jobs', 'customers', 'invoices'],
                'status'            => 'active',
            ],
            [
                'name'              => 'Pro',
                'slug'              => 'pro',
                'price'             => 2999,
                'billing_cycle'     => 'monthly',
                'trial_days'        => 14,
                'max_locations'     => 3,
                'max_users'         => 20,
                'max_jobs_per_month'=> 500,
                'features'          => ['jobs', 'invoices', 'inventory', 'loyalty', 'reports'],
                'status'            => 'active',
            ],
            [
                'name'              => 'Enterprise',
                'slug'              => 'enterprise',
                'price'             => 7999,
                'billing_cycle'     => 'monthly',
                'trial_days'        => 30,
                'max_locations'     => 10,
                'max_users'         => 100,
                'max_jobs_per_month'=> 5000,
                'features'          => ['jobs', 'invoices', 'inventory', 'loyalty', 'reports', 'api'],
                'status'            => 'active',
            ],
        ];

        foreach ($plans as $plan) {
            SubscriptionPlan::updateOrCreate(['slug' => $plan['slug']], $plan);
        }
    }
}
