<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\Customer;
use App\Models\GarageCustomer;
use App\Models\InventoryItem;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\JobTask;
use App\Models\Payment;
use App\Models\PaymentMethod;
use App\Models\ServiceBay;
use App\Models\ServiceCategory;
use App\Models\ServiceItem;
use App\Models\ServiceJob;
use App\Models\SubscriptionPlan;
use App\Models\TaxRate;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Models\Vehicle;
use App\Support\StaffLoginHelper;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AutoCarCareDemoSeeder
{
    public const OWNER_PHONE = '+919988776655';
    public const OWNER_PIN = '654321';
    public const BUSINESS_NAME = 'Auto Car Care';

    private const FIRST_NAMES = [
        'Rahul', 'Priya', 'Amit', 'Sneha', 'Vikram', 'Ananya', 'Rohan', 'Kavita', 'Suresh', 'Meera',
        'Arjun', 'Divya', 'Karan', 'Pooja', 'Nikhil', 'Shreya', 'Manish', 'Neha', 'Deepak', 'Ritu',
        'Sanjay', 'Anjali', 'Varun', 'Swati', 'Gaurav', 'Nisha', 'Harsh', 'Kiran', 'Yogesh', 'Preeti',
        'Ashok', 'Lata', 'Rajesh', 'Sunita', 'Mahesh', 'Geeta', 'Vinod', 'Rekha', 'Prakash', 'Usha',
        'Sunil', 'Asha', 'Ramesh', 'Vandana', 'Anil', 'Kalpana', 'Mukesh', 'Sarita', 'Dinesh', 'Madhuri',
    ];

    private const LAST_NAMES = [
        'Sharma', 'Patel', 'Reddy', 'Iyer', 'Singh', 'Khan', 'Desai', 'Nair', 'Mehta', 'Joshi',
        'Gupta', 'Rao', 'Kulkarni', 'Pillai', 'Verma', 'Shah', 'Chopra', 'Malhotra', 'Bhat', 'Menon',
        'Kapoor', 'Saxena', 'Tiwari', 'Mishra', 'Pandey', 'Dubey', 'Chauhan', 'Yadav', 'Thakur', 'Shetty',
        'Naik', 'Gowda', 'Hegde', 'Murthy', 'Krishnan', 'Subramanian', 'Banerjee', 'Das', 'Ghosh', 'Roy',
        'Chatterjee', 'Bose', 'Tripathi', 'Agarwal', 'Jain', 'Bhatt', 'Solanki', 'Parmar', 'Rathod', 'More',
    ];

    private const CITIES = [
        ['code' => 'MH12', 'city' => 'Pune', 'state' => 'Maharashtra'],
        ['code' => 'MH14', 'city' => 'Pimpri', 'state' => 'Maharashtra'],
        ['code' => 'MH04', 'city' => 'Mumbai', 'state' => 'Maharashtra'],
        ['code' => 'GJ01', 'city' => 'Ahmedabad', 'state' => 'Gujarat'],
        ['code' => 'KA03', 'city' => 'Bengaluru', 'state' => 'Karnataka'],
        ['code' => 'DL01', 'city' => 'Delhi', 'state' => 'Delhi'],
        ['code' => 'TN07', 'city' => 'Chennai', 'state' => 'Tamil Nadu'],
        ['code' => 'RJ14', 'city' => 'Jaipur', 'state' => 'Rajasthan'],
    ];

    private const CAR_MODELS = [
        ['Maruti Suzuki', 'Swift', 'VXi', 'petrol'],
        ['Maruti Suzuki', 'Baleno', 'Delta', 'petrol'],
        ['Hyundai', 'Creta', 'SX', 'diesel'],
        ['Hyundai', 'i20', 'Asta', 'petrol'],
        ['Tata', 'Nexon', 'XZ+', 'petrol'],
        ['Tata', 'Punch', 'Adventure', 'petrol'],
        ['Honda', 'City', 'V CVT', 'petrol'],
        ['Honda', 'Amaze', 'VX', 'petrol'],
        ['Toyota', 'Innova Crysta', '2.7 GX', 'petrol'],
        ['Mahindra', 'XUV700', 'AX5', 'diesel'],
        ['Kia', 'Seltos', 'HTX', 'petrol'],
        ['Volkswagen', 'Virtus', 'GT', 'petrol'],
        ['Skoda', 'Slavia', 'Style', 'petrol'],
        ['Renault', 'Kiger', 'RXZ', 'petrol'],
        ['MG', 'Hector', 'Sharp', 'petrol'],
    ];

    private const COMPLAINTS = [
        'Periodic service due',
        'AC cooling weak in afternoon',
        'Brake squeal from front wheels',
        'Engine vibration at idle',
        'Clutch hard while shifting',
        'Suspension noise on speed breakers',
        'Battery weak — slow crank',
        'Tyre wear uneven on rear axle',
        'Check engine light on dashboard',
        'Steering vibration above 80 km/h',
    ];

    private const TASK_NAMES = [
        'Engine oil and filter change',
        'Wheel alignment and balancing',
        'Brake pad inspection',
        'AC gas top-up and filter clean',
        'General health check-up',
        'Coolant flush',
        'Spark plug replacement',
        'Battery load test',
    ];

    public function __construct(
        private TenantOperationalResetService $resetService,
    ) {}

    public function seed(): array
    {
        return DB::transaction(function () {
            [$tenant, $owner] = $this->ensureTenant();
            $this->resetService->reset($tenant, false);
            $this->clearFoundation($tenant);
            $context = $this->seedFoundation($tenant, $owner);
            $customers = $this->seedCustomers($tenant, $context);
            $stats = $this->seedOperationalData($tenant, $owner, $context, $customers);
            Cache::flush();

            return array_merge([
                'tenant_uuid'   => $tenant->uuid,
                'business_name' => $tenant->business_name,
                'login_phone'   => self::OWNER_PHONE,
                'login_pin'     => self::OWNER_PIN,
            ], $stats);
        });
    }

    private function ensureTenant(): array
    {
        $phone = StaffLoginHelper::normalizePhone(self::OWNER_PHONE);
        $existing = User::where('phone', $phone)->first();

        if ($existing?->tenant_id) {
            $tenant = Tenant::findOrFail($existing->tenant_id);
            $owner = User::where('tenant_id', $tenant->id)->where('role', 'owner')->firstOrFail();
            $this->updateOwnerAndTenant($tenant, $owner);
            return [$tenant->fresh(), $owner->fresh()];
        }

        $plan = SubscriptionPlan::where('status', 'active')->orderBy('price')->firstOrFail();

        $tenant = Tenant::create([
            'business_name'        => self::BUSINESS_NAME,
            'business_type'      => 'single',
            'status'             => 'active',
            'currency'             => 'INR',
            'timezone'             => 'Asia/Kolkata',
            'country_code'         => 'IN',
            'phone'                => $phone,
            'email'                => 'owner@autocarcare.in',
            'address'              => 'Shop 12, Baner Road, Near Balewadi High Street',
            'city'                 => 'Pune',
            'state'                => 'Maharashtra',
            'pincode'              => '411045',
            'gst_number'           => '27AABCA7421F1Z8',
            'setup_step'           => 'done',
            'setup_bay_count'      => 5,
            'setup_completed_at'   => now(),
        ]);

        TenantSubscription::create([
            'tenant_id'            => $tenant->id,
            'plan_id'              => $plan->id,
            'status'               => 'active',
            'current_period_start' => now(),
            'current_period_end'   => now()->addYear(),
            'price_at_signup'      => $plan->price,
            'currency_at_signup'   => 'INR',
        ]);

        $owner = User::create([
            'tenant_id'          => $tenant->id,
            'first_name'         => 'Ramesh',
            'last_name'          => 'Kulkarni',
            'phone'              => $phone,
            'email'              => 'owner@autocarcare.in',
            'role'               => 'owner',
            'pin_hash'           => Hash::make(self::OWNER_PIN),
            'requires_pin_setup' => false,
        ]);

        return [$tenant, $owner];
    }

    private function updateOwnerAndTenant(Tenant $tenant, User $owner): void
    {
        $tenant->update([
            'business_name'      => self::BUSINESS_NAME,
            'phone'              => self::OWNER_PHONE,
            'email'              => 'owner@autocarcare.in',
            'address'            => 'Shop 12, Baner Road, Near Balewadi High Street',
            'city'               => 'Pune',
            'state'              => 'Maharashtra',
            'pincode'            => '411045',
            'gst_number'         => '27AABCA7421F1Z8',
            'setup_step'         => 'done',
            'setup_bay_count'    => 5,
            'setup_completed_at' => now(),
        ]);

        $owner->update([
            'pin_hash'           => Hash::make(self::OWNER_PIN),
            'requires_pin_setup' => false,
            'first_name'         => 'Ramesh',
            'last_name'          => 'Kulkarni',
        ]);
    }

    private function clearFoundation(Tenant $tenant): void
    {
        $tenantId = $tenant->id;

        User::where('tenant_id', $tenantId)->where('role', '!=', 'owner')->delete();
        InventoryItem::where('tenant_id', $tenantId)->forceDelete();

        $categoryIds = ServiceCategory::where('tenant_id', $tenantId)->pluck('id');
        ServiceItem::whereIn('category_id', $categoryIds)->forceDelete();
        ServiceCategory::where('tenant_id', $tenantId)->forceDelete();
        ServiceBay::where('tenant_id', $tenantId)->forceDelete();
    }

    private function seedFoundation(Tenant $tenant, User $owner): array
    {
        $tenantId = $tenant->id;

        $technicians = collect([
            User::create([
                'tenant_id' => $tenantId, 'first_name' => 'Sandeep', 'last_name' => 'Patil',
                'phone' => '+919988776651', 'role' => 'technician', 'pin_hash' => Hash::make('111111'),
            ]),
            User::create([
                'tenant_id' => $tenantId, 'first_name' => 'Ajay', 'last_name' => 'Shinde',
                'phone' => '+919988776652', 'role' => 'technician', 'pin_hash' => Hash::make('222222'),
            ]),
        ]);

        $advisor = User::create([
            'tenant_id' => $tenantId, 'first_name' => 'Neha', 'last_name' => 'Desai',
            'phone' => '+919988776653', 'role' => 'service_advisor', 'pin_hash' => Hash::make('333333'),
        ]);

        $bays = collect([
            ['name' => 'Bay 1', 'code' => 'B1', 'bay_type' => 'general_lift'],
            ['name' => 'Bay 2', 'code' => 'B2', 'bay_type' => 'general_lift'],
            ['name' => 'Alignment Bay', 'code' => 'ALN', 'bay_type' => 'alignment'],
            ['name' => 'Wash Bay', 'code' => 'WSH', 'bay_type' => 'wash_bay'],
            ['name' => 'Diagnostic Bay', 'code' => 'DX1', 'bay_type' => 'diagnostic'],
        ])->map(fn ($bay, $i) => ServiceBay::create([
            'tenant_id' => $tenantId, 'sort_order' => $i, 'status' => 'available', ...$bay,
        ]));

        $categories = $this->seedServiceCategories($tenantId);
        $this->seedInventory($tenantId);

        return [
            'owner'        => $owner,
            'technicians'  => $technicians,
            'advisor'      => $advisor,
            'bays'         => $bays,
            'categories'   => $categories,
            'tax_rate_id'  => TaxRate::where('code', 'GST18')->value('id'),
            'cash_method'  => PaymentMethod::where('code', 'CASH')->first(),
            'upi_method'   => PaymentMethod::where('code', 'UPI')->first(),
        ];
    }

    private function seedServiceCategories(int $tenantId)
    {
        $definitions = [
            ['name' => 'Oil Service', 'code' => 'OIL_SVC', 'duration' => 45, 'items' => [
                ['name' => 'Engine Oil Change (3.5L)', 'code' => 'OIL_3L', 'price' => 1299],
                ['name' => 'Oil Filter Replacement', 'code' => 'OIL_FILTER', 'price' => 349],
            ]],
            ['name' => 'Tyre Service', 'code' => 'TYRE_SVC', 'duration' => 60, 'items' => [
                ['name' => 'Wheel Balancing (4 tyres)', 'code' => 'WHEEL_BAL', 'price' => 799],
                ['name' => 'Wheel Alignment', 'code' => 'WHEEL_ALIGN', 'price' => 899],
            ]],
            ['name' => 'Brakes', 'code' => 'BRAKE_SVC', 'duration' => 90, 'items' => [
                ['name' => 'Brake Pad Replacement (Front)', 'code' => 'BRAKE_F', 'price' => 2499],
            ]],
            ['name' => 'AC Service', 'code' => 'AC_SVC', 'duration' => 120, 'items' => [
                ['name' => 'AC Gas Recharge', 'code' => 'AC_GAS', 'price' => 2199],
            ]],
            ['name' => 'General Inspection', 'code' => 'GEN_INSP', 'duration' => 60, 'items' => [
                ['name' => '40-Point Inspection', 'code' => 'INSP_40', 'price' => 499],
            ]],
        ];

        return collect($definitions)->map(function ($cat, $i) use ($tenantId) {
            $category = ServiceCategory::create([
                'tenant_id' => $tenantId,
                'name' => $cat['name'],
                'code' => $cat['code'],
                'default_duration_min' => $cat['duration'],
                'sort_order' => $i,
            ]);

            foreach ($cat['items'] as $j => $item) {
                ServiceItem::create([
                    'tenant_id' => $tenantId,
                    'category_id' => $category->id,
                    'name' => $item['name'],
                    'code' => $item['code'],
                    'default_price' => $item['price'],
                    'sort_order' => $j,
                ]);
            }

            return $category;
        });
    }

    private function seedInventory(int $tenantId): void
    {
        $parts = [
            ['sku' => 'OIL-5W30-4L', 'name' => 'Castrol Magnatec 5W30 (4L)', 'brand' => 'Castrol', 'cost' => 980, 'sell' => 1299, 'stock' => 24, 'low' => 6],
            ['sku' => 'FILTER-OIL-01', 'name' => 'Oil Filter — Maruti/Hyundai', 'brand' => 'Bosch', 'cost' => 180, 'sell' => 349, 'stock' => 40, 'low' => 10],
            ['sku' => 'PAD-BRAKE-F', 'name' => 'Front Brake Pads Set', 'brand' => 'Brembo', 'cost' => 1200, 'sell' => 1899, 'stock' => 12, 'low' => 4],
            ['sku' => 'BAT-45AH', 'name' => 'Exide 45Ah Battery', 'brand' => 'Exide', 'cost' => 3200, 'sell' => 4299, 'stock' => 8, 'low' => 2],
            ['sku' => 'AC-GAS-R134', 'name' => 'AC Refrigerant R134a', 'brand' => 'Honeywell', 'cost' => 450, 'sell' => 699, 'stock' => 15, 'low' => 5],
            ['sku' => 'WIPER-18', 'name' => 'Wiper Blade 18 inch', 'brand' => 'Bosch', 'cost' => 220, 'sell' => 399, 'stock' => 3, 'low' => 5],
            ['sku' => 'COOLANT-1L', 'name' => 'Engine Coolant 1L', 'brand' => 'Motul', 'cost' => 280, 'sell' => 449, 'stock' => 18, 'low' => 6],
            ['sku' => 'SPARK-4SET', 'name' => 'Spark Plug Set (4)', 'brand' => 'NGK', 'cost' => 640, 'sell' => 999, 'stock' => 10, 'low' => 4],
        ];

        foreach ($parts as $part) {
            InventoryItem::create([
                'tenant_id'           => $tenantId,
                'sku'                 => $part['sku'],
                'name'                => $part['name'],
                'brand'               => $part['brand'],
                'cost_price'          => $part['cost'],
                'selling_price'       => $part['sell'],
                'stock_on_hand'       => $part['stock'],
                'low_stock_threshold' => $part['low'],
                'unit_of_measure'     => 'piece',
            ]);
        }
    }

    private function seedCustomers(Tenant $tenant, array $context): array
    {
        $customers = [];

        for ($i = 0; $i < 50; $i++) {
            $phone = '+9198765' . str_pad((string) (10001 + $i), 5, '0', STR_PAD_LEFT);
            $customer = Customer::create([
                'phone_primary' => $phone,
                'first_name'    => self::FIRST_NAMES[$i],
                'last_name'     => self::LAST_NAMES[$i],
                'email'         => strtolower(self::FIRST_NAMES[$i] . '.' . self::LAST_NAMES[$i] . '@email.com'),
            ]);

            GarageCustomer::create([
                'customer_id'     => $customer->id,
                'tenant_id'       => $tenant->id,
                'loyalty_points'  => rand(50, 1200),
                'total_spent'     => 0,
                'visit_count'     => 0,
                'last_visited_at' => null,
            ]);

            $vehicleCount = $i < 25 ? 1 : ($i < 42 ? 2 : 3);
            $vehicles = [];

            for ($v = 0; $v < $vehicleCount; $v++) {
                $city = self::CITIES[($i + $v) % count(self::CITIES)];
                $car = self::CAR_MODELS[($i + $v) % count(self::CAR_MODELS)];
                $regLetters = chr(65 + ($i % 26)) . chr(65 + (($i + $v) % 26));
                $regNumber = $city['code'] . $regLetters . str_pad((string) (1000 + $i + ($v * 17)), 4, '0', STR_PAD_LEFT);
                $year = 2018 + (($i + $v) % 7);
                $odometer = 12000 + ($i * 1300) + ($v * 4800) + rand(0, 5000);

                $vehicles[] = Vehicle::create([
                    'customer_id'         => $customer->id,
                    'registration_number' => $regNumber,
                    'maker'               => $car[0],
                    'model'               => $car[1],
                    'variant'             => $car[2],
                    'year'                => $year,
                    'fuel_type'           => $car[3],
                    'color'               => ['White', 'Silver', 'Black', 'Red', 'Blue'][$i % 5],
                    'odometer_reading'    => $odometer,
                ]);
            }

            $customers[] = ['customer' => $customer, 'vehicles' => $vehicles];
        }

        return $customers;
    }

    private function seedOperationalData(Tenant $tenant, User $owner, array $context, array $customers): array
    {
        $tenantId = $tenant->id;
        $technicians = $context['technicians'];
        $categories = $context['categories'];
        $taxRateId = $context['tax_rate_id'];
        $cashMethod = $context['cash_method'];
        $upiMethod = $context['upi_method'];

        $jobCount = 0;
        $invoiceCount = 0;
        $vehicleCount = 0;
        $totalSpentByCustomer = [];

        foreach ($customers as $index => $entry) {
            $customer = $entry['customer'];
            $totalSpentByCustomer[$customer->id] = 0;

            foreach ($entry['vehicles'] as $vehicleIndex => $vehicle) {
                $vehicleCount++;
                $historyJobs = 4 + ($vehicleIndex % 2);

                for ($h = 0; $h < $historyJobs; $h++) {
                    $daysAgo = 30 + ($index * 11) + ($vehicleIndex * 17) + ($h * 45);
                    $completedAt = now()->subDays($daysAgo)->setHour(10 + ($h % 6));
                    $technician = $technicians[$jobCount % $technicians->count()];
                    $complaint = self::COMPLAINTS[($index + $h) % count(self::COMPLAINTS)];
                    $taskName = self::TASK_NAMES[($index + $vehicleIndex + $h) % count(self::TASK_NAMES)];
                    $labour = 800 + (($index + $h) % 8) * 350;
                    $parts = 400 + (($vehicleIndex + $h) % 5) * 250;
                    $total = $labour + $parts;
                    $tax = round($total * 0.18, 2);

                    $job = ServiceJob::withoutGlobalScopes()->create([
                        'tenant_id'             => $tenantId,
                        'customer_id'           => $customer->id,
                        'vehicle_id'            => $vehicle->id,
                        'status'                => 'delivered',
                        'priority'              => ['low', 'normal', 'urgent'][$h % 3],
                        'odometer_at_intake'    => max(5000, $vehicle->odometer_reading - rand(500, 2500)),
                        'fuel_level'            => 'half',
                        'customer_complaint'    => $complaint,
                        'primary_technician_id' => $technician->id,
                        'actual_start_at'       => $completedAt->copy()->subHours(4),
                        'actual_completion_at'  => $completedAt,
                        'estimated_amount'      => $total,
                        'approval_status'       => 'approved',
                        'customer_approved_at'  => $completedAt->copy()->subHours(5),
                        'created_by'            => $owner->id,
                    ]);

                    $job->serviceCategories()->attach($categories[$h % $categories->count()]->id, [
                        'is_primary' => true,
                        'sort_order' => 0,
                    ]);

                    JobTask::create([
                        'job_id' => $job->id,
                        'name' => $taskName,
                        'status' => 'completed',
                        'estimated_price' => $labour,
                        'final_price' => $labour,
                        'labor_minutes' => 60 + ($h * 15),
                        'assigned_technician_id' => $technician->id,
                        'is_billable' => true,
                    ]);

                    JobTask::create([
                        'job_id' => $job->id,
                        'name' => 'Parts and consumables',
                        'status' => 'completed',
                        'estimated_price' => $parts,
                        'final_price' => $parts,
                        'assigned_technician_id' => $technician->id,
                        'is_billable' => true,
                    ]);

                    $invoice = Invoice::withoutGlobalScopes()->create([
                        'tenant_id'   => $tenantId,
                        'customer_id' => $customer->id,
                        'vehicle_id'  => $vehicle->id,
                        'job_id'      => $job->id,
                        'type'        => 'final',
                        'status'      => 'paid',
                        'issued_date' => $completedAt,
                        'paid_at'     => $completedAt,
                    ]);

                    InvoiceItem::create([
                        'invoice_id' => $invoice->id,
                        'line_type' => 'service',
                        'name' => $taskName,
                        'quantity' => 1,
                        'unit_price' => $labour,
                        'tax_rate_id' => $taxRateId,
                        'tax_amount' => round($labour * 0.18, 2),
                        'total_amount' => $labour + round($labour * 0.18, 2),
                        'sort_order' => 0,
                    ]);

                    InvoiceItem::create([
                        'invoice_id' => $invoice->id,
                        'line_type' => 'part',
                        'name' => 'Parts and consumables',
                        'quantity' => 1,
                        'unit_price' => $parts,
                        'tax_rate_id' => $taxRateId,
                        'tax_amount' => round($parts * 0.18, 2),
                        'total_amount' => $parts + round($parts * 0.18, 2),
                        'sort_order' => 1,
                    ]);

                    $invoice->recalculate();
                    $invoice->update(['status' => 'paid', 'paid_at' => $completedAt]);

                    Payment::create([
                        'tenant_id' => $tenantId,
                        'invoice_id' => $invoice->id,
                        'payment_method_id' => ($h % 2 === 0 ? $cashMethod?->id : $upiMethod?->id),
                        'amount' => $invoice->grand_total,
                        'currency' => 'INR',
                        'status' => 'success',
                        'payment_type' => 'customer_pay',
                        'paid_at' => $completedAt,
                        'reference_number' => ($h % 2 === 1) ? 'UPI' . rand(100000, 999999) : null,
                    ]);

                    $totalSpentByCustomer[$customer->id] += (float) $invoice->grand_total;
                    $jobCount++;
                    $invoiceCount++;
                }

                $vehicle->update(['odometer_reading' => $vehicle->odometer_reading + ($historyJobs * 800)]);
            }

            GarageCustomer::where('customer_id', $customer->id)
                ->where('tenant_id', $tenantId)
                ->update([
                    'total_spent'     => $totalSpentByCustomer[$customer->id],
                    'visit_count'     => count($entry['vehicles']) * 4,
                    'last_visited_at' => now()->subDays(rand(5, 120)),
                ]);
        }

        $activeSpecs = [
            ['status' => 'in_progress', 'bay' => 0, 'priority' => 'urgent'],
            ['status' => 'in_progress', 'bay' => 1, 'priority' => 'normal'],
            ['status' => 'estimate_pending', 'bay' => null, 'priority' => 'normal'],
            ['status' => 'ready_for_delivery', 'bay' => null, 'priority' => 'low'],
            ['status' => 'quality_check', 'bay' => 4, 'priority' => 'normal'],
            ['status' => 'checked_in', 'bay' => null, 'priority' => 'normal'],
        ];

        $bays = $context['bays'];
        foreach ($activeSpecs as $i => $spec) {
            $entry = $customers[$i % count($customers)];
            $vehicle = $entry['vehicles'][0];
            $technician = $technicians[$i % $technicians->count()];
            $bay = $spec['bay'] !== null ? $bays[$spec['bay']] : null;

            ServiceJob::withoutGlobalScopes()->create([
                'tenant_id'             => $tenantId,
                'customer_id'           => $entry['customer']->id,
                'vehicle_id'            => $vehicle->id,
                'status'                => $spec['status'],
                'priority'              => $spec['priority'],
                'odometer_at_intake'    => $vehicle->odometer_reading,
                'fuel_level'            => 'three_quarter',
                'customer_complaint'    => self::COMPLAINTS[$i % count(self::COMPLAINTS)],
                'primary_technician_id' => $technician->id,
                'assigned_bay_id'       => $bay?->id,
                'actual_start_at'       => now()->subHours(2 + $i),
                'estimated_completion_at' => now()->addHours(3 + $i),
                'estimated_amount'      => 2500 + ($i * 500),
                'approval_status'       => in_array($spec['status'], ['estimate_pending', 'checked_in'], true) ? 'pending' : 'approved',
                'created_by'            => $owner->id,
            ]);

            if ($bay && $spec['status'] === 'in_progress') {
                $bay->update(['status' => 'occupied']);
            }

            $jobCount++;
        }

        $appointmentCount = 0;
        for ($a = 0; $a < 6; $a++) {
            $entry = $customers[40 + $a];
            Appointment::create([
                'tenant_id'            => $tenantId,
                'customer_id'          => $entry['customer']->id,
                'vehicle_id'           => $entry['vehicles'][0]->id,
                'service_category_id'  => $categories[$a % $categories->count()]->id,
                'scheduled_date'       => now()->toDateString(),
                'start_time'           => sprintf('%02d:00:00', 9 + $a),
                'end_time'             => sprintf('%02d:30:00', 9 + $a),
                'status'               => ['booked', 'confirmed', 'checked_in'][$a % 3],
                'source'               => 'phone',
                'assigned_technician_id' => $technicians[$a % $technicians->count()]->id,
                'created_by'           => $owner->id,
            ]);
            $appointmentCount++;
        }

        return [
            'customers'     => 50,
            'vehicles'      => $vehicleCount,
            'jobs'          => $jobCount,
            'invoices'      => $invoiceCount,
            'appointments'  => $appointmentCount,
            'active_jobs'   => count($activeSpecs),
        ];
    }
}
