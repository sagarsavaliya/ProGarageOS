<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->foreignId('vehicle_id')->constrained();
            $table->unsignedBigInteger('service_category_id')->nullable();
            $table->string('appointment_number', 50);
            $table->date('scheduled_date');
            $table->time('start_time');
            $table->time('end_time');
            $table->enum('status', ['booked', 'confirmed', 'checked_in', 'completed', 'no_show', 'cancelled'])->default('booked');
            $table->enum('source', ['walk_in', 'phone', 'app', 'web', 'whatsapp'])->default('app');
            $table->unsignedBigInteger('assigned_technician_id')->nullable();
            $table->unsignedBigInteger('assigned_bay_id')->nullable();
            $table->unsignedBigInteger('converted_job_id')->nullable();
            $table->datetime('reminder_sent_at')->nullable();
            $table->boolean('customer_acknowledged')->default(false);
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'appointment_number']);
            $table->index(['tenant_id', 'scheduled_date', 'status']);
            $table->foreign('service_category_id')->references('id')->on('service_categories')->nullOnDelete();
            $table->foreign('assigned_technician_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('assigned_bay_id')->references('id')->on('service_bays')->nullOnDelete();
            $table->foreign('converted_job_id')->references('id')->on('service_jobs')->nullOnDelete();
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};
