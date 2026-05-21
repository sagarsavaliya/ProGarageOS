<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->nullable()->index();
            $table->string('name');
            $table->string('code', 50);
            $table->enum('type', ['cash', 'digital', 'card', 'cheque', 'insurance', 'split']);
            $table->string('gateway_provider', 50)->nullable();
            $table->boolean('requires_reference')->default(false);
            $table->enum('processing_fee_type', ['none', 'flat', 'percentage'])->default('none');
            $table->decimal('processing_fee_value', 6, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_methods');
    }
};
