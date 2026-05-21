<?php

namespace Database\Seeders;

use App\Models\PaymentMethod;
use Illuminate\Database\Seeder;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        $methods = [
            ['name' => 'Cash', 'code' => 'CASH', 'type' => 'cash', 'sort_order' => 1],
            ['name' => 'UPI', 'code' => 'UPI', 'type' => 'digital', 'gateway_provider' => 'razorpay', 'sort_order' => 2],
            ['name' => 'Credit/Debit Card', 'code' => 'CARD', 'type' => 'card', 'gateway_provider' => 'razorpay', 'sort_order' => 3],
            ['name' => 'Net Banking', 'code' => 'NETBANK', 'type' => 'digital', 'sort_order' => 4],
            ['name' => 'Cheque', 'code' => 'CHEQUE', 'type' => 'cheque', 'requires_reference' => true, 'sort_order' => 5],
            ['name' => 'Insurance Claim', 'code' => 'INSURANCE', 'type' => 'insurance', 'requires_reference' => true, 'sort_order' => 6],
        ];

        foreach ($methods as $method) {
            PaymentMethod::create(array_merge(['tenant_id' => null], $method));
        }
    }
}
