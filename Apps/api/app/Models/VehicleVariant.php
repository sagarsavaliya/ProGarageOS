<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class VehicleVariant extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'vehicle_model_id', 'name', 'slug', 'fuel_type', 'transmission',
        'year_from', 'year_to', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn (self $m) => $m->uuid ??= (string) Str::uuid());
    }

    public function model(): BelongsTo
    {
        return $this->belongsTo(VehicleModel::class, 'vehicle_model_id');
    }

    public function colors(): BelongsToMany
    {
        return $this->belongsToMany(VehicleColor::class, 'vehicle_variant_colors')
            ->withPivot('is_default');
    }

    public function scopeForYear($query, int $year)
    {
        return $query
            ->where(function ($q) use ($year) {
                $q->whereNull('year_from')->orWhere('year_from', '<=', $year);
            })
            ->where(function ($q) use ($year) {
                $q->whereNull('year_to')->orWhere('year_to', '>=', $year);
            });
    }
}
