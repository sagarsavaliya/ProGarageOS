<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantSubscription extends Model
{
    use SoftDeletes;

    protected $table = 'tenant_subscriptions';

    protected $fillable = [
        'tenant_id', 'plan_id', 'status', 'current_period_start', 'current_period_end',
        'cancel_at_period_end', 'canceled_at', 'gateway', 'gateway_subscription_id',
        'gateway_customer_id', 'price_at_signup', 'currency_at_signup',
    ];

    protected $casts = [
        'current_period_start' => 'datetime',
        'current_period_end'   => 'datetime',
        'canceled_at'          => 'datetime',
        'cancel_at_period_end' => 'boolean',
        'price_at_signup'      => 'decimal:2',
    ];

    public function tenant(): BelongsTo { return $this->belongsTo(Tenant::class); }
    public function plan(): BelongsTo { return $this->belongsTo(SubscriptionPlan::class, 'plan_id'); }
}
