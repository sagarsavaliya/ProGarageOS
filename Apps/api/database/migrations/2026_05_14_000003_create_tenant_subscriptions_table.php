<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('plan_id')->constrained('subscription_plans');
            $table->enum('status', ['trialing', 'active', 'past_due', 'canceled', 'expired', 'paused'])->default('trialing');
            $table->datetime('current_period_start');
            $table->datetime('current_period_end');
            $table->boolean('cancel_at_period_end')->default(false);
            $table->datetime('canceled_at')->nullable();
            $table->string('gateway', 50)->nullable();
            $table->string('gateway_subscription_id')->nullable();
            $table->string('gateway_customer_id')->nullable();
            $table->decimal('price_at_signup', 10, 2)->nullable();
            $table->char('currency_at_signup', 3)->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_subscriptions');
    }
};
