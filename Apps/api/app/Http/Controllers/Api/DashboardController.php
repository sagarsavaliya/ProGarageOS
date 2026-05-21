<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceJob;
use App\Models\Invoice;
use App\Models\ServiceBay;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DashboardController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $user     = $request->user();
        $tenantId = $user->tenant_id;
        $period   = $request->query('period', 'today');

        $cacheKey = "dashboard:{$tenantId}:{$period}";

        $payload = Cache::remember($cacheKey, 30, function () use ($tenantId, $period) {
            return $this->buildSummaryPayload($tenantId, $period);
        });

        return response()->json(['success' => true, 'data' => $payload]);
    }

    private function buildSummaryPayload(int $tenantId, string $period): array
    {
        [$start, $end] = $this->periodRange($period);

        // KPI: Jobs
        $jobsToday  = ServiceJob::where('tenant_id', $tenantId)
            ->whereBetween('created_at', [$start, $end])
            ->count();

        $activeJobs = ServiceJob::where('tenant_id', $tenantId)
            ->whereNotIn('status', ['delivered', 'cancelled'])
            ->count();

        // KPI: Revenue
        $revenue = Invoice::where('tenant_id', $tenantId)
            ->whereBetween('paid_at', [$start, $end])
            ->where('status', 'paid')
            ->sum('grand_total');

        $pendingAmount = Invoice::where('tenant_id', $tenantId)
            ->whereIn('status', ['partially_paid', 'sent'])
            ->sum('balance_due');

        // KPI: Customers
        $newCustomers = Customer::whereHas('garageProfiles', fn ($q) => $q->where('tenant_id', $tenantId)
            ->whereBetween('created_at', [$start, $end])
        )->count();

        // Revenue chart (last 7 days)
        $revenueChart = Invoice::where('tenant_id', $tenantId)
            ->where('status', 'paid')
            ->whereBetween('paid_at', [now()->subDays(6)->startOfDay(), now()->endOfDay()])
            ->selectRaw('DATE(paid_at) as date, SUM(grand_total) as total')
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->keyBy('date');

        $chartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $date        = now()->subDays($i)->format('Y-m-d');
            $chartData[] = [
                'date'  => $date,
                'total' => (float) ($revenueChart[$date]->total ?? 0),
            ];
        }

        // Service bays
        $bays = ServiceBay::where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->with(['currentJobs' => fn ($q) => $q->with('vehicle:id,maker,model,registration_number')])
            ->orderBy('sort_order')
            ->get()
            ->map(fn ($bay) => [
                'uuid'    => $bay->uuid,
                'name'    => $bay->name,
                'code'    => $bay->code,
                'type'    => $bay->bay_type,
                'status'  => $bay->status,
                'job'     => $bay->currentJobs->first() ? [
                    'uuid'       => $bay->currentJobs->first()->uuid,
                    'job_number' => $bay->currentJobs->first()->job_number,
                    'status'     => $bay->currentJobs->first()->status,
                    'vehicle'    => $bay->currentJobs->first()->vehicle?->display_name,
                ] : null,
            ]);

        // Active jobs list
        $activeJobsList = ServiceJob::where('tenant_id', $tenantId)
            ->whereNotIn('status', ['delivered', 'cancelled'])
            ->with([
                'customer:id,first_name,last_name,phone_primary',
                'vehicle:id,maker,model,registration_number',
                'primaryTechnician:id,first_name,last_name',
            ])
            ->orderBy('priority', 'desc')
            ->orderBy('actual_start_at')
            ->limit(20)
            ->get()
            ->map(fn ($job) => [
                'uuid'        => $job->uuid,
                'job_number'  => $job->job_number,
                'status'      => $job->status,
                'priority'    => $job->priority,
                'customer'    => $job->customer ? [
                    'name'  => $job->customer->full_name,
                    'phone' => $job->customer->phone_primary,
                ] : null,
                'vehicle'     => $job->vehicle ? [
                    'display'              => $job->vehicle->display_name,
                    'registration_number'  => $job->vehicle->registration_number,
                ] : null,
                'technician'  => $job->primaryTechnician?->full_name,
                'started_at'  => $job->actual_start_at?->toIso8601String(),
                'eta'         => $job->estimated_completion_at?->toIso8601String(),
            ]);

        return [
            'period'  => $period,
            'kpis'    => [
                'jobs_today'      => $jobsToday,
                'active_jobs'     => $activeJobs,
                'revenue'         => (float) $revenue,
                'pending_amount'  => (float) $pendingAmount,
                'new_customers'   => $newCustomers,
            ],
            'revenue_chart'  => $chartData,
            'service_bays'   => $bays,
            'active_jobs'    => $activeJobsList,
        ];
    }

    private function periodRange(string $period): array
    {
        return match ($period) {
            'week'  => [now()->startOfWeek(), now()->endOfWeek()],
            'month' => [now()->startOfMonth(), now()->endOfMonth()],
            default => [now()->startOfDay(), now()->endOfDay()],
        };
    }
}
