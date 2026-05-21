<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Tenant extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'business_name', 'business_type', 'status', 'currency',
        'timezone', 'country_code', 'phone', 'email', 'address',
        'city', 'state', 'pincode', 'gst_number', 'logo_url',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($model) => $model->uuid ??= (string) Str::uuid());
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(GarageCustomer::class);
    }

    public function serviceJobs(): HasMany
    {
        return $this->hasMany(ServiceJob::class);
    }

    public function serviceBays(): HasMany
    {
        return $this->hasMany(ServiceBay::class);
    }

    public function serviceCategories(): HasMany
    {
        return $this->hasMany(ServiceCategory::class);
    }

    public function activeSubscription(): HasOne
    {
        return $this->hasOne(TenantSubscription::class)->whereIn('status', ['trialing', 'active']);
    }

    public function loyaltyProgram(): HasOne
    {
        return $this->hasOne(LoyaltyProgram::class);
    }
}
