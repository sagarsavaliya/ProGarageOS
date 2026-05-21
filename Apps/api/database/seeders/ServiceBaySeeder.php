<?php

namespace Database\Seeders;

use App\Models\ServiceBay;
use App\Models\Tenant;
use Illuminate\Database\Seeder;

class ServiceBaySeeder extends Seeder
{
    public function run(): void
    {
        $tenantId = Tenant::first()->id;

        $bays = [
            ['name' => 'Bay 1', 'code' => 'B1', 'bay_type' => 'general_lift', 'status' => 'available'],
            ['name' => 'Bay 2', 'code' => 'B2', 'bay_type' => 'general_lift', 'status' => 'available'],
            ['name' => 'Alignment Bay', 'code' => 'ALN', 'bay_type' => 'alignment', 'status' => 'available'],
            ['name' => 'Wash Bay', 'code' => 'WSH', 'bay_type' => 'wash_bay', 'status' => 'available'],
            ['name' => 'Diagnostic Bay', 'code' => 'DX1', 'bay_type' => 'diagnostic', 'status' => 'available'],
        ];

        foreach ($bays as $i => $bay) {
            ServiceBay::create([
                'tenant_id'  => $tenantId,
                'sort_order' => $i,
                ...$bay,
            ]);
        }
    }
}
