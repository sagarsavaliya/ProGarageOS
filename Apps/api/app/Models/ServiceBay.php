<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class ServiceBay extends Model
{
    use SoftDeletes;

    protected $table = 'service_bays';

    protected $fillable = [
        'uuid', 'tenant_id', 'name', 'code', 'bay_type',
        'capacity_concurrent', 'equipment_features', 'status', 'is_active', 'sort_order',
    ];

    protected $casts = [
        'equipment_features' => 'array',
        'is_active'          => 'boolean',
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

    public function currentJobs(): HasMany
    {
        return $this->hasMany(ServiceJob::class, 'assigned_bay_id')
            ->whereNotIn('status', ['delivered', 'cancelled']);
    }
}
