<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InvoiceItem extends Model
{
    use SoftDeletes;

    protected $table = 'invoice_items';

    protected $fillable = [
        'invoice_id', 'job_task_id', 'service_item_id', 'part_id',
        'line_type', 'name', 'description', 'quantity', 'unit_price',
        'tax_rate_id', 'tax_amount', 'discount_amount', 'total_amount',
        'is_taxable', 'sort_order', 'internal_notes',
    ];

    protected $casts = [
        'quantity'        => 'decimal:3',
        'unit_price'      => 'decimal:2',
        'tax_amount'      => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'total_amount'    => 'decimal:2',
        'is_taxable'      => 'boolean',
    ];

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    public function taxRate(): BelongsTo
    {
        return $this->belongsTo(TaxRate::class, 'tax_rate_id');
    }
}
