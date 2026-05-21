<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Invoice extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'tenant_id', 'customer_id', 'vehicle_id', 'job_id',
        'invoice_number', 'type', 'status', 'issued_date', 'due_date', 'paid_at',
        'subtotal', 'tax_total', 'discount_total', 'grand_total',
        'amount_paid', 'balance_due', 'customer_pay_amount', 'insurance_claim_amount',
        'payment_method', 'payment_reference', 'gateway', 'gateway_transaction_id',
        'qr_code_url', 'pdf_url', 'customer_notes', 'internal_notes', 'terms_conditions',
    ];

    protected $casts = [
        'issued_date'  => 'datetime',
        'due_date'     => 'date',
        'paid_at'      => 'datetime',
        'subtotal'     => 'decimal:2',
        'tax_total'    => 'decimal:2',
        'discount_total' => 'decimal:2',
        'grand_total'  => 'decimal:2',
        'amount_paid'  => 'decimal:2',
        'balance_due'  => 'decimal:2',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function (Invoice $model) {
            $model->uuid ??= (string) Str::uuid();
            if (empty($model->invoice_number)) {
                $count = static::withTrashed()->where('tenant_id', $model->tenant_id)->count() + 1;
                $model->invoice_number = 'INV-' . now()->format('Ymd') . '-' . str_pad((string) $count, 4, '0', STR_PAD_LEFT);
            }
        });
    }

    public function job(): BelongsTo
    {
        return $this->belongsTo(ServiceJob::class, 'job_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(InvoiceItem::class)->orderBy('sort_order');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function recalculate(): void
    {
        $items = $this->items()->get();
        $this->subtotal       = $items->where('line_type', '!=', 'tax')->where('line_type', '!=', 'discount')->sum('total_amount');
        $this->tax_total      = $items->sum('tax_amount');
        $this->discount_total = $items->sum('discount_amount');
        $this->grand_total    = $this->subtotal + $this->tax_total - $this->discount_total;
        $paidAmount           = $this->payments()->where('status', 'success')->sum('amount');
        $this->amount_paid    = $paidAmount;
        $this->balance_due    = $this->grand_total - $paidAmount;
        $this->save();
    }
}
