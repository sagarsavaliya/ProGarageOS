<?php

namespace Database\Seeders;

use App\Models\VehicleColor;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class VehicleColorSeeder extends Seeder
{
    public function run(): void
    {
        $colors = [
            ['name' => 'White',       'hex_code' => '#FFFFFF', 'sort_order' => 1],
            ['name' => 'Pearl White', 'hex_code' => '#F8F8F6', 'sort_order' => 2],
            ['name' => 'Black',       'hex_code' => '#1A1A1A', 'sort_order' => 3],
            ['name' => 'Silver',      'hex_code' => '#C0C0C0', 'sort_order' => 4],
            ['name' => 'Grey',        'hex_code' => '#808080', 'sort_order' => 5],
            ['name' => 'Red',         'hex_code' => '#CC0000', 'sort_order' => 6],
            ['name' => 'Blue',        'hex_code' => '#1E4FA1', 'sort_order' => 7],
            ['name' => 'Navy Blue',   'hex_code' => '#0B1F3A', 'sort_order' => 8],
            ['name' => 'Green',       'hex_code' => '#2E7D32', 'sort_order' => 9],
            ['name' => 'Brown',       'hex_code' => '#6D4C41', 'sort_order' => 10],
            ['name' => 'Beige',       'hex_code' => '#D4C4A8', 'sort_order' => 11],
            ['name' => 'Gold',        'hex_code' => '#C9A227', 'sort_order' => 12],
            ['name' => 'Champagne',   'hex_code' => '#D4C5A9', 'sort_order' => 13],
            ['name' => 'Orange',      'hex_code' => '#E65100', 'sort_order' => 14],
            ['name' => 'Yellow',      'hex_code' => '#F9A825', 'sort_order' => 15],
            ['name' => 'Purple',      'hex_code' => '#6A1B9A', 'sort_order' => 16],
            ['name' => 'Maroon',      'hex_code' => '#800000', 'sort_order' => 17],
            ['name' => 'Teal',        'hex_code' => '#00897B', 'sort_order' => 18],
            ['name' => 'Bronze',      'hex_code' => '#8C6239', 'sort_order' => 19],
            ['name' => 'Other',       'hex_code' => null,      'sort_order' => 99],
        ];

        foreach ($colors as $color) {
            VehicleColor::updateOrCreate(
                ['slug' => Str::slug($color['name'])],
                [
                    'name'        => $color['name'],
                    'hex_code'    => $color['hex_code'],
                    'sort_order'  => $color['sort_order'],
                    'is_active'   => true,
                ]
            );
        }
    }
}
