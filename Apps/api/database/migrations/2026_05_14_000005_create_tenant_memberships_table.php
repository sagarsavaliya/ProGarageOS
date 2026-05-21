<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Phase 2 stub — table created now, populated in Phase 2 sprint
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('role', ['owner', 'manager', 'service_advisor', 'technician', 'receptionist']);
            $table->json('permissions_override')->nullable();
            $table->boolean('is_primary_tenant')->default(false);
            $table->unsignedBigInteger('invited_by')->nullable();
            $table->datetime('invited_at')->nullable();
            $table->datetime('accepted_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'user_id']);
            $table->index(['tenant_id', 'role']);
            $table->foreign('invited_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_memberships');
    }
};
