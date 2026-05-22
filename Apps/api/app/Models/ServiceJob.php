<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class ServiceJob extends Model
{
    use SoftDeletes;

    protected $table = 'service_jobs';

    protected $fillable = [
        'uuid', 'tenant_id', 'customer_id', 'vehicle_id', 'job_number',
        'status', 'priority', 'odometer_at_intake', 'fuel_level',
        'estimated_amount', 'approval_status', 'customer_approved_at',
        'primary_technician_id', 'assigned_bay_id',
        'scheduled_start_at', 'actual_start_at',
        'estimated_completion_at', 'actual_completion_at',
        'delivery_method', 'delivery_address', 'handover_notes',
        'customer_complaint', 'created_by',
        'is_insurance_job', 'insurance_company', 'claim_number',
        'insurance_claim_status', 'insurance_survey_at',
        'customer_liability_amount', 'job_insurance_claim_amount',
    ];

    protected $casts = [
        'delivery_address'      => 'array',
        'estimated_amount'      => 'decimal:2',
        'customer_approved_at'  => 'datetime',
        'scheduled_start_at'    => 'datetime',
        'actual_start_at'       => 'datetime',
        'estimated_completion_at' => 'datetime',
        'actual_completion_at'  => 'datetime',
        'is_insurance_job'      => 'boolean',
        'insurance_survey_at'   => 'datetime',
        'customer_liability_amount' => 'decimal:2',
        'job_insurance_claim_amount' => 'decimal:2',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function (ServiceJob $model) {
            $model->uuid ??= (string) Str::uuid();
            if (empty($model->job_number)) {
                $count = static::withTrashed()->where('tenant_id', $model->tenant_id)->count() + 1;
                $model->job_number = 'JOB-' . str_pad((string) $count, 5, '0', STR_PAD_LEFT);
            }
        });
    }

    // Tenant scoping
    protected static function booted(): void
    {
        static::addGlobalScope('tenant', function (Builder $builder) {
            if (auth()->check() && auth()->user() instanceof User) {
                $builder->where('tenant_id', auth()->user()->tenant_id);
            }
        });
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function primaryTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'primary_technician_id');
    }

    public function assignedBay(): BelongsTo
    {
        return $this->belongsTo(ServiceBay::class, 'assigned_bay_id');
    }

    public function tasks(): HasMany
    {
        return $this->hasMany(JobTask::class, 'job_id');
    }

    public function invoice(): HasOne
    {
        return $this->hasOne(Invoice::class, 'job_id');
    }

    public function inspectionRecords(): HasMany
    {
        return $this->hasMany(JobInspectionRecord::class, 'job_id');
    }

    public function serviceCategories(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(ServiceCategory::class, 'job_service_categories', 'job_id', 'category_id')
            ->withPivot('is_primary', 'sort_order')
            ->withTimestamps();
    }

    public function isActive(): bool
    {
        return !in_array($this->status, ['delivered', 'cancelled']);
    }
}
