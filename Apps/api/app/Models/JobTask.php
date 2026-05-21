<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class JobTask extends Model
{
    use SoftDeletes;

    protected $table = 'job_tasks';

    protected $fillable = [
        'job_id', 'service_item_id', 'required_skill_id', 'name', 'description',
        'source', 'status', 'assigned_technician_id', 'estimated_price',
        'final_price', 'labor_minutes', 'requires_customer_approval',
        'liability_flag', 'is_billable',
    ];

    protected $casts = [
        'estimated_price'             => 'decimal:2',
        'final_price'                 => 'decimal:2',
        'requires_customer_approval'  => 'boolean',
        'liability_flag'              => 'boolean',
        'is_billable'                 => 'boolean',
    ];

    public function job(): BelongsTo
    {
        return $this->belongsTo(ServiceJob::class, 'job_id');
    }

    public function serviceItem(): BelongsTo
    {
        return $this->belongsTo(ServiceItem::class);
    }

    public function assignedTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_technician_id');
    }
}
