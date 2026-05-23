<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class PlatformAdminSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@progarage.cloud'],
            [
                'tenant_id'          => null,
                'phone'              => '+919988877766',
                'pin_hash'           => Hash::make('999999'),
                'first_name'         => 'Platform',
                'last_name'          => 'Admin',
                'role'               => 'owner',
                'is_platform_admin'  => true,
                'requires_pin_setup' => false,
            ]
        );
    }
}
