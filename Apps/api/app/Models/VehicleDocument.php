<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class VehicleDocument extends Model
{
    use SoftDeletes;

    protected $table = 'vehicle_documents';

    protected $fillable = [
        'uuid', 'vehicle_id', 'tenant_id', 'document_type', 'document_number',
        'issuing_authority', 'issue_date', 'expiry_date', 'file_url',
        'is_verified', 'is_active', 'ocr_extracted_data',
    ];

    protected $casts = [
        'issue_date'          => 'date',
        'expiry_date'         => 'date',
        'is_verified'         => 'boolean',
        'is_active'           => 'boolean',
        'ocr_extracted_data'  => 'array',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function isExpired(): bool
    {
        return $this->expiry_date?->isPast() ?? false;
    }

    public function isExpiringSoon(int $days = 30): bool
    {
        return $this->expiry_date?->isBetween(now(), now()->addDays($days)) ?? false;
    }
}
