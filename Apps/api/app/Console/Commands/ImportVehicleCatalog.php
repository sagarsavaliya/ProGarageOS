<?php

namespace App\Console\Commands;

use App\Services\VehicleCatalogImportService;
use App\Services\VehicleCatalogJsonImportService;
use Database\Seeders\VehicleColorSeeder;
use Illuminate\Console\Command;

class ImportVehicleCatalog extends Command
{
    public function __construct(
        private VehicleCatalogImportService $csvImporter,
        private VehicleCatalogJsonImportService $jsonImporter,
    ) {
        parent::__construct();
    }

    protected $signature = 'progarage:import-vehicle-catalog
                            {--path= : Directory containing makes/models/variants/variant_colors CSV files}
                            {--json= : Path to vehicle_master.json scraped catalog}
                            {--fresh : Clear existing make/model/variant catalog before import}
                            {--seed-colors : Seed standard vehicle colors before import}';

    protected $description = 'Import vehicle make/model/variant/color catalog from CSV or JSON';

    public function handle(): int
    {
        if ($this->option('seed-colors')) {
            $this->info('Seeding standard vehicle colors...');
            (new VehicleColorSeeder())->run();
        }

        if ($this->option('fresh')) {
            $this->warn('Clearing existing vehicle catalog (makes, models, variants, color links)...');
        }

        try {
            if ($json = $this->option('json')) {
                $jsonPath = $this->resolveJsonPath($json);
                $this->info("Importing vehicle catalog from JSON: {$jsonPath}");
                $stats = $this->jsonImporter->importFromJson($jsonPath, (bool) $this->option('fresh'));
            } else {
                $path = $this->option('path')
                    ?: database_path('seeders/data/vehicle-catalog');

                if (! is_dir($path)) {
                    $this->error("Catalog directory not found: {$path}");
                    return self::FAILURE;
                }

                $stats = $this->csvImporter->importFromDirectory($path, (bool) $this->option('fresh'));
            }
        } catch (\Throwable $e) {
            $this->error($e->getMessage());
            return self::FAILURE;
        }

        $this->info('Vehicle catalog import complete.');
        $this->table(
            ['Metric', 'Count'],
            collect($stats)->map(fn ($value, $key) => [$key, $value])->values()->all()
        );

        return self::SUCCESS;
    }

    private function resolveJsonPath(string $json): string
    {
        if (is_file($json)) {
            return $json;
        }

        $candidates = [
            base_path($json),
            database_path("seeders/data/vehicle-catalog/{$json}"),
            base_path("../Car Make Modal Scraper/{$json}"),
        ];

        foreach ($candidates as $candidate) {
            if (is_file($candidate)) {
                return $candidate;
            }
        }

        throw new \InvalidArgumentException("JSON file not found: {$json}");
    }
}
