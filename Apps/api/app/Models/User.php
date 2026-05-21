<?php

namespace App\Models;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, SoftDeletes;

    protected $fillable = [
        'uuid', 'tenant_id', 'email', 'phone', 'pin_hash',
        'pin_otp_code', 'pin_otp_expires_at', 'phone_verified_at', 'requires_pin_setup',
        'first_name', 'last_name', 'role', 'is_platform_admin',
        'is_support_agent', 'avatar_url', 'last_login_at', 'pin_last_changed_at',
    ];

    protected $hidden = ['pin_hash', 'pin_otp_code', 'remember_token'];

    protected $casts = [
        'is_platform_admin'   => 'boolean',
        'is_support_agent'    => 'boolean',
        'requires_pin_setup'  => 'boolean',
        'last_login_at'       => 'datetime',
        'pin_last_changed_at' => 'datetime',
        'pin_otp_expires_at'  => 'datetime',
        'phone_verified_at'   => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function assignedJobs(): HasMany
    {
        return $this->hasMany(ServiceJob::class, 'primary_technician_id');
    }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}");
    }

    public function getInitialsAttribute(): string
    {
        return strtoupper(substr($this->first_name, 0, 1) . substr($this->last_name ?? '', 0, 1));
    }

    public function verifyPin(string $pin): bool
    {
        if (!$this->pin_hash) {
            return false;
        }

        return \Hash::check($pin, $this->pin_hash);
    }

    public function generatePinOtp(): string
    {
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->update([
            'pin_otp_code'       => $otp,
            'pin_otp_expires_at' => now()->addMinutes(10),
        ]);

        return $otp;
    }

    public function verifyPinOtp(string $otp): bool
    {
        return $this->pin_otp_code === $otp && $this->pin_otp_expires_at?->isFuture();
    }

    public function setPin(string $pin): void
    {
        $this->update([
            'pin_hash'             => \Hash::make($pin),
            'pin_last_changed_at'  => now(),
            'phone_verified_at'    => now(),
            'requires_pin_setup'   => false,
            'pin_otp_code'         => null,
            'pin_otp_expires_at'   => null,
        ]);
    }
}
