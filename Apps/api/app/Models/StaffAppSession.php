<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StaffAppSession extends Model
{
    protected $fillable = [
        'user_id', 'tenant_id', 'device_token', 'platform',
        'app_version', 'last_active_at', 'is_active',
    ];

    protected $casts = [
        'last_active_at' => 'datetime',
        'is_active'      => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
