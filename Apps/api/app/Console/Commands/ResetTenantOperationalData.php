<?php

namespace App\Console\Commands;

use App\Models\Tenant;
use App\Models\User;
use App\Services\TenantOperationalResetService;
use Illuminate\Console\Command;

class ResetTenantOperationalData extends Command
{
    public function __construct(private TenantOperationalResetService $resetService)
    {
        parent::__construct();
    }

    protected $signature = 'progarage:reset-tenant-data
                            {--phone= : Owner or staff phone (digits only, e.g. 8141302341)}
                            {--tenant= : Tenant UUID}
                            {--reset-onboarding : Clear setup_completed so owner can run onboarding again}
                            {--force : Required to execute}';

    protected $description = 'Remove operational test data (jobs, customers, invoices, vehicles) for one garage tenant';

    public function handle(): int
    {
        if (! $this->option('force')) {
            $this->error('Add --force to confirm this destructive operation.');
            return self::FAILURE;
        }

        $tenant = $this->resolveTenant();
        if (! $tenant) {
            $this->error('Tenant not found. Use --phone= or --tenant=uuid.');
            return self::FAILURE;
        }

        $this->warn("Resetting operational data for tenant #{$tenant->id} ({$tenant->business_name})");

        $this->resetService->reset($tenant, $this->option('reset-onboarding'));

        $this->info('Operational data cleared. Users, bays, categories, and tax rates were kept.');
        if ($this->option('reset-onboarding')) {
            $this->info('Onboarding flags reset — owner can complete setup again.');
        }

        return self::SUCCESS;
    }

    private function resolveTenant(): ?Tenant
    {
        if ($uuid = $this->option('tenant')) {
            return Tenant::where('uuid', $uuid)->first();
        }

        $phone = preg_replace('/\D/', '', (string) $this->option('phone'));
        if ($phone === '') {
            return null;
        }

        $user = User::where('phone', 'like', "%{$phone}")->first();
        if (! $user?->tenant_id) {
            return null;
        }

        return Tenant::find($user->tenant_id);
    }
}
