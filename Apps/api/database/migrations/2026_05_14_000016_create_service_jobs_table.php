<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_jobs', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique()->index();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->foreignId('vehicle_id')->constrained();
            $table->string('job_number', 50);
            $table->enum('status', [
                'draft', 'checked_in', 'inspecting', 'estimate_pending',
                'estimate_approved', 'in_progress', 'quality_check',
                'ready_for_delivery', 'delivered', 'cancelled', 'on_hold'
            ])->default('draft');
            $table->enum('priority', ['low', 'normal', 'urgent', 'critical'])->default('normal');
            $table->unsignedInteger('odometer_at_intake')->nullable();
            $table->enum('fuel_level', ['empty', 'quarter', 'half', 'three_quarter', 'full'])->nullable();
            $table->decimal('estimated_amount', 12, 2)->nullable();
            $table->enum('approval_status', ['pending', 'approved', 'partially_approved', 'rejected'])->default('pending');
            $table->datetime('customer_approved_at')->nullable();
            $table->unsignedBigInteger('primary_technician_id')->nullable();
            $table->unsignedBigInteger('assigned_bay_id')->nullable();
            $table->datetime('scheduled_start_at')->nullable();
            $table->datetime('actual_start_at')->nullable();
            $table->datetime('estimated_completion_at')->nullable();
            $table->datetime('actual_completion_at')->nullable();
            $table->enum('delivery_method', ['pickup', 'drop', 'doorstep'])->default('pickup');
            $table->json('delivery_address')->nullable();
            $table->text('handover_notes')->nullable();
            $table->text('customer_complaint')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'job_number']);
            $table->index(['tenant_id', 'status', 'priority']);
            $table->index(['tenant_id', 'actual_start_at']);
            $table->foreign('primary_technician_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('assigned_bay_id')->references('id')->on('service_bays')->nullOnDelete();
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_jobs');
    }
};
