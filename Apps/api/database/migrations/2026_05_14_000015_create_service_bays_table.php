<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_bays', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('code', 50);
            $table->enum('bay_type', ['general_lift', 'alignment', 'paint_booth', 'wash_bay', 'diagnostic', 'waiting_area'])->default('general_lift');
            $table->unsignedTinyInteger('capacity_concurrent')->default(1);
            $table->json('equipment_features')->nullable();
            $table->enum('status', ['available', 'occupied', 'maintenance', 'reserved'])->default('available');
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
            $table->index(['tenant_id', 'status', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_bays');
    }
};
