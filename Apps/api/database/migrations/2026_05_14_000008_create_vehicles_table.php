<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique()->index();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('registration_number', 50)->index();
            $table->string('chassis_number', 100)->nullable()->unique();
            $table->string('engine_number', 100)->nullable()->index();
            $table->date('registration_date')->nullable();
            $table->date('registration_validity')->nullable();
            $table->date('fitness_validity')->nullable();
            $table->unsignedTinyInteger('owner_serial')->default(1);
            $table->date('ownership_transfer_date')->nullable();
            $table->enum('fuel_type', ['petrol', 'diesel', 'electric', 'cng', 'lpg', 'hybrid'])->nullable();
            $table->string('emission_norms', 20)->nullable();
            $table->string('vehicle_class', 50)->nullable();
            $table->string('body_type', 50)->nullable();
            $table->enum('transmission', ['manual', 'automatic', 'cvt', 'amt'])->nullable();
            $table->string('maker', 100)->nullable();
            $table->string('model', 100)->nullable();
            $table->string('variant', 100)->nullable();
            $table->year('year')->nullable();
            $table->string('color', 50)->nullable();
            $table->string('nickname', 100)->nullable();
            $table->unsignedInteger('odometer_reading')->default(0);
            $table->unsignedInteger('gps_estimated_odometer')->default(0);
            $table->boolean('gps_tracking_consent')->default(false);
            $table->enum('odometer_review_status', ['none', 'pending_approval', 'approved', 'manually_corrected', 'auto_accepted'])->default('none');
            $table->datetime('gps_last_sync_at')->nullable();
            $table->string('insurance_policy_number', 100)->nullable();
            $table->string('insurance_company', 100)->nullable();
            $table->date('insurance_expiry')->nullable();
            $table->string('permit_number', 100)->nullable();
            $table->date('permit_expiry')->nullable();
            $table->enum('blacklisted_status', ['clean', 'flagged', 'blacklisted'])->default('clean');
            $table->string('photo_url', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['customer_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
