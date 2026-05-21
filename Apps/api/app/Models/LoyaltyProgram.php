<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LoyaltyProgram extends Model
{
    use SoftDeletes;

    protected $table = 'loyalty_programs';

    protected $fillable = [
        'tenant_id', 'name', 'earning_mode', 'points_per_amount',
        'min_spend_threshold', 'redemption_rate', 'min_points_to_redeem',
        'max_discount_percent', 'points_expiry_days', 'stack_with_other_discounts', 'is_active',
    ];

    protected $casts = [
        'points_per_amount'           => 'decimal:2',
        'min_spend_threshold'         => 'decimal:2',
        'redemption_rate'             => 'decimal:4',
        'stack_with_other_discounts'  => 'boolean',
        'is_active'                   => 'boolean',
    ];

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(LoyaltyTransaction::class, 'tenant_id', 'tenant_id');
    }
}
