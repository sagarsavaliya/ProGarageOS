<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

class Customer extends Authenticatable
{
    use HasApiTokens, SoftDeletes;

    protected $fillable = [
        'uuid', 'phone_primary', 'phone_secondary', 'is_p_wa_enabled',
        'is_s_wa_enabled', 'email', 'first_name', 'last_name',
        'preferred_language', 'marketing_opt_in', 'otp_code', 'otp_expires_at',
    ];

    protected $hidden = ['otp_code', 'otp_expires_at'];

    protected $casts = [
        'is_p_wa_enabled'    => 'boolean',
        'is_s_wa_enabled'    => 'boolean',
        'marketing_opt_in'   => 'boolean',
        'otp_expires_at'     => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function garageProfiles(): HasMany
    {
        return $this->hasMany(GarageCustomer::class);
    }

    public function serviceJobs(): HasMany
    {
        return $this->hasMany(ServiceJob::class);
    }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name} " . ($this->last_name ?? ''));
    }

    public function generateOtp(): string
    {
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->update([
            'otp_code'       => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);
        return $otp;
    }

    public function verifyOtp(string $otp): bool
    {
        return $this->otp_code === $otp && $this->otp_expires_at?->isFuture();
    }
}
