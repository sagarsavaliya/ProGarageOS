<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class JobInspectionRecord extends Model
{
    protected $table = 'job_inspection_records';

    protected $fillable = [
        'uuid', 'job_id', 'template_id', 'inspection_phase', 'component_name',
        'category', 'condition_status', 'severity', 'notes', 'media_urls',
        'signature_url', 'inspected_by', 'customer_acknowledged', 'acknowledged_at',
    ];

    protected $casts = [
        'media_urls'            => 'array',
        'customer_acknowledged' => 'boolean',
        'acknowledged_at'       => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function job(): BelongsTo { return $this->belongsTo(ServiceJob::class, 'job_id'); }
    public function template(): BelongsTo { return $this->belongsTo(InspectionTemplate::class); }
    public function inspector(): BelongsTo { return $this->belongsTo(User::class, 'inspected_by'); }
}
