<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::first();

        // Owner — PIN: 123456
        User::create([
            'tenant_id'  => $tenant->id,
            'email'      => 'sagar@patelautworks.in',
            'phone'      => '+918141302341',
            'pin_hash'   => Hash::make('123456'),
            'first_name' => 'Sagar',
            'last_name'  => 'Patel',
            'role'       => 'owner',
        ]);

        // Technician 1 — PIN: 111111
        User::create([
            'tenant_id'  => $tenant->id,
            'email'      => 'raju@patelautworks.in',
            'phone'      => '+919876543211',
            'pin_hash'   => Hash::make('111111'),
            'first_name' => 'Raju',
            'last_name'  => 'Sharma',
            'role'       => 'technician',
        ]);

        // Technician 2 — PIN: 222222
        User::create([
            'tenant_id'  => $tenant->id,
            'email'      => 'arjun@patelautworks.in',
            'phone'      => '+919876543212',
            'pin_hash'   => Hash::make('222222'),
            'first_name' => 'Arjun',
            'last_name'  => 'Mehta',
            'role'       => 'technician',
        ]);

        // Service Advisor — PIN: 333333
        User::create([
            'tenant_id'  => $tenant->id,
            'email'      => 'priya@patelautworks.in',
            'phone'      => '+919876543213',
            'pin_hash'   => Hash::make('333333'),
            'first_name' => 'Priya',
            'last_name'  => 'Joshi',
            'role'       => 'service_advisor',
        ]);
    }
}
