<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class InspectionTemplate extends Model
{
    use SoftDeletes;

    protected $table = 'inspection_templates';

    protected $fillable = [
        'uuid', 'tenant_id', 'name', 'code', 'component_name', 'component_category',
        'expected_condition', 'is_mandatory', 'requires_photo', 'sort_order', 'is_active',
    ];

    protected $casts = [
        'is_mandatory'   => 'boolean',
        'requires_photo' => 'boolean',
        'is_active'      => 'boolean',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }

    public function tenant(): BelongsTo { return $this->belongsTo(Tenant::class); }
}
