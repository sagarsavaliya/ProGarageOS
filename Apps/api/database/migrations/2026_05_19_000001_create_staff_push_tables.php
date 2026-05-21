<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('staff_app_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('device_token', 512);
            $table->enum('platform', ['ios', 'android', 'web'])->default('android');
            $table->string('app_version', 20)->nullable();
            $table->datetime('last_active_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'device_token']);
            $table->index(['tenant_id', 'is_active']);
        });

        Schema::create('staff_notifications', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('event_code', 80)->index();
            $table->string('title', 200);
            $table->text('body');
            $table->json('data')->nullable();
            $table->enum('status', ['pending', 'sent', 'delivered', 'failed', 'read'])->default('sent');
            $table->datetime('read_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'read_at', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('staff_notifications');
        Schema::dropIfExists('staff_app_sessions');
    }
};
