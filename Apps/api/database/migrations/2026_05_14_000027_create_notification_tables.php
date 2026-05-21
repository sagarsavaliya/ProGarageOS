<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_templates', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->string('event_code', 100)->index();
            $table->string('name');
            $table->enum('channel', ['push', 'whatsapp', 'sms', 'email'])->default('push');
            $table->string('subject', 255)->nullable();
            $table->text('template_body');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->index(['tenant_id', 'event_code', 'is_active']);
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('customer_id')->nullable();
            $table->unsignedBigInteger('template_id')->nullable();
            $table->enum('channel', ['push', 'whatsapp', 'sms', 'email'])->default('push');
            $table->string('recipient', 255);
            $table->text('content_snapshot');
            $table->enum('status', ['pending', 'sent', 'delivered', 'failed', 'read'])->default('pending');
            $table->string('external_id', 150)->nullable();
            $table->string('reference_type', 50)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->datetime('sent_at')->nullable();
            $table->datetime('read_at')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'customer_id', 'status']);
            $table->foreign('customer_id')->references('id')->on('customers')->nullOnDelete();
            $table->foreign('template_id')->references('id')->on('notification_templates')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('notification_templates');
    }
};
