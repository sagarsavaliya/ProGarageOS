<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('parts_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('code', 50);
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
            $table->foreign('parent_id')->references('id')->on('parts_categories')->nullOnDelete();
        });

        Schema::create('vendors', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('code', 50);
            $table->enum('vendor_type', ['parts_supplier', 'insurance_agent', 'towing_service', 'external_workshop', 'misc'])->default('parts_supplier');
            $table->string('contact_name', 100)->nullable();
            $table->string('contact_phone', 20)->nullable();
            $table->string('contact_email')->nullable();
            $table->string('address')->nullable();
            $table->string('city', 100)->nullable();
            $table->string('state', 100)->nullable();
            $table->string('gst_number', 20)->nullable();
            $table->enum('payment_terms', ['immediate', 'net_7', 'net_15', 'net_30', 'net_60'])->default('immediate');
            $table->decimal('credit_limit', 12, 2)->default(0);
            $table->decimal('current_balance', 12, 2)->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->unsignedInteger('average_lead_time_days')->default(0);
            $table->boolean('is_preferred')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'tenant_id']);
        });

        Schema::create('inventory_items', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('sku', 100);
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('brand', 100)->nullable();
            $table->unsignedBigInteger('category_id')->nullable();
            $table->enum('unit_of_measure', ['piece', 'litre', 'ml', 'kg', 'gram', 'set', 'pair', 'box', 'meter'])->default('piece');
            $table->decimal('cost_price', 10, 2)->default(0);
            $table->decimal('selling_price', 10, 2)->default(0);
            $table->unsignedBigInteger('tax_rate_id')->nullable();
            $table->integer('stock_on_hand')->default(0);
            $table->integer('low_stock_threshold')->default(5);
            $table->integer('reorder_quantity')->default(10);
            $table->unsignedBigInteger('preferred_vendor_id')->nullable();
            $table->boolean('requires_serial_warranty')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'sku']);
            $table->index(['tenant_id', 'category_id', 'is_active']);
            $table->foreign('category_id')->references('id')->on('parts_categories')->nullOnDelete();
            $table->foreign('tax_rate_id')->references('id')->on('tax_rates')->nullOnDelete();
            $table->foreign('preferred_vendor_id')->references('id')->on('vendors')->nullOnDelete();
        });

        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('vendor_id')->constrained();
            $table->string('po_number', 50);
            $table->enum('status', ['draft', 'sent', 'partial', 'received', 'cancelled'])->default('draft');
            $table->date('order_date');
            $table->date('expected_delivery_date')->nullable();
            $table->date('actual_delivery_date')->nullable();
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('tax_total', 12, 2)->default(0);
            $table->decimal('grand_total', 12, 2)->default(0);
            $table->enum('payment_status', ['unpaid', 'partially_paid', 'paid'])->default('unpaid');
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['tenant_id', 'po_number']);
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
        });

        Schema::create('purchase_order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('inventory_item_id')->constrained();
            $table->decimal('quantity_ordered', 10, 3);
            $table->decimal('quantity_received', 10, 3)->default(0);
            $table->decimal('unit_cost', 10, 2);
            $table->unsignedBigInteger('tax_rate_id')->nullable();
            $table->decimal('line_total', 10, 2)->default(0);
            $table->json('batch_serial_numbers')->nullable();
            $table->timestamps();

            $table->foreign('tax_rate_id')->references('id')->on('tax_rates')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_order_items');
        Schema::dropIfExists('purchase_orders');
        Schema::dropIfExists('inventory_items');
        Schema::dropIfExists('vendors');
        Schema::dropIfExists('parts_categories');
    }
};
