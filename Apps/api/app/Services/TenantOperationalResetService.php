<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\AuditLog;
use App\Models\FeedbackReview;
use App\Models\GarageCustomer;
use App\Models\Invoice;
use App\Models\JobInspectionRecord;
use App\Models\LoyaltyTransaction;
use App\Models\Payment;
use App\Models\ServiceJob;
use App\Models\StaffNotification;
use App\Models\Tenant;
use App\Models\Vehicle;
use App\Models\VehicleDocument;
use App\Models\VehicleMileageLog;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TenantOperationalResetService
{
    public function reset(Tenant $tenant, bool $resetOnboarding = false): void
    {
        DB::transaction(function () use ($tenant, $resetOnboarding) {
            $tenantId = $tenant->id;
            $customerIds = GarageCustomer::where('tenant_id', $tenantId)->pluck('customer_id');
            $vehicleIds = Vehicle::whereIn('customer_id', $customerIds)->pluck('id');
            $jobIds = ServiceJob::withoutGlobalScopes()->where('tenant_id', $tenantId)->pluck('id');
            $invoiceIds = Invoice::withoutGlobalScopes()->where('tenant_id', $tenantId)->pluck('id');

            Payment::whereIn('invoice_id', $invoiceIds)->delete();

            if (Schema::hasTable('invoice_items')) {
                DB::table('invoice_items')->whereIn('invoice_id', $invoiceIds)->delete();
            }

            Invoice::withoutGlobalScopes()->where('tenant_id', $tenantId)->forceDelete();
            JobInspectionRecord::whereIn('job_id', $jobIds)->delete();

            if (Schema::hasTable('job_tasks')) {
                DB::table('job_tasks')->whereIn('job_id', $jobIds)->delete();
            }

            if (Schema::hasTable('job_service_categories')) {
                DB::table('job_service_categories')->whereIn('job_id', $jobIds)->delete();
            }

            ServiceJob::withoutGlobalScopes()->where('tenant_id', $tenantId)->forceDelete();
            Appointment::where('tenant_id', $tenantId)->delete();
            StaffNotification::where('tenant_id', $tenantId)->delete();
            AuditLog::where('tenant_id', $tenantId)->delete();
            FeedbackReview::where('tenant_id', $tenantId)->delete();
            LoyaltyTransaction::where('tenant_id', $tenantId)->delete();

            VehicleDocument::whereIn('vehicle_id', $vehicleIds)->delete();
            VehicleMileageLog::whereIn('vehicle_id', $vehicleIds)->delete();
            Vehicle::whereIn('id', $vehicleIds)->delete();
            GarageCustomer::where('tenant_id', $tenantId)->delete();

            DB::table('customers')
                ->whereIn('id', $customerIds)
                ->whereNotExists(function ($q) {
                    $q->select(DB::raw(1))
                        ->from('garage_customers')
                        ->whereColumn('garage_customers.customer_id', 'customers.id');
                })
                ->delete();

            if ($resetOnboarding) {
                $tenant->update([
                    'setup_step'         => 'welcome',
                    'setup_completed_at' => null,
                    'setup_bay_count'    => null,
                ]);
            }
        });
    }
}
