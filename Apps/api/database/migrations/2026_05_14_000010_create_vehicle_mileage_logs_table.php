<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_mileage_logs', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('vehicle_id')->constrained()->cascadeOnDelete();
            $table->datetime('recorded_at')->index();
            $table->unsignedInteger('odometer_value_km');
            $table->unsignedInteger('previous_value_km')->default(0);
            $table->enum('source', ['gps_background', 'customer_approved', 'customer_manual_correct', 'job_intake', 'admin_override']);
            $table->enum('review_status', ['pending', 'confirmed', 'auto_accepted'])->default('confirmed');
            $table->unsignedInteger('gps_delta_km')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['vehicle_id', 'review_status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_mileage_logs');
    }
};
