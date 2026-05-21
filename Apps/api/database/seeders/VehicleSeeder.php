<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Vehicle;
use Illuminate\Database\Seeder;

class VehicleSeeder extends Seeder
{
    public function run(): void
    {
        $vehicles = [
            [1, 'GJ05AB1234', 'Maruti Suzuki', 'Swift', 'VXi', 2021, 'petrol', 'White', 28500],
            [2, 'GJ06CD5678', 'Hyundai',        'Creta', '1.5 SX', 2022, 'diesel', 'Phantom Black', 15200],
            [3, 'GJ07EF9012', 'Tata',           'Nexon', 'XZ+', 2020, 'petrol', 'Calgary White', 42300],
            [4, 'GJ01GH3456', 'Honda',          'City', 'V CVT', 2023, 'petrol', 'Meteoroid Grey', 8900],
            [5, 'GJ05IJ7890', 'Toyota',         'Innova Crysta', '2.7 ZX', 2019, 'petrol', 'Super White', 76000],
        ];

        $customers = Customer::orderBy('id')->get();

        foreach ($vehicles as $i => $v) {
            if (!isset($customers[$i])) continue;
            Vehicle::create([
                'customer_id'         => $customers[$i]->id,
                'registration_number' => $v[1],
                'maker'               => $v[2],
                'model'               => $v[3],
                'variant'             => $v[4],
                'year'                => $v[5],
                'fuel_type'           => $v[6],
                'color'               => $v[7],
                'odometer_reading'    => $v[8],
            ]);
        }
    }
}
