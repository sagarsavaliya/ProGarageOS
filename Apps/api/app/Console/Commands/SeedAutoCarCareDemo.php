<?php

namespace App\Console\Commands;

use App\Services\AutoCarCareDemoSeeder;
use Illuminate\Console\Command;

class SeedAutoCarCareDemo extends Command
{
    protected $signature = 'progarage:seed-auto-car-care
                            {--force : Required to run on production}';

    protected $description = 'Create or refresh the Auto Car Care demo tenant with realistic Indian garage data';

    public function __construct(private AutoCarCareDemoSeeder $seeder)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        if (! $this->option('force')) {
            $this->error('This command writes demo data. Re-run with --force to confirm.');
            return self::FAILURE;
        }

        $this->info('Seeding Auto Car Care demo tenant...');
        $stats = $this->seeder->seed();

        $this->newLine();
        $this->info('Demo tenant ready.');
        $this->table(['Field', 'Value'], collect($stats)->map(fn ($v, $k) => [$k, is_scalar($v) ? (string) $v : json_encode($v)])->values()->all());
        $this->newLine();
        $this->line('Login: ' . AutoCarCareDemoSeeder::OWNER_PHONE . ' / PIN ' . AutoCarCareDemoSeeder::OWNER_PIN);
        $this->line('Web: https://app.progarage.cloud · API: https://api.progarage.cloud/api');

        return self::SUCCESS;
    }
}
