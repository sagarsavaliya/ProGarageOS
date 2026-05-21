<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\ServiceBay;
use App\Models\ServiceJob;
use App\Models\Tenant;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Database\Seeder;

class ServiceJobSeeder extends Seeder
{
    public function run(): void
    {
        $tenant     = Tenant::first();
        $users      = User::where('role', 'technician')->get();
        $bays       = ServiceBay::where('tenant_id', $tenant->id)->get();
        $customers  = Customer::all();
        $vehicles   = Vehicle::all();

        $statuses = ['checked_in', 'in_progress', 'ready_for_delivery'];

        foreach ($customers as $i => $customer) {
            $vehicle = $vehicles->firstWhere('customer_id', $customer->id);
            if (!$vehicle) continue;

            $status     = $statuses[$i % count($statuses)];
            $technician = $users->get($i % $users->count());
            $bay        = $bays->get($i % $bays->count());

            $job = ServiceJob::withoutGlobalScopes()->create([
                'tenant_id'             => $tenant->id,
                'customer_id'           => $customer->id,
                'vehicle_id'            => $vehicle->id,
                'status'                => $status,
                'priority'              => ['normal', 'urgent', 'low'][$i % 3],
                'odometer_at_intake'    => $vehicle->odometer_reading,
                'fuel_level'            => 'half',
                'customer_complaint'    => 'Regular maintenance service',
                'primary_technician_id' => $technician?->id,
                'assigned_bay_id'       => $bay?->id,
                'actual_start_at'       => now()->subHours(rand(1, 5)),
                'estimated_completion_at' => now()->addHours(rand(1, 4)),
                'estimated_amount'      => rand(1500, 8000),
                'approval_status'       => 'approved',
                'created_by'            => User::where('role', 'owner')->first()?->id,
            ]);

            // Update bay status
            if ($bay && $status === 'in_progress') {
                $bay->update(['status' => 'occupied']);
            }

            // Create a draft invoice for in_progress jobs
            if ($status === 'in_progress') {
                $invoice = Invoice::create([
                    'tenant_id'      => $tenant->id,
                    'customer_id'    => $customer->id,
                    'vehicle_id'     => $vehicle->id,
                    'job_id'         => $job->id,
                    'type'           => 'final',
                    'issued_date'    => now(),
                ]);

                $price = $job->estimated_amount ?? 2000;
                $tax   = round($price * 0.18, 2);

                InvoiceItem::create([
                    'invoice_id'  => $invoice->id,
                    'line_type'   => 'service',
                    'name'        => 'Labour Charges',
                    'quantity'    => 1,
                    'unit_price'  => $price,
                    'tax_amount'  => $tax,
                    'total_amount' => $price + $tax,
                    'sort_order'  => 0,
                ]);

                $invoice->recalculate();
            }
        }
    }
}
