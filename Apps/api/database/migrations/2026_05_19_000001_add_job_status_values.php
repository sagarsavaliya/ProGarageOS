<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE service_jobs MODIFY COLUMN status ENUM(
            'draft', 'checked_in', 'inspecting', 'estimate_pending',
            'estimate_approved', 'estimate_rejected', 'in_progress', 'quality_check',
            'ready_for_delivery', 'delivered', 'cancelled', 'on_hold'
        ) NOT NULL DEFAULT 'draft'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE service_jobs MODIFY COLUMN status ENUM(
            'draft', 'checked_in', 'inspecting', 'estimate_pending',
            'estimate_approved', 'in_progress', 'quality_check',
            'ready_for_delivery', 'delivered', 'cancelled'
        ) NOT NULL DEFAULT 'draft'");
    }
};
