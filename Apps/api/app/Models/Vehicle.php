<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Vehicle extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'customer_id', 'registration_number', 'chassis_number',
        'engine_number', 'registration_date', 'registration_validity', 'fitness_validity',
        'owner_serial', 'ownership_transfer_date', 'fuel_type', 'emission_norms',
        'vehicle_class', 'body_type', 'transmission', 'maker', 'model', 'variant',
        'year', 'color', 'nickname', 'odometer_reading', 'gps_estimated_odometer',
        'gps_tracking_consent', 'odometer_review_status', 'gps_last_sync_at',
        'insurance_policy_number', 'insurance_company', 'insurance_expiry',
        'permit_number', 'permit_expiry', 'blacklisted_status', 'photo_url', 'is_active',
    ];

    protected $casts = [
        'registration_date'        => 'date',
        'registration_validity'    => 'date',
        'fitness_validity'         => 'date',
        'ownership_transfer_date'  => 'date',
        'insurance_expiry'         => 'date',
        'permit_expiry'            => 'date',
        'gps_tracking_consent'     => 'boolean',
        'is_active'                => 'boolean',
        'gps_last_sync_at'         => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function serviceJobs(): HasMany
    {
        return $this->hasMany(ServiceJob::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(VehicleDocument::class);
    }

    public function mileageLogs(): HasMany
    {
        return $this->hasMany(VehicleMileageLog::class)->orderByDesc('recorded_at');
    }

    public function getDisplayNameAttribute(): string
    {
        $parts = array_filter([$this->year, $this->maker, $this->model]);
        return implode(' ', $parts) ?: $this->registration_number;
    }
}
