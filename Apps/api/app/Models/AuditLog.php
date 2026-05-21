<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    public $timestamps = false;

    protected $table = 'audit_logs';

    protected $fillable = [
        'tenant_id', 'user_id', 'impersonator_id', 'action_type', 'target_type',
        'target_id', 'old_values', 'new_values', 'ip_address', 'user_agent', 'notes',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'created_at' => 'datetime',
    ];

    public static function record(
        string $actionType,
        string $targetType,
        ?int $targetId = null,
        array $oldValues = [],
        array $newValues = []
    ): void {
        static::create([
            'tenant_id'   => auth()->user()?->tenant_id,
            'user_id'     => auth()->id(),
            'action_type' => $actionType,
            'target_type' => $targetType,
            'target_id'   => $targetId,
            'old_values'  => $oldValues ?: null,
            'new_values'  => $newValues ?: null,
            'ip_address'  => request()->ip(),
            'user_agent'  => request()->userAgent(),
        ]);
    }
}
