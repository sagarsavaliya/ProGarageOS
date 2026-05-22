<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_jobs', function (Blueprint $table) {
            $table->boolean('is_insurance_job')->default(false)->after('customer_complaint');
            $table->string('insurance_company', 150)->nullable()->after('is_insurance_job');
            $table->string('claim_number', 100)->nullable()->after('insurance_company');
            $table->enum('insurance_claim_status', [
                'none', 'survey_pending', 'estimate_submitted', 'approved', 'rejected', 'settled',
            ])->default('none')->after('claim_number');
            $table->dateTime('insurance_survey_at')->nullable()->after('insurance_claim_status');
            $table->decimal('customer_liability_amount', 12, 2)->nullable()->after('insurance_survey_at');
            $table->decimal('job_insurance_claim_amount', 12, 2)->nullable()->after('customer_liability_amount');
        });
    }

    public function down(): void
    {
        Schema::table('service_jobs', function (Blueprint $table) {
            $table->dropColumn([
                'is_insurance_job',
                'insurance_company',
                'claim_number',
                'insurance_claim_status',
                'insurance_survey_at',
                'customer_liability_amount',
                'job_insurance_claim_amount',
            ]);
        });
    }
};
