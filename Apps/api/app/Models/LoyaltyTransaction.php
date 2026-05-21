<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LoyaltyTransaction extends Model
{
    public $timestamps = false;

    protected $table = 'loyalty_transactions';

    protected $fillable = [
        'tenant_id', 'customer_id', 'type', 'points', 'balance_after',
        'reference_type', 'reference_id', 'expires_at', 'description',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
