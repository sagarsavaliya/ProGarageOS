<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_templates', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('code', 50);
            $table->string('component_name');
            $table->string('component_category', 100);
            $table->string('expected_condition', 100)->nullable();
            $table->boolean('is_mandatory')->default(false);
            $table->boolean('requires_photo')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'is_active', 'sort_order']);
        });

        Schema::create('job_inspection_records', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('job_id')->constrained('service_jobs')->cascadeOnDelete();
            $table->foreignId('template_id')->constrained('inspection_templates');
            $table->enum('inspection_phase', ['intake', 'delivery'])->default('intake');
            $table->string('component_name');
            $table->string('category', 100)->nullable();
            $table->enum('condition_status', ['good', 'fair', 'poor', 'damaged', 'missing', 'na'])->default('good');
            $table->enum('severity', ['none', 'minor', 'moderate', 'severe'])->default('none');
            $table->text('notes')->nullable();
            $table->json('media_urls')->nullable();
            $table->string('signature_url', 500)->nullable();
            $table->unsignedBigInteger('inspected_by')->nullable();
            $table->boolean('customer_acknowledged')->default(false);
            $table->datetime('acknowledged_at')->nullable();
            $table->timestamps();

            $table->index(['job_id', 'inspection_phase']);
            $table->foreign('inspected_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_inspection_records');
        Schema::dropIfExists('inspection_templates');
    }
};
