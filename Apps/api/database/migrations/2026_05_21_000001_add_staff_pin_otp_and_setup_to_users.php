<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('pin_otp_code', 6)->nullable()->after('pin_hash');
            $table->timestamp('pin_otp_expires_at')->nullable()->after('pin_otp_code');
            $table->timestamp('phone_verified_at')->nullable()->after('pin_otp_expires_at');
            $table->boolean('requires_pin_setup')->default(false)->after('phone_verified_at');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['pin_otp_code', 'pin_otp_expires_at', 'phone_verified_at', 'requires_pin_setup']);
        });
    }
};
