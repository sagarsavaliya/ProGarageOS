<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoice_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('job_task_id')->nullable();
            $table->unsignedBigInteger('service_item_id')->nullable();
            $table->unsignedBigInteger('part_id')->nullable();
            $table->enum('line_type', ['service', 'part', 'labor', 'package', 'manual', 'discount', 'tax']);
            $table->string('name');
            $table->text('description')->nullable();
            $table->decimal('quantity', 10, 3)->default(1);
            $table->decimal('unit_price', 10, 2)->default(0);
            $table->unsignedBigInteger('tax_rate_id')->nullable();
            $table->decimal('tax_amount', 10, 2)->default(0);
            $table->decimal('discount_amount', 10, 2)->default(0);
            $table->decimal('total_amount', 10, 2)->default(0);
            $table->boolean('is_taxable')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->text('internal_notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['invoice_id', 'line_type']);
            $table->foreign('job_task_id')->references('id')->on('job_tasks')->nullOnDelete();
            $table->foreign('service_item_id')->references('id')->on('service_items')->nullOnDelete();
            $table->foreign('tax_rate_id')->references('id')->on('tax_rates')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoice_items');
    }
};
