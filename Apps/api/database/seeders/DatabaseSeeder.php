<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            TenantSeeder::class,
            UserSeeder::class,
            ServiceCategorySeeder::class,
            ServiceBaySeeder::class,
            TaxRateSeeder::class,
            PaymentMethodSeeder::class,
            CustomerSeeder::class,
            VehicleSeeder::class,
            ServiceJobSeeder::class,
        ]);
    }
}
