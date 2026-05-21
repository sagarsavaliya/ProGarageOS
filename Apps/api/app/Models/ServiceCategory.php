<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class ServiceCategory extends Model
{
    use SoftDeletes;

    protected $table = 'service_categories';

    protected $fillable = [
        'uuid', 'tenant_id', 'name', 'code', 'default_duration_min',
        'requires_intake_inspection', 'requires_approval', 'is_billable',
        'is_active', 'sort_order',
    ];

    protected $casts = [
        'requires_intake_inspection' => 'boolean',
        'requires_approval'          => 'boolean',
        'is_billable'                => 'boolean',
        'is_active'                  => 'boolean',
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

    public function items(): HasMany
    {
        return $this->hasMany(ServiceItem::class, 'category_id');
    }
}
