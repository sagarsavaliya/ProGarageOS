<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_items', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('service_categories');
            $table->string('name');
            $table->string('code', 50);
            $table->decimal('default_price', 10, 2)->default(0);
            $table->unsignedInteger('default_labor_minutes')->default(30);
            $table->boolean('requires_parts')->default(false);
            $table->boolean('is_package')->default(false);
            $table->boolean('tax_applicable')->default(true);
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
            $table->index(['tenant_id', 'category_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_items');
    }
};
