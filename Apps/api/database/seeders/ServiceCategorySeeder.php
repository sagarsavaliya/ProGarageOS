<?php

namespace Database\Seeders;

use App\Models\ServiceCategory;
use App\Models\ServiceItem;
use App\Models\Tenant;
use Illuminate\Database\Seeder;

class ServiceCategorySeeder extends Seeder
{
    public function run(): void
    {
        $tenantId = Tenant::first()->id;

        $categories = [
            ['name' => 'Oil Service', 'code' => 'OIL_SVC', 'duration' => 45, 'items' => [
                ['name' => 'Engine Oil Change (3.5L)', 'code' => 'OIL_3L', 'price' => 1200],
                ['name' => 'Engine Oil Change (5L)', 'code' => 'OIL_5L', 'price' => 1800],
                ['name' => 'Oil Filter Replacement', 'code' => 'OIL_FILTER', 'price' => 350],
            ]],
            ['name' => 'Tyre Service', 'code' => 'TYRE_SVC', 'duration' => 60, 'items' => [
                ['name' => 'Tyre Rotation', 'code' => 'TYRE_ROT', 'price' => 400],
                ['name' => 'Wheel Balancing (per tyre)', 'code' => 'WHEEL_BAL', 'price' => 200],
                ['name' => 'Wheel Alignment', 'code' => 'WHEEL_ALIGN', 'price' => 800],
            ]],
            ['name' => 'Brakes', 'code' => 'BRAKE_SVC', 'duration' => 90, 'items' => [
                ['name' => 'Brake Pad Replacement (Front)', 'code' => 'BRAKE_F', 'price' => 2500],
                ['name' => 'Brake Pad Replacement (Rear)', 'code' => 'BRAKE_R', 'price' => 2000],
                ['name' => 'Brake Fluid Change', 'code' => 'BRAKE_FLUID', 'price' => 600],
            ]],
            ['name' => 'AC Service', 'code' => 'AC_SVC', 'duration' => 120, 'items' => [
                ['name' => 'AC Gas Recharge', 'code' => 'AC_GAS', 'price' => 2200],
                ['name' => 'AC Filter Cleaning', 'code' => 'AC_FILTER', 'price' => 500],
                ['name' => 'AC Full Service', 'code' => 'AC_FULL', 'price' => 3500],
            ]],
            ['name' => 'Battery', 'code' => 'BATT_SVC', 'duration' => 30, 'items' => [
                ['name' => 'Battery Check & Replacement', 'code' => 'BATT_REPL', 'price' => 4500],
                ['name' => 'Battery Terminal Cleaning', 'code' => 'BATT_CLEAN', 'price' => 200],
            ]],
            ['name' => 'General Inspection', 'code' => 'GEN_INSP', 'duration' => 60, 'items' => [
                ['name' => '40-Point Inspection', 'code' => 'INSP_40', 'price' => 499],
                ['name' => 'Pre-Purchase Inspection', 'code' => 'INSP_PPB', 'price' => 1500],
            ]],
            ['name' => 'Accident Repair', 'code' => 'ACCIDENT_RPR', 'duration' => 480, 'requires_intake_inspection' => true, 'requires_approval' => true, 'items' => [
                ['name' => 'Accident Assessment', 'code' => 'ACC_ASSESS', 'price' => 1500],
                ['name' => 'Panel Repair (per panel)', 'code' => 'ACC_PANEL', 'price' => 3500],
            ]],
            ['name' => 'Body Work', 'code' => 'BODY_WORK', 'duration' => 360, 'requires_intake_inspection' => true, 'requires_approval' => true, 'items' => [
                ['name' => 'Dent Removal', 'code' => 'BODY_DENT', 'price' => 2500],
            ]],
        ];

        foreach ($categories as $i => $cat) {
            $category = ServiceCategory::create([
                'tenant_id'       => $tenantId,
                'name'            => $cat['name'],
                'code'            => $cat['code'],
                'default_duration_min' => $cat['duration'],
                'requires_intake_inspection' => $cat['requires_intake_inspection'] ?? true,
                'requires_approval' => $cat['requires_approval'] ?? false,
                'sort_order'      => $i,
            ]);

            foreach ($cat['items'] as $j => $item) {
                ServiceItem::create([
                    'tenant_id'   => $tenantId,
                    'category_id' => $category->id,
                    'name'        => $item['name'],
                    'code'        => $item['code'],
                    'default_price' => $item['price'],
                    'sort_order'  => $j,
                ]);
            }
        }
    }
}
