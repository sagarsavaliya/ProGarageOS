<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class TaxRate extends Model
{
    use SoftDeletes;

    protected $table = 'tax_rates';

    protected $fillable = [
        'uuid', 'tenant_id', 'name', 'code', 'tax_type', 'rate_percentage',
        'is_compound', 'component_breakdown', 'applicable_to', 'region_scope',
        'state_code', 'hsn_sac_codes', 'effective_from', 'effective_to',
        'is_active', 'is_default', 'sort_order',
    ];

    protected $casts = [
        'rate_percentage'      => 'decimal:2',
        'is_compound'          => 'boolean',
        'is_active'            => 'boolean',
        'is_default'           => 'boolean',
        'component_breakdown'  => 'array',
        'hsn_sac_codes'        => 'array',
        'effective_from'       => 'date',
        'effective_to'         => 'date',
    ];

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn ($m) => $m->uuid ??= (string) Str::uuid());
    }
}
