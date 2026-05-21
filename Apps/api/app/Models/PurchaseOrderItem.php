<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseOrderItem extends Model
{
    protected $table = 'purchase_order_items';

    protected $fillable = [
        'purchase_order_id', 'inventory_item_id', 'quantity_ordered',
        'quantity_received', 'unit_cost', 'tax_rate_id', 'line_total', 'batch_serial_numbers',
    ];

    protected $casts = [
        'quantity_ordered'      => 'decimal:3',
        'quantity_received'     => 'decimal:3',
        'unit_cost'             => 'decimal:2',
        'line_total'            => 'decimal:2',
        'batch_serial_numbers'  => 'array',
    ];

    public function inventoryItem(): BelongsTo { return $this->belongsTo(InventoryItem::class); }
    public function taxRate(): BelongsTo { return $this->belongsTo(TaxRate::class, 'tax_rate_id'); }
}
