<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('garage_customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->text('internal_notes')->nullable();
            $table->unsignedInteger('loyalty_points')->default(0);
            $table->unsignedBigInteger('preferred_technician_id')->nullable();
            $table->datetime('last_visited_at')->nullable();
            $table->decimal('total_spent', 12, 2)->default(0);
            $table->unsignedInteger('visit_count')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['customer_id', 'tenant_id']);
            $table->index(['tenant_id', 'last_visited_at']);
            $table->foreign('preferred_technician_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('garage_customers');
    }
};
