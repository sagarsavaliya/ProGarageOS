<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique()->index();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained();
            $table->foreignId('vehicle_id')->constrained();
            $table->foreignId('job_id')->constrained('service_jobs');
            $table->string('invoice_number', 50);
            $table->enum('type', ['final', 'advance', 'proforma', 'credit_note', 'warranty'])->default('final');
            $table->enum('status', ['draft', 'sent', 'paid', 'partially_paid', 'overdue', 'void'])->default('draft');
            $table->datetime('issued_date')->nullable();
            $table->date('due_date')->nullable();
            $table->datetime('paid_at')->nullable();
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('tax_total', 12, 2)->default(0);
            $table->decimal('discount_total', 12, 2)->default(0);
            $table->decimal('grand_total', 12, 2)->default(0);
            $table->decimal('amount_paid', 12, 2)->default(0);
            $table->decimal('balance_due', 12, 2)->default(0);
            $table->decimal('customer_pay_amount', 12, 2)->nullable();
            $table->decimal('insurance_claim_amount', 12, 2)->nullable();
            $table->string('payment_method', 50)->nullable();
            $table->string('payment_reference', 100)->nullable();
            $table->string('gateway', 50)->nullable();
            $table->string('gateway_transaction_id', 150)->nullable();
            $table->string('qr_code_url', 500)->nullable();
            $table->string('pdf_url', 500)->nullable();
            $table->text('customer_notes')->nullable();
            $table->text('internal_notes')->nullable();
            $table->text('terms_conditions')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'invoice_number']);
            $table->index(['tenant_id', 'status', 'due_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
