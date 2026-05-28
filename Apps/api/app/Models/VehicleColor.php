<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Str;

class VehicleColor extends Model
{
    protected $fillable = [
        'uuid', 'name', 'slug', 'hex_code', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn (self $m) => $m->uuid ??= (string) Str::uuid());
    }

    public function variants(): BelongsToMany
    {
        return $this->belongsToMany(VehicleVariant::class, 'vehicle_variant_colors')
            ->withPivot('is_default');
    }
}
