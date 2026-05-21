<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Vendor extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'tenant_id', 'name', 'code', 'vendor_type', 'contact_name',
        'contact_phone', 'contact_email', 'address', 'city', 'state',
        'gst_number', 'payment_terms', 'credit_limit', 'current_balance',
        'rating', 'average_lead_time_days', 'is_preferred', 'is_active',
    ];

    protected $casts = [
        'credit_limit'   => 'decimal:2',
        'current_balance' => 'decimal:2',
        'rating'         => 'decimal:2',
        'is_preferred'   => 'boolean',
        'is_active'      => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function purchaseOrders(): HasMany { return $this->hasMany(PurchaseOrder::class); }
    public function inventoryItems(): HasMany { return $this->hasMany(InventoryItem::class, 'preferred_vendor_id'); }
}
