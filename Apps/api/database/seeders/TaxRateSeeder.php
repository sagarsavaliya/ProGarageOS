<?php

namespace Database\Seeders;

use App\Models\TaxRate;
use Illuminate\Database\Seeder;

class TaxRateSeeder extends Seeder
{
    public function run(): void
    {
        $rates = [
            ['name' => 'GST 18%', 'code' => 'GST18', 'rate_percentage' => 18.00, 'is_default' => true,
             'component_breakdown' => ['CGST' => 9.00, 'SGST' => 9.00]],
            ['name' => 'GST 12%', 'code' => 'GST12', 'rate_percentage' => 12.00,
             'component_breakdown' => ['CGST' => 6.00, 'SGST' => 6.00]],
            ['name' => 'GST 5%',  'code' => 'GST5',  'rate_percentage' => 5.00,
             'component_breakdown' => ['CGST' => 2.50, 'SGST' => 2.50]],
            ['name' => 'Nil Rate', 'code' => 'NIL', 'rate_percentage' => 0.00, 'tax_type' => 'nil'],
        ];

        foreach ($rates as $rate) {
            TaxRate::create(array_merge([
                'tenant_id'    => null,
                'tax_type'     => 'gst',
                'is_compound'  => true,
                'applicable_to' => 'both',
                'is_default'   => false,
                'effective_from' => '2017-07-01',
            ], $rate));
        }
    }
}
