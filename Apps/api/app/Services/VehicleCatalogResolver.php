<?php

namespace App\Services;

use App\Models\VehicleColor;
use App\Models\VehicleMake;
use App\Models\VehicleModel;
use App\Models\VehicleVariant;

class VehicleCatalogResolver
{
    /**
     * Resolve optional catalog UUIDs into FK ids and display text fields.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public function apply(array $data): array
    {
        if ($uuid = $data['vehicle_make_uuid'] ?? null) {
            $make = VehicleMake::where('uuid', $uuid)->where('is_active', true)->firstOrFail();
            $data['vehicle_make_id'] = $make->id;
            $data['maker'] = $data['maker'] ?? $make->name;
            unset($data['vehicle_make_uuid']);
        }

        if ($uuid = $data['vehicle_model_uuid'] ?? null) {
            $model = VehicleModel::where('uuid', $uuid)->where('is_active', true)->firstOrFail();
            $data['vehicle_model_id'] = $model->id;
            $data['model'] = $data['model'] ?? $model->name;
            unset($data['vehicle_model_uuid']);
        }

        if ($uuid = $data['vehicle_variant_uuid'] ?? null) {
            $variant = VehicleVariant::where('uuid', $uuid)->where('is_active', true)->firstOrFail();
            $data['vehicle_variant_id'] = $variant->id;
            $data['variant'] = $data['variant'] ?? $variant->name;
            if (! isset($data['fuel_type']) && $variant->fuel_type) {
                $data['fuel_type'] = $variant->fuel_type;
            }
            if (! isset($data['transmission']) && $variant->transmission) {
                $data['transmission'] = $variant->transmission;
            }
            unset($data['vehicle_variant_uuid']);
        }

        if ($uuid = $data['vehicle_color_uuid'] ?? null) {
            $color = VehicleColor::where('uuid', $uuid)->where('is_active', true)->firstOrFail();
            $data['vehicle_color_id'] = $color->id;
            $data['color'] = $data['color'] ?? $color->name;
            unset($data['vehicle_color_uuid']);
        }

        return $data;
    }
}
