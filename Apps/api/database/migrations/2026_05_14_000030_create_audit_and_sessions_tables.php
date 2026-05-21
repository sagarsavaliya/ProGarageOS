<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->unsignedBigInteger('impersonator_id')->nullable();
            $table->string('action_type', 50)->index();
            $table->string('target_type', 50)->index();
            $table->unsignedBigInteger('target_id')->nullable()->index();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent()->index();
        });

        Schema::create('customer_app_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('device_token');
            $table->enum('platform', ['ios', 'android', 'web'])->default('android');
            $table->string('app_version', 20)->nullable();
            $table->datetime('last_active_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['customer_id', 'is_active']);
        });

        Schema::create('customer_engagement_events', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->enum('event_type', [
                'app_opened', 'viewed_job_progress', 'confirmed_odometer',
                'booked_service', 'dismissed_reminder', 'updated_preferences'
            ])->index();
            $table->string('reference_type', 50)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('created_at')->useCurrent()->index();

            $table->index(['customer_id', 'event_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_engagement_events');
        Schema::dropIfExists('customer_app_sessions');
        Schema::dropIfExists('audit_logs');
    }
};
