<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleColor;
use App\Models\VehicleMake;
use App\Models\VehicleModel;
use App\Models\VehicleVariant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleCatalogController extends Controller
{
    /**
     * GET /vehicle-catalog/makes
     */
    public function makes(Request $request): JsonResponse
    {
        $query = trim((string) $request->query('q', ''));
        $year  = $this->parseYear($request->query('year'));
        $limit = min(50, max(1, (int) $request->query('limit', 15)));

        $makes = VehicleMake::query()
            ->where('vehicle_category', 'car')
            ->where('is_active', true)
            ->when($query !== '', fn ($q) => $q->where('name', 'like', "{$query}%"))
            ->when($year !== null, fn ($q) => $q->whereHas(
                'models.variants',
                fn ($variantQuery) => $variantQuery
                    ->where('is_active', true)
                    ->forYear($year)
            ))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->limit($limit)
            ->get(['uuid', 'name', 'slug']);

        return response()->json(['success' => true, 'data' => $makes]);
    }

    /**
     * GET /vehicle-catalog/models
     */
    public function models(Request $request): JsonResponse
    {
        $makeUuid = trim((string) $request->query('make_uuid', ''));
        $query    = trim((string) $request->query('q', ''));
        $year     = $this->parseYear($request->query('year'));
        $limit    = min(50, max(1, (int) $request->query('limit', 15)));

        if ($makeUuid === '') {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'MAKE_REQUIRED', 'message' => 'Select a make first.'],
            ], 422);
        }

        $make = VehicleMake::where('uuid', $makeUuid)
            ->where('vehicle_category', 'car')
            ->where('is_active', true)
            ->firstOrFail();

        $models = VehicleModel::query()
            ->where('vehicle_make_id', $make->id)
            ->where('is_active', true)
            ->when($query !== '', fn ($q) => $q->where('name', 'like', "{$query}%"))
            ->when($year !== null, fn ($q) => $q->whereHas(
                'variants',
                fn ($variantQuery) => $variantQuery
                    ->where('is_active', true)
                    ->forYear($year)
            ))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->limit($limit)
            ->get(['uuid', 'name', 'slug', 'body_type']);

        return response()->json(['success' => true, 'data' => $models]);
    }

    /**
     * GET /vehicle-catalog/variants
     */
    public function variants(Request $request): JsonResponse
    {
        $modelUuid = trim((string) $request->query('model_uuid', ''));
        $query     = trim((string) $request->query('q', ''));
        $year      = $this->parseYear($request->query('year'));
        $limit     = min(50, max(1, (int) $request->query('limit', 15)));

        if ($modelUuid === '') {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'MODEL_REQUIRED', 'message' => 'Select a model first.'],
            ], 422);
        }

        $model = VehicleModel::where('uuid', $modelUuid)
            ->where('is_active', true)
            ->whereHas('make', fn ($q) => $q->where('vehicle_category', 'car')->where('is_active', true))
            ->firstOrFail();

        $variants = VehicleVariant::query()
            ->where('vehicle_model_id', $model->id)
            ->where('is_active', true)
            ->when($year !== null, fn ($q) => $q->forYear($year))
            ->when($query !== '', fn ($q) => $q->where('name', 'like', "%{$query}%"))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->limit($limit)
            ->get(['uuid', 'name', 'slug', 'fuel_type', 'transmission', 'year_from', 'year_to']);

        return response()->json(['success' => true, 'data' => $variants]);
    }

    /**
     * GET /vehicle-catalog/colors
     */
    public function colors(Request $request): JsonResponse
    {
        $variantUuid = trim((string) $request->query('variant_uuid', ''));
        $query       = trim((string) $request->query('q', ''));
        $limit       = min(50, max(1, (int) $request->query('limit', 15)));

        if ($variantUuid !== '') {
            $variant = VehicleVariant::where('uuid', $variantUuid)
                ->where('is_active', true)
                ->firstOrFail();

            $colors = $variant->colors()
                ->where('vehicle_colors.is_active', true)
                ->when($query !== '', fn ($q) => $q->where('vehicle_colors.name', 'like', "{$query}%"))
                ->orderBy('vehicle_colors.sort_order')
                ->orderBy('vehicle_colors.name')
                ->limit($limit)
                ->get(['vehicle_colors.uuid', 'vehicle_colors.name', 'vehicle_colors.slug', 'vehicle_colors.hex_code']);

            return response()->json(['success' => true, 'data' => $colors]);
        }

        $colors = VehicleColor::query()
            ->where('is_active', true)
            ->when($query !== '', fn ($q) => $q->where('name', 'like', "{$query}%"))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->limit($limit)
            ->get(['uuid', 'name', 'slug', 'hex_code']);

        return response()->json(['success' => true, 'data' => $colors]);
    }

    private function parseYear(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        $year = (int) $value;
        if ($year < 1900 || $year > ((int) date('Y')) + 1) {
            return null;
        }

        return $year;
    }
}
