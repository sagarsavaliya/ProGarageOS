<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique()->index();
            $table->string('business_name');
            $table->enum('business_type', ['single', 'multi_location'])->default('single');
            $table->enum('status', ['trial', 'active', 'suspended', 'churned'])->default('trial');
            $table->char('currency', 3)->default('INR');
            $table->string('timezone', 50)->default('Asia/Kolkata');
            $table->char('country_code', 2)->default('IN');
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->string('address')->nullable();
            $table->string('city', 100)->nullable();
            $table->string('state', 100)->nullable();
            $table->string('pincode', 10)->nullable();
            $table->string('gst_number', 20)->nullable();
            $table->string('logo_url', 500)->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenants');
    }
};
