<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class PurchaseOrder extends Model
{
    use SoftDeletes;

    protected $table = 'purchase_orders';

    protected $fillable = [
        'uuid', 'tenant_id', 'vendor_id', 'po_number', 'status',
        'order_date', 'expected_delivery_date', 'actual_delivery_date',
        'subtotal', 'tax_total', 'grand_total', 'payment_status', 'notes', 'created_by',
    ];

    protected $casts = [
        'order_date'             => 'date',
        'expected_delivery_date' => 'date',
        'actual_delivery_date'   => 'date',
        'subtotal'               => 'decimal:2',
        'tax_total'              => 'decimal:2',
        'grand_total'            => 'decimal:2',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function (PurchaseOrder $m) {
            $m->uuid ??= (string) Str::uuid();
            if (empty($m->po_number)) {
                $count = static::withTrashed()->where('tenant_id', $m->tenant_id)->count() + 1;
                $m->po_number = 'PO-' . str_pad((string) $count, 5, '0', STR_PAD_LEFT);
            }
        });
    }

    public function vendor(): BelongsTo { return $this->belongsTo(Vendor::class); }
    public function items(): HasMany { return $this->hasMany(PurchaseOrderItem::class); }
}
