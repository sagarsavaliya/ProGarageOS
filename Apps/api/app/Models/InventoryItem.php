<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class InventoryItem extends Model
{
    use SoftDeletes;

    protected $table = 'inventory_items';

    protected $fillable = [
        'uuid', 'tenant_id', 'sku', 'name', 'description', 'brand',
        'category_id', 'unit_of_measure', 'cost_price', 'selling_price',
        'tax_rate_id', 'stock_on_hand', 'low_stock_threshold', 'reorder_quantity',
        'preferred_vendor_id', 'requires_serial_warranty', 'is_active',
    ];

    protected $casts = [
        'cost_price'               => 'decimal:2',
        'selling_price'            => 'decimal:2',
        'requires_serial_warranty' => 'boolean',
        'is_active'                => 'boolean',
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

    public function category(): BelongsTo
    {
        return $this->belongsTo(PartsCategory::class, 'category_id');
    }

    public function taxRate(): BelongsTo
    {
        return $this->belongsTo(TaxRate::class, 'tax_rate_id');
    }

    public function preferredVendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class, 'preferred_vendor_id');
    }

    public function isLowStock(): bool
    {
        return $this->stock_on_hand <= $this->low_stock_threshold;
    }
}
