<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class SubscriptionPlan extends Model
{
    use SoftDeletes;

    protected $table = 'subscription_plans';

    protected $fillable = [
        'uuid', 'name', 'slug', 'price', 'billing_cycle', 'trial_days',
        'max_locations', 'max_users', 'max_jobs_per_month', 'features', 'status',
    ];

    protected $casts = [
        'price'    => 'decimal:2',
        'features' => 'array',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }
}
