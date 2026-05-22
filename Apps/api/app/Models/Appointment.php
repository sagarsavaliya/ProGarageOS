<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Appointment extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'tenant_id', 'customer_id', 'vehicle_id', 'service_category_id',
        'appointment_number', 'scheduled_date', 'start_time', 'end_time', 'status',
        'source', 'assigned_technician_id', 'assigned_bay_id', 'converted_job_id',
        'reminder_sent_at', 'customer_acknowledged', 'notes', 'created_by',
    ];

    protected $casts = [
        'scheduled_date'        => 'date',
        'reminder_sent_at'      => 'datetime',
        'customer_acknowledged' => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function (Appointment $model) {
            $model->uuid ??= (string) Str::uuid();
            if (empty($model->appointment_number)) {
                $count = static::withTrashed()->where('tenant_id', $model->tenant_id)->count() + 1;
                $model->appointment_number = 'APT-' . str_pad((string) $count, 5, '0', STR_PAD_LEFT);
            }
        });
    }

    public function customer(): BelongsTo { return $this->belongsTo(Customer::class); }
    public function vehicle(): BelongsTo { return $this->belongsTo(Vehicle::class); }
    public function serviceCategory(): BelongsTo { return $this->belongsTo(ServiceCategory::class); }
    public function assignedTechnician(): BelongsTo { return $this->belongsTo(User::class, 'assigned_technician_id'); }
    public function convertedJob(): BelongsTo { return $this->belongsTo(ServiceJob::class, 'converted_job_id'); }
    public function assignedBay(): BelongsTo { return $this->belongsTo(ServiceBay::class, 'assigned_bay_id'); }
}
