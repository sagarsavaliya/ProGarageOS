<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PaymentMethod extends Model
{
    use SoftDeletes;

    protected $table = 'payment_methods';

    protected $fillable = [
        'tenant_id', 'name', 'code', 'type', 'gateway_provider',
        'requires_reference', 'processing_fee_type', 'processing_fee_value',
        'is_active', 'sort_order',
    ];

    protected $casts = [
        'requires_reference'     => 'boolean',
        'processing_fee_value'   => 'decimal:2',
        'is_active'              => 'boolean',
    ];
}
