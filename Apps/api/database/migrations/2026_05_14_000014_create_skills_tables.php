<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('skills', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code', 50)->unique();
            $table->unsignedBigInteger('category_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('technician_skills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skill_id')->constrained()->cascadeOnDelete();
            $table->enum('proficiency_level', ['beginner', 'intermediate', 'expert'])->default('intermediate');
            $table->unsignedSmallInteger('years_experience')->default(0);
            $table->boolean('is_verified')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'skill_id']);
        });

        Schema::create('service_item_skills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_item_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skill_id')->constrained()->cascadeOnDelete();
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            $table->unique(['service_item_id', 'skill_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_item_skills');
        Schema::dropIfExists('technician_skills');
        Schema::dropIfExists('skills');
    }
};
