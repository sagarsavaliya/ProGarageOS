<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_service_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('job_id')->constrained('service_jobs')->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('service_categories');
            $table->boolean('is_primary')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['job_id', 'category_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_service_categories');
    }
};
