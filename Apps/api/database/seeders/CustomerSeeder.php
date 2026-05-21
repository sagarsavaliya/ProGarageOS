<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\GarageCustomer;
use App\Models\Tenant;
use Illuminate\Database\Seeder;

class CustomerSeeder extends Seeder
{
    public function run(): void
    {
        $tenantId = Tenant::first()->id;

        $customers = [
            ['phone' => '+919876500001', 'first' => 'Rahul', 'last' => 'Verma',   'email' => 'rahul@email.com'],
            ['phone' => '+919876500002', 'first' => 'Sneha', 'last' => 'Shah',    'email' => 'sneha@email.com'],
            ['phone' => '+919876500003', 'first' => 'Vikas', 'last' => 'Desai',   'email' => null],
            ['phone' => '+919876500004', 'first' => 'Meera', 'last' => 'Pillai',  'email' => 'meera@email.com'],
            ['phone' => '+919876500005', 'first' => 'Arun',  'last' => 'Nair',    'email' => null],
        ];

        foreach ($customers as $data) {
            $customer = Customer::create([
                'phone_primary' => $data['phone'],
                'first_name'    => $data['first'],
                'last_name'     => $data['last'],
                'email'         => $data['email'],
            ]);

            GarageCustomer::create([
                'customer_id'   => $customer->id,
                'tenant_id'     => $tenantId,
                'loyalty_points' => rand(0, 500),
                'total_spent'   => rand(500, 25000),
                'visit_count'   => rand(1, 15),
                'last_visited_at' => now()->subDays(rand(1, 180)),
            ]);
        }
    }
}
