<?php

use App\Models\ServiceCategory;
use App\Models\ServiceItem;
use App\Models\Tenant;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        $categories = [
            [
                'code'     => 'ACCIDENT_RPR',
                'name'     => 'Accident Repair',
                'duration' => 480,
                'requires_intake_inspection' => true,
                'requires_approval' => true,
                'items'    => [
                    ['name' => 'Accident Assessment', 'code' => 'ACC_ASSESS', 'price' => 1500],
                    ['name' => 'Panel Repair (per panel)', 'code' => 'ACC_PANEL', 'price' => 3500],
                    ['name' => 'Paint & Refinish', 'code' => 'ACC_PAINT', 'price' => 8000],
                ],
            ],
            [
                'code'     => 'BODY_WORK',
                'name'     => 'Body Work',
                'duration' => 360,
                'requires_intake_inspection' => true,
                'requires_approval' => true,
                'items'    => [
                    ['name' => 'Dent Removal', 'code' => 'BODY_DENT', 'price' => 2500],
                    ['name' => 'Bumper Replacement', 'code' => 'BODY_BUMP', 'price' => 4500],
                ],
            ],
        ];

        Tenant::query()->pluck('id')->each(function (int $tenantId) use ($categories) {
            foreach ($categories as $i => $cat) {
                $category = ServiceCategory::firstOrCreate(
                    ['tenant_id' => $tenantId, 'code' => $cat['code']],
                    [
                        'uuid'                       => (string) Str::uuid(),
                        'name'                       => $cat['name'],
                        'default_duration_min'       => $cat['duration'],
                        'requires_intake_inspection' => $cat['requires_intake_inspection'],
                        'requires_approval'          => $cat['requires_approval'],
                        'is_billable'                => true,
                        'is_active'                  => true,
                        'sort_order'                 => 100 + $i,
                    ]
                );

                foreach ($cat['items'] as $j => $item) {
                    ServiceItem::firstOrCreate(
                        ['tenant_id' => $tenantId, 'category_id' => $category->id, 'code' => $item['code']],
                        [
                            'name'          => $item['name'],
                            'default_price' => $item['price'],
                            'sort_order'    => $j,
                        ]
                    );
                }
            }
        });
    }

    public function down(): void
    {
        ServiceCategory::whereIn('code', ['ACCIDENT_RPR', 'BODY_WORK'])->delete();
    }
};
