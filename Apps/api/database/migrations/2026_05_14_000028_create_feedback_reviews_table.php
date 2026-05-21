<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('feedback_reviews', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->foreignId('job_id')->constrained('service_jobs');
            $table->unsignedBigInteger('technician_id')->nullable();
            $table->unsignedTinyInteger('rating_overall');
            $table->json('rating_breakdown')->nullable();
            $table->text('comments')->nullable();
            $table->enum('channel', ['push', 'whatsapp', 'sms', 'web', 'in_app'])->default('in_app');
            $table->enum('status', ['requested', 'submitted', 'needs_attention', 'resolved', 'escalated'])->default('requested');
            $table->text('response_text')->nullable();
            $table->unsignedBigInteger('responded_by')->nullable();
            $table->datetime('response_at')->nullable();
            $table->datetime('sent_at')->nullable();
            $table->datetime('submitted_at')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['job_id']);
            $table->index(['tenant_id', 'status', 'rating_overall']);
            $table->foreign('technician_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('responded_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('feedback_reviews');
    }
};
