<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('invoice_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('payment_method_id')->nullable();
            $table->decimal('amount', 12, 2);
            $table->char('currency', 3)->default('INR');
            $table->enum('status', ['pending', 'processing', 'success', 'failed', 'refunded', 'partial_refund', 'chargeback'])->default('pending');
            $table->enum('payment_type', ['customer_pay', 'insurance_claim', 'advance', 'refund', 'adjustment'])->default('customer_pay');
            $table->string('reference_number', 100)->nullable();
            $table->string('gateway_transaction_id', 150)->nullable();
            $table->json('gateway_response')->nullable();
            $table->datetime('paid_at')->nullable();
            $table->text('failed_reason')->nullable();
            $table->decimal('refunded_amount', 12, 2)->default(0);
            $table->datetime('refunded_at')->nullable();
            $table->datetime('reconciled_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['tenant_id', 'status']);
            $table->foreign('payment_method_id')->references('id')->on('payment_methods')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
