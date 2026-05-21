<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->char('uuid', 36)->unique()->index();
            $table->string('phone_primary', 20)->unique()->index();
            $table->string('phone_secondary', 20)->nullable()->index();
            $table->boolean('is_p_wa_enabled')->default(true);
            $table->boolean('is_s_wa_enabled')->default(false);
            $table->string('email')->nullable();
            $table->string('first_name');
            $table->string('last_name')->nullable();
            $table->char('preferred_language', 5)->default('en');
            $table->boolean('marketing_opt_in')->default(false);
            $table->string('otp_code', 10)->nullable();
            $table->datetime('otp_expires_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
