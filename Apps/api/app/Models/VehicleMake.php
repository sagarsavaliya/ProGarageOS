<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class VehicleMake extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'name', 'slug', 'vehicle_category', 'country_code', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn (self $m) => $m->uuid ??= (string) Str::uuid());
    }

    public function models(): HasMany
    {
        return $this->hasMany(VehicleModel::class)->orderBy('sort_order')->orderBy('name');
    }
}
