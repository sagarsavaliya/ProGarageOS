<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class ServiceItem extends Model
{
    use SoftDeletes;

    protected $table = 'service_items';

    protected $fillable = [
        'uuid', 'tenant_id', 'category_id', 'name', 'code',
        'default_price', 'default_labor_minutes', 'requires_parts',
        'is_package', 'tax_applicable', 'is_active', 'sort_order',
    ];

    protected $casts = [
        'default_price'   => 'decimal:2',
        'requires_parts'  => 'boolean',
        'is_package'      => 'boolean',
        'tax_applicable'  => 'boolean',
        'is_active'       => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'category_id');
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
