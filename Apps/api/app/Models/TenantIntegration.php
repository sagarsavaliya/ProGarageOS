<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantIntegration extends Model
{
    protected $fillable = [
        'tenant_id',
        'provider',
        'enabled',
        'credentials',
        'settings',
        'last_tested_at',
    ];

    protected $casts = [
        'enabled'        => 'boolean',
        'credentials'    => 'encrypted:array',
        'settings'       => 'array',
        'last_tested_at' => 'datetime',
    ];

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public static function whatsappForTenant(?int $tenantId): ?self
    {
        if (!$tenantId) {
            return null;
        }

        return static::where('tenant_id', $tenantId)
            ->where('provider', 'whatsapp')
            ->where('enabled', true)
            ->first();
    }
}
