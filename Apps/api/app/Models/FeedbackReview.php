<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class FeedbackReview extends Model
{
    use SoftDeletes;

    protected $table = 'feedback_reviews';

    protected $fillable = [
        'uuid', 'tenant_id', 'customer_id', 'job_id', 'technician_id',
        'rating_overall', 'rating_breakdown', 'comments', 'channel', 'status',
        'response_text', 'responded_by', 'response_at', 'sent_at', 'submitted_at', 'is_anonymous',
    ];

    protected $casts = [
        'rating_breakdown' => 'array',
        'is_anonymous'     => 'boolean',
        'response_at'      => 'datetime',
        'sent_at'          => 'datetime',
        'submitted_at'     => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function job(): BelongsTo { return $this->belongsTo(ServiceJob::class, 'job_id'); }
    public function customer(): BelongsTo { return $this->belongsTo(Customer::class); }
    public function technician(): BelongsTo { return $this->belongsTo(User::class, 'technician_id'); }
}
