<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('job_id')->constrained('service_jobs')->cascadeOnDelete();
            $table->unsignedBigInteger('service_item_id')->nullable();
            $table->unsignedBigInteger('required_skill_id')->nullable();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('source', ['planned', 'discovered', 'accidental_damage', 'upsell', 'customer_request'])->default('planned');
            $table->enum('status', ['pending_approval', 'approved', 'in_progress', 'completed', 'cancelled', 'waived'])->default('approved');
            $table->unsignedBigInteger('assigned_technician_id')->nullable();
            $table->decimal('estimated_price', 10, 2)->default(0);
            $table->decimal('final_price', 10, 2)->default(0);
            $table->unsignedInteger('labor_minutes')->default(0);
            $table->boolean('requires_customer_approval')->default(false);
            $table->boolean('liability_flag')->default(false);
            $table->boolean('is_billable')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['job_id', 'status']);
            $table->foreign('service_item_id')->references('id')->on('service_items')->nullOnDelete();
            $table->foreign('required_skill_id')->references('id')->on('skills')->nullOnDelete();
            $table->foreign('assigned_technician_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_tasks');
    }
};
