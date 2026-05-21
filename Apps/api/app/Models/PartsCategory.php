<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PartsCategory extends Model
{
    use SoftDeletes;

    protected $table = 'parts_categories';

    protected $fillable = ['tenant_id', 'name', 'code', 'parent_id', 'is_active', 'sort_order'];

    protected $casts = ['is_active' => 'boolean'];

    public function parent(): BelongsTo { return $this->belongsTo(self::class, 'parent_id'); }
    public function children(): HasMany { return $this->hasMany(self::class, 'parent_id'); }
    public function items(): HasMany { return $this->hasMany(InventoryItem::class, 'category_id'); }
}
