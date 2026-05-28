<?php

namespace App\Services;

use App\Models\VehicleColor;
use App\Models\VehicleMake;
use App\Models\VehicleModel;
use App\Models\VehicleVariant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class VehicleCatalogJsonImportService
{
    /** @var array<string, true> */
    private const LUXURY_MAKE_SLUGS = [
        'aston-martin' => true,
        'bentley'      => true,
        'ferrari'      => true,
        'lamborghini'  => true,
        'maserati'     => true,
        'mclaren'      => true,
        'rolls-royce'  => true,
        'porsche'      => true,
    ];

    /** @var array<string, true> */
    private const COMMERCIAL_MAKE_SLUGS = [
        'force-motors' => true,
        'isuzu'        => true,
    ];

    /** @var array<int, VehicleMake> */
    private array $makeBySourceId = [];

    /** @var array<int, VehicleModel> */
    private array $modelBySourceId = [];

    /** @var array<string, VehicleColor> */
    private array $colorsBySlug = [];

    public function importFromJson(string $jsonPath, bool $fresh = false): array
    {
        if (! is_file($jsonPath)) {
            throw new \InvalidArgumentException("JSON file not found: {$jsonPath}");
        }

        $payload = json_decode(file_get_contents($jsonPath), true);
        if (! is_array($payload)) {
            throw new \InvalidArgumentException('Invalid vehicle catalog JSON.');
        }

        $stats = [
            'makes'          => 0,
            'models'         => 0,
            'variants'       => 0,
            'variant_colors' => 0,
            'skipped_rows'   => 0,
            'source'         => $payload['meta']['source'] ?? 'unknown',
        ];

        DB::transaction(function () use ($payload, $fresh, &$stats) {
            if ($fresh) {
                DB::table('vehicle_variant_colors')->delete();
                VehicleVariant::query()->forceDelete();
                VehicleModel::query()->forceDelete();
                VehicleMake::query()->forceDelete();
            }

            $this->colorsBySlug = VehicleColor::all()->keyBy('slug')->all();

            $stats['makes'] = $this->importMakes($payload['makes'] ?? [], $stats);
            $stats['models'] = $this->importModels($payload['models'] ?? [], $stats);
            $stats['variants'] = $this->importVariants($payload['variants'] ?? [], $stats);
        });

        return $stats;
    }

    private function importMakes(array $makes, array &$stats): int
    {
        $count = 0;

        foreach ($makes as $index => $make) {
            $name = trim((string) ($make['name'] ?? ''));
            $slug = trim((string) ($make['slug'] ?? ''));
            if ($name === '' || $slug === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $category = $this->resolveCategory($slug);
            $record = VehicleMake::updateOrCreate(
                ['slug' => $slug, 'vehicle_category' => $category],
                [
                    'name'         => $name,
                    'country_code' => 'IN',
                    'sort_order'   => $index + 1,
                    'is_active'    => $category === 'car',
                ]
            );

            if (isset($make['id'])) {
                $this->makeBySourceId[(int) $make['id']] = $record;
            }

            $count++;
        }

        return $count;
    }

    private function importModels(array $models, array &$stats): int
    {
        $count = 0;

        foreach ($models as $index => $model) {
            $sourceMakeId = (int) ($model['make_id'] ?? 0);
            $name = trim((string) ($model['name'] ?? ''));
            if ($sourceMakeId <= 0 || $name === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $make = $this->makeBySourceId[$sourceMakeId] ?? null;
            if (! $make) {
                $stats['skipped_rows']++;
                continue;
            }

            $record = VehicleModel::updateOrCreate(
                ['vehicle_make_id' => $make->id, 'slug' => $this->slug($name)],
                [
                    'name'       => $name,
                    'body_type'  => $this->normalizeBodyType($model['body_type'] ?? null),
                    'sort_order' => $index + 1,
                    'is_active'  => $make->is_active,
                ]
            );

            if (isset($model['id'])) {
                $this->modelBySourceId[(int) $model['id']] = $record;
            }

            $count++;
        }

        return $count;
    }

    private function importVariants(array $variants, array &$stats): int
    {
        $count = 0;

        foreach ($variants as $index => $variant) {
            if ($this->shouldSkipVariant($variant)) {
                $stats['skipped_rows']++;
                continue;
            }

            $sourceModelId = (int) ($variant['model_id'] ?? 0);
            $model = $this->modelBySourceId[$sourceModelId] ?? null;
            if (! $model) {
                $stats['skipped_rows']++;
                continue;
            }

            $year = isset($variant['year']) ? (int) $variant['year'] : null;
            $variantSlug = trim((string) ($variant['slug'] ?? ''));
            $variantName = trim((string) ($variant['name'] ?? $variantSlug));
            if ($variantSlug === '' || $variantName === '') {
                $stats['skipped_rows']++;
                continue;
            }

            $slug = $this->slug($variantSlug . ($year ? "-{$year}" : ''));

            $record = VehicleVariant::updateOrCreate(
                [
                    'vehicle_model_id' => $model->id,
                    'slug'             => $slug,
                    'year_from'        => $year,
                ],
                [
                    'name'         => $variantName,
                    'fuel_type'    => $this->normalizeFuelType($variant['fuel_type'] ?? null),
                    'transmission' => $this->normalizeTransmission($variant['transmission'] ?? null),
                    'year_to'      => $year,
                    'sort_order'   => $index + 1,
                    'is_active'    => $model->is_active,
                ]
            );

            $stats['variant_colors'] += $this->syncVariantColors(
                $record,
                $variant['colors'] ?? [],
                $stats
            );

            $count++;
        }

        return $count;
    }

    private function syncVariantColors(VehicleVariant $variant, array $colors, array &$stats): int
    {
        $mapped = [];
        $isFirst = true;

        foreach ($colors as $rawColor) {
            $rawColor = trim((string) $rawColor);
            if ($rawColor === '') {
                continue;
            }

            $colorSlug = $this->mapToStandardColorSlug($rawColor);
            $color = $this->colorsBySlug[$colorSlug] ?? $this->colorsBySlug['other'] ?? null;
            if (! $color) {
                $stats['skipped_rows']++;
                continue;
            }

            $mapped[$color->id] = ['is_default' => $isFirst];
            $isFirst = false;
        }

        if ($mapped === []) {
            return 0;
        }

        $variant->colors()->sync($mapped);

        return count($mapped);
    }

    private function shouldSkipVariant(array $variant): bool
    {
        $slug = strtolower(trim((string) ($variant['slug'] ?? '')));
        if ($slug === 'range') {
            return true;
        }

        $fuel = $variant['fuel_type'] ?? null;
        $transmission = $variant['transmission'] ?? null;
        $colors = $variant['colors'] ?? [];

        return $fuel === null && $transmission === null && $colors === [];
    }

    private function resolveCategory(string $slug): string
    {
        if (isset(self::LUXURY_MAKE_SLUGS[$slug])) {
            return 'luxury';
        }

        if (isset(self::COMMERCIAL_MAKE_SLUGS[$slug])) {
            return 'commercial';
        }

        return 'car';
    }

    private function normalizeBodyType(mixed $value): ?string
    {
        $value = strtolower(trim((string) $value));
        if ($value === '') {
            return null;
        }

        $map = [
            'hatchback'  => 'hatchback',
            'sedan'      => 'sedan',
            'suv'        => 'suv',
            'muv'        => 'muv',
            'coupe'      => 'coupe',
            'convertible'=> 'convertible',
            'van'        => 'van',
            'pickup'     => 'pickup',
            'crossover'  => 'crossover',
        ];

        return $map[$value] ?? $value;
    }

    private function normalizeFuelType(mixed $value): ?string
    {
        $value = strtolower(trim((string) $value));
        if ($value === '') {
            return null;
        }

        if (str_contains($value, 'electric')) {
            return 'electric';
        }
        if (str_contains($value, 'hybrid') || str_contains($value, 'mild hybrid')) {
            return 'hybrid';
        }
        if (str_contains($value, 'diesel')) {
            return 'diesel';
        }
        if (str_contains($value, 'cng')) {
            return 'cng';
        }
        if (str_contains($value, 'lpg')) {
            return 'lpg';
        }
        if (str_contains($value, 'petrol')) {
            return 'petrol';
        }

        return null;
    }

    private function normalizeTransmission(mixed $value): ?string
    {
        $value = strtolower(trim((string) $value));
        if ($value === '') {
            return null;
        }

        if (str_contains($value, 'manual') || str_contains($value, 'imt')) {
            return 'manual';
        }
        if (str_contains($value, 'amt')) {
            return 'amt';
        }
        if (str_contains($value, 'cvt')) {
            return 'cvt';
        }
        if (str_contains($value, 'automatic') || str_contains($value, 'dct') || str_contains($value, 'tc')) {
            return 'automatic';
        }

        return null;
    }

    private function mapToStandardColorSlug(string $name): string
    {
        $n = strtolower($name);

        if (str_contains($n, 'pearl') && str_contains($n, 'white')) {
            return 'pearl-white';
        }
        if (str_contains($n, 'champagne')) {
            return 'champagne';
        }
        if (str_contains($n, 'white') || str_contains($n, 'ivory')) {
            return 'white';
        }
        if (str_contains($n, 'black') || str_contains($n, 'onyx') || str_contains($n, 'jet')) {
            return 'black';
        }
        if (str_contains($n, 'silver') || str_contains($n, 'platinum')) {
            return 'silver';
        }
        if (str_contains($n, 'grey') || str_contains($n, 'gray') || str_contains($n, 'graphite') || str_contains($n, 'steel')) {
            return 'grey';
        }
        if (str_contains($n, 'red') || str_contains($n, 'crimson') || str_contains($n, 'maroon')) {
            return str_contains($n, 'maroon') ? 'maroon' : 'red';
        }
        if (str_contains($n, 'blue') || str_contains($n, 'navy') || str_contains($n, 'indigo')) {
            return str_contains($n, 'navy') ? 'navy-blue' : 'blue';
        }
        if (str_contains($n, 'green') || str_contains($n, 'olive') || str_contains($n, 'teal')) {
            return str_contains($n, 'teal') ? 'teal' : 'green';
        }
        if (str_contains($n, 'brown') || str_contains($n, 'bronze') || str_contains($n, 'copper') || str_contains($n, 'bronze')) {
            return str_contains($n, 'bronze') ? 'bronze' : 'brown';
        }
        if (str_contains($n, 'beige') || str_contains($n, 'sand') || str_contains($n, 'tan')) {
            return 'beige';
        }
        if (str_contains($n, 'gold')) {
            return 'gold';
        }
        if (str_contains($n, 'orange')) {
            return 'orange';
        }
        if (str_contains($n, 'yellow')) {
            return 'yellow';
        }
        if (str_contains($n, 'purple') || str_contains($n, 'violet')) {
            return 'purple';
        }

        return 'other';
    }

    private function slug(string $value): string
    {
        return Str::slug(trim($value));
    }
}
