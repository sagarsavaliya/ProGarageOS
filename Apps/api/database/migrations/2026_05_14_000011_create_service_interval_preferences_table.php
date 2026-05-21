<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_interval_preferences', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('vehicle_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedInteger('preferred_interval_km')->nullable();
            $table->unsignedInteger('preferred_interval_months')->nullable();
            $table->enum('reminder_channel', ['push', 'whatsapp', 'sms', 'email', 'none'])->default('push');
            $table->unsignedInteger('advance_notice_days')->default(7);
            $table->unsignedInteger('advance_notice_km')->default(500);
            $table->boolean('is_active')->default(true);
            $table->datetime('last_acknowledged_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_interval_preferences');
    }
};
