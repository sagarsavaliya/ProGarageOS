<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tax_rates', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->string('name');
            $table->string('code', 50);
            $table->enum('tax_type', ['gst', 'vat', 'service_tax', 'luxury_tax', 'cess', 'nil'])->default('gst');
            $table->decimal('rate_percentage', 5, 2);
            $table->boolean('is_compound')->default(false);
            $table->json('component_breakdown')->nullable();
            $table->enum('applicable_to', ['services', 'parts', 'both'])->default('both');
            $table->enum('region_scope', ['all_india', 'state_specific', 'union_territory'])->default('all_india');
            $table->char('state_code', 2)->nullable();
            $table->json('hsn_sac_codes')->nullable();
            $table->date('effective_from');
            $table->date('effective_to')->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tax_rates');
    }
};
