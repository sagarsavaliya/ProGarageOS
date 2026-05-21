<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class VehicleMileageLog extends Model
{
    public $timestamps = false;

    protected $table = 'vehicle_mileage_logs';

    protected $fillable = [
        'uuid', 'vehicle_id', 'recorded_at', 'odometer_value_km',
        'previous_value_km', 'source', 'review_status', 'gps_delta_km',
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
        'created_at'  => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }
}
