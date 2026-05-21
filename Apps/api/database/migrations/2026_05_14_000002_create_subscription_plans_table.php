<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->string('name');
            $table->string('slug')->unique();
            $table->decimal('price', 10, 2)->default(0);
            $table->enum('billing_cycle', ['monthly', 'yearly', 'quarterly'])->default('monthly');
            $table->unsignedInteger('trial_days')->default(14);
            $table->unsignedInteger('max_locations')->default(1);
            $table->unsignedInteger('max_users')->default(5);
            $table->unsignedInteger('max_jobs_per_month')->default(100);
            $table->json('features')->nullable();
            $table->enum('status', ['draft', 'active', 'archived'])->default('active');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
