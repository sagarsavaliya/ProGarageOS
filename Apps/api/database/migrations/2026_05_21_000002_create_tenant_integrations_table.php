<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_integrations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->index();
            $table->string('provider', 50); // whatsapp
            $table->boolean('enabled')->default(false);
            $table->text('credentials')->nullable(); // encrypted JSON
            $table->json('settings')->nullable(); // template names, language
            $table->timestamp('last_tested_at')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'provider']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_integrations');
    }
};
