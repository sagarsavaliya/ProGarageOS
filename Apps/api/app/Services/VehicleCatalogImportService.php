<?php

namespace App\Services;

use App\Models\VehicleColor;
use App\Models\VehicleMake;
use App\Models\VehicleModel;
use App\Models\VehicleVariant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class VehicleCatalogImportService
{
    public function importFromDirectory(string $directory, bool $fresh = false): array
    {
        $stats = [
            'makes'           => 0,
            'models'          => 0,
            'variants'        => 0,
            'variant_colors'  => 0,
            'skipped_rows'    => 0,
        ];

        DB::transaction(function () use ($directory, $fresh, &$stats) {
            if ($fresh) {
                DB::table('vehicle_variant_colors')->delete();
                VehicleVariant::query()->forceDelete();
                VehicleModel::query()->forceDelete();
                VehicleMake::query()->forceDelete();
            }

            $stats['makes'] = $this->importMakes("{$directory}/makes.csv", $stats);
            $stats['models'] = $this->importModels("{$directory}/models.csv", $stats);
            $stats['variants'] = $this->importVariants("{$directory}/variants.csv", $stats);
            $stats['variant_colors'] = $this->importVariantColors("{$directory}/variant_colors.csv", $stats);
        });

        return $stats;
    }

    private function importMakes(string $path, array &$stats): int
    {
        $rows = $this->readCsv($path);
        $count = 0;

        foreach ($rows as $row) {
            $name = trim($row['name'] ?? '');
            if ($name === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $category = strtolower(trim($row['vehicle_category'] ?? 'car'));
            if (! in_array($category, ['car', 'bike', 'commercial', 'luxury'], true)) {
                $category = 'car';
            }

            VehicleMake::updateOrCreate(
                ['slug' => $this->slug($name), 'vehicle_category' => $category],
                [
                    'name'          => $name,
                    'country_code'  => strtoupper(trim($row['country_code'] ?? 'IN')),
                    'sort_order'    => (int) ($row['sort_order'] ?? 0),
                    'is_active'     => $this->boolValue($row['is_active'] ?? '1'),
                ]
            );
            $count++;
        }

        return $count;
    }

    private function importModels(string $path, array &$stats): int
    {
        $rows = $this->readCsv($path);
        $count = 0;

        foreach ($rows as $row) {
            $makeName = trim($row['make_name'] ?? '');
            $modelName = trim($row['model_name'] ?? '');
            if ($makeName === '' || $modelName === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $make = $this->findMake($makeName, $row['vehicle_category'] ?? 'car');
            if (! $make) {
                $stats['skipped_rows']++;
                continue;
            }

            VehicleModel::updateOrCreate(
                ['vehicle_make_id' => $make->id, 'slug' => $this->slug($modelName)],
                [
                    'name'       => $modelName,
                    'body_type'  => $this->nullableString($row['body_type'] ?? null),
                    'sort_order' => (int) ($row['sort_order'] ?? 0),
                    'is_active'  => $this->boolValue($row['is_active'] ?? '1'),
                ]
            );
            $count++;
        }

        return $count;
    }

    private function importVariants(string $path, array &$stats): int
    {
        $rows = $this->readCsv($path);
        $count = 0;

        foreach ($rows as $row) {
            $makeName = trim($row['make_name'] ?? '');
            $modelName = trim($row['model_name'] ?? '');
            $variantName = trim($row['variant_name'] ?? '');
            if ($makeName === '' || $modelName === '' || $variantName === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $make = $this->findMake($makeName, $row['vehicle_category'] ?? 'car');
            if (! $make) {
                $stats['skipped_rows']++;
                continue;
            }

            $model = VehicleModel::where('vehicle_make_id', $make->id)
                ->where('slug', $this->slug($modelName))
                ->first();
            if (! $model) {
                $stats['skipped_rows']++;
                continue;
            }

            $yearFrom = $this->nullableInt($row['year_from'] ?? null);
            $slug = $this->slug($variantName . ($yearFrom ? "-{$yearFrom}" : ''));

            VehicleVariant::updateOrCreate(
                [
                    'vehicle_model_id' => $model->id,
                    'slug'             => $slug,
                    'year_from'        => $yearFrom,
                ],
                [
                    'name'         => $variantName,
                    'fuel_type'    => $this->nullableFuelType($row['fuel_type'] ?? null),
                    'transmission' => $this->nullableTransmission($row['transmission'] ?? null),
                    'year_to'      => $this->nullableInt($row['year_to'] ?? null),
                    'sort_order'   => (int) ($row['sort_order'] ?? 0),
                    'is_active'    => $this->boolValue($row['is_active'] ?? '1'),
                ]
            );
            $count++;
        }

        return $count;
    }

    private function importVariantColors(string $path, array &$stats): int
    {
        if (! is_file($path)) {
            return 0;
        }

        $rows = $this->readCsv($path);
        $count = 0;

        foreach ($rows as $row) {
            $makeName = trim($row['make_name'] ?? '');
            $modelName = trim($row['model_name'] ?? '');
            $variantName = trim($row['variant_name'] ?? '');
            $colorName = trim($row['color_name'] ?? '');
            if ($makeName === '' || $modelName === '' || $variantName === '' || $colorName === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $variant = $this->findVariant($makeName, $modelName, $variantName, $row);
            $color = VehicleColor::where('slug', $this->slug($colorName))->first();
            if (! $variant || ! $color) {
                $stats['skipped_rows']++;
                continue;
            }

            $variant->colors()->syncWithoutDetaching([
                $color->id => ['is_default' => $this->boolValue($row['is_default'] ?? '0')],
            ]);
            $count++;
        }

        return $count;
    }

    private function findMake(string $makeName, string $category = 'car'): ?VehicleMake
    {
        $category = strtolower(trim($category));
        if (! in_array($category, ['car', 'bike', 'commercial', 'luxury'], true)) {
            $category = 'car';
        }

        return VehicleMake::where('slug', $this->slug($makeName))
            ->where('vehicle_category', $category)
            ->first();
    }

    private function findVariant(string $makeName, string $modelName, string $variantName, array $row): ?VehicleVariant
    {
        $make = $this->findMake($makeName, $row['vehicle_category'] ?? 'car');
        if (! $make) {
            return null;
        }

        $model = VehicleModel::where('vehicle_make_id', $make->id)
            ->where('slug', $this->slug($modelName))
            ->first();
        if (! $model) {
            return null;
        }

        $yearFrom = $this->nullableInt($row['year_from'] ?? null);
        $slug = $this->slug($variantName . ($yearFrom ? "-{$yearFrom}" : ''));

        return VehicleVariant::where('vehicle_model_id', $model->id)
            ->where('slug', $slug)
            ->when($yearFrom !== null, fn ($q) => $q->where('year_from', $yearFrom))
            ->first();
    }

    private function readCsv(string $path): array
    {
        if (! is_file($path)) {
            throw new \InvalidArgumentException("CSV file not found: {$path}");
        }

        $handle = fopen($path, 'rb');
        if ($handle === false) {
            throw new \RuntimeException("Unable to open CSV file: {$path}");
        }

        $headers = fgetcsv($handle);
        if ($headers === false) {
            fclose($handle);
            return [];
        }

        $headers = array_map(fn ($h) => strtolower(trim((string) $h)), $headers);
        $rows = [];

        while (($data = fgetcsv($handle)) !== false) {
            if (count(array_filter($data, fn ($v) => trim((string) $v) !== '')) === 0) {
                continue;
            }
            $row = [];
            foreach ($headers as $i => $header) {
                $row[$header] = $data[$i] ?? null;
            }
            $rows[] = $row;
        }

        fclose($handle);

        return $rows;
    }

    private function slug(string $value): string
    {
        return Str::slug(trim($value));
    }

    private function boolValue(mixed $value): bool
    {
        $normalized = strtolower(trim((string) $value));
        return in_array($normalized, ['1', 'true', 'yes', 'y'], true);
    }

    private function nullableString(?string $value): ?string
    {
        $value = trim((string) $value);
        return $value === '' ? null : $value;
    }

    private function nullableInt(mixed $value): ?int
    {
        if ($value === null || trim((string) $value) === '') {
            return null;
        }

        return (int) $value;
    }

    private function nullableFuelType(?string $value): ?string
    {
        $value = strtolower(trim((string) $value));
        $allowed = ['petrol', 'diesel', 'electric', 'cng', 'lpg', 'hybrid'];
        return in_array($value, $allowed, true) ? $value : null;
    }

    private function nullableTransmission(?string $value): ?string
    {
        $value = strtolower(trim((string) $value));
        $allowed = ['manual', 'automatic', 'cvt', 'amt'];
        return in_array($value, $allowed, true) ? $value : null;
    }
}
