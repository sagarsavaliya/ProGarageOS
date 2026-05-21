<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loyalty_programs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->enum('earning_mode', ['spend_based', 'visit_based', 'service_based'])->default('spend_based');
            $table->decimal('points_per_amount', 6, 2)->default(1);
            $table->decimal('min_spend_threshold', 10, 2)->default(0);
            $table->decimal('redemption_rate', 6, 4)->default(0.01); // 1 point = ₹0.01
            $table->unsignedInteger('min_points_to_redeem')->default(100);
            $table->unsignedTinyInteger('max_discount_percent')->default(10);
            $table->unsignedInteger('points_expiry_days')->default(365);
            $table->boolean('stack_with_other_discounts')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('loyalty_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->enum('type', ['earned', 'redeemed', 'expired', 'adjusted', 'voided']);
            $table->integer('points');
            $table->unsignedInteger('balance_after');
            $table->string('reference_type', 50)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->datetime('expires_at')->nullable();
            $table->text('description')->nullable();
            $table->timestamp('created_at')->useCurrent()->index();

            $table->index(['tenant_id', 'customer_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loyalty_transactions');
        Schema::dropIfExists('loyalty_programs');
    }
};
