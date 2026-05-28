<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_makes', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->string('name', 120);
            $table->string('slug', 140);
            $table->enum('vehicle_category', ['car', 'bike', 'commercial', 'luxury'])->default('car');
            $table->char('country_code', 2)->default('IN');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['slug', 'vehicle_category']);
            $table->index(['vehicle_category', 'is_active', 'name']);
        });

        Schema::create('vehicle_models', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('vehicle_make_id')->constrained('vehicle_makes')->cascadeOnDelete();
            $table->string('name', 120);
            $table->string('slug', 140);
            $table->string('body_type', 50)->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['vehicle_make_id', 'slug']);
            $table->index(['vehicle_make_id', 'is_active', 'name']);
        });

        Schema::create('vehicle_variants', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('vehicle_model_id')->constrained('vehicle_models')->cascadeOnDelete();
            $table->string('name', 160);
            $table->string('slug', 180);
            $table->enum('fuel_type', ['petrol', 'diesel', 'electric', 'cng', 'lpg', 'hybrid'])->nullable();
            $table->enum('transmission', ['manual', 'automatic', 'cvt', 'amt'])->nullable();
            $table->unsignedSmallInteger('year_from')->nullable();
            $table->unsignedSmallInteger('year_to')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['vehicle_model_id', 'slug', 'year_from']);
            $table->index(['vehicle_model_id', 'year_from', 'year_to', 'is_active'], 'veh_variants_year_filter_idx');
            $table->index(['vehicle_model_id', 'is_active', 'name'], 'veh_variants_model_name_idx');
        });

        Schema::create('vehicle_colors', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->string('name', 80);
            $table->string('slug', 100)->unique();
            $table->char('hex_code', 7)->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['is_active', 'name']);
        });

        Schema::create('vehicle_variant_colors', function (Blueprint $table) {
            $table->foreignId('vehicle_variant_id')->constrained('vehicle_variants')->cascadeOnDelete();
            $table->foreignId('vehicle_color_id')->constrained('vehicle_colors')->cascadeOnDelete();
            $table->boolean('is_default')->default(false);
            $table->primary(['vehicle_variant_id', 'vehicle_color_id']);
        });

        Schema::table('vehicles', function (Blueprint $table) {
            $table->foreignId('vehicle_make_id')->nullable()->after('transmission')->constrained('vehicle_makes')->nullOnDelete();
            $table->foreignId('vehicle_model_id')->nullable()->after('vehicle_make_id')->constrained('vehicle_models')->nullOnDelete();
            $table->foreignId('vehicle_variant_id')->nullable()->after('vehicle_model_id')->constrained('vehicle_variants')->nullOnDelete();
            $table->foreignId('vehicle_color_id')->nullable()->after('color')->constrained('vehicle_colors')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropConstrainedForeignId('vehicle_color_id');
            $table->dropConstrainedForeignId('vehicle_variant_id');
            $table->dropConstrainedForeignId('vehicle_model_id');
            $table->dropConstrainedForeignId('vehicle_make_id');
        });

        Schema::dropIfExists('vehicle_variant_colors');
        Schema::dropIfExists('vehicle_colors');
        Schema::dropIfExists('vehicle_variants');
        Schema::dropIfExists('vehicle_models');
        Schema::dropIfExists('vehicle_makes');
    }
};
