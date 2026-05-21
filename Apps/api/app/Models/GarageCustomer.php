<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GarageCustomer extends Model
{
    use SoftDeletes;

    protected $table = 'garage_customers';

    protected $fillable = [
        'customer_id', 'tenant_id', 'internal_notes', 'loyalty_points',
        'preferred_technician_id', 'last_visited_at', 'total_spent', 'visit_count',
    ];

    protected $casts = [
        'total_spent'     => 'decimal:2',
        'last_visited_at' => 'datetime',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function preferredTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'preferred_technician_id');
    }
}
