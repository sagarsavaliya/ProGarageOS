<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Payment extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'tenant_id', 'invoice_id', 'payment_method_id',
        'amount', 'currency', 'status', 'payment_type',
        'reference_number', 'gateway_transaction_id', 'gateway_response',
        'paid_at', 'failed_reason', 'refunded_amount', 'refunded_at',
        'reconciled_at', 'notes',
    ];

    protected $casts = [
        'amount'           => 'decimal:2',
        'refunded_amount'  => 'decimal:2',
        'gateway_response' => 'array',
        'paid_at'          => 'datetime',
        'refunded_at'      => 'datetime',
        'reconciled_at'    => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
        static::saved(function (Payment $payment) {
            $payment->invoice->recalculate();
        });
    }

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }
}
