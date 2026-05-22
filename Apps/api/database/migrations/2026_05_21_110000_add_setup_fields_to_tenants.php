<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->enum('setup_step', ['welcome', 'details', 'bays', 'done'])
                ->default('welcome')
                ->after('logo_url');
            $table->unsignedSmallInteger('setup_bay_count')->nullable()->after('setup_step');
            $table->timestamp('setup_completed_at')->nullable()->after('setup_bay_count');
        });

        // Existing garages should not be forced through setup again.
        DB::table('tenants')->update([
            'setup_step'         => 'done',
            'setup_completed_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['setup_step', 'setup_bay_count', 'setup_completed_at']);
        });
    }
};
