<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_documents', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique();
            $table->foreignId('vehicle_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->enum('document_type', ['rc', 'insurance', 'puc', 'fitness', 'permit', 'other']);
            $table->string('document_number', 100)->nullable();
            $table->string('issuing_authority', 150)->nullable();
            $table->date('issue_date')->nullable();
            $table->date('expiry_date')->nullable();
            $table->string('file_url', 500)->nullable();
            $table->boolean('is_verified')->default(false);
            $table->boolean('is_active')->default(true);
            $table->json('ocr_extracted_data')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['vehicle_id', 'document_type', 'is_active']);
            $table->index(['expiry_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_documents');
    }
};
