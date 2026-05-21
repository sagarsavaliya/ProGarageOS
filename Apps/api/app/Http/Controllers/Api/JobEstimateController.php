<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ServiceJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JobEstimateController extends Controller
{
    public function show(Request $request, string $uuid): JsonResponse
    {
        $job = $this->resolveJob($request, $uuid);
        $job->load('tasks');

        return response()->json([
            'success' => true,
            'data'    => $this->formatEstimate($job),
        ]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $job = $this->resolveJob($request, $uuid);

        $data = $request->validate([
            'lines'                    => ['required', 'array', 'min:1'],
            'lines.*.id'               => ['required', 'integer'],
            'lines.*.estimated_price'  => ['numeric', 'min:0'],
            'lines.*.final_price'      => ['nullable', 'numeric', 'min:0'],
            'lines.*.labor_minutes'    => ['nullable', 'integer', 'min:0'],
        ]);

        DB::transaction(function () use ($job, $data) {
            foreach ($data['lines'] as $line) {
                $task = $job->tasks()->where('id', $line['id'])->first();
                if (! $task) {
                    continue;
                }
                $task->update([
                    'estimated_price' => $line['estimated_price'],
                    'final_price'     => $line['final_price'] ?? $line['estimated_price'],
                    'labor_minutes'   => $line['labor_minutes'] ?? $task->labor_minutes,
                ]);
            }

            $total = $job->tasks()->where('is_billable', true)->sum('final_price');
            $job->update(['estimated_amount' => $total]);
        });

        $job->refresh()->load('tasks');

        return response()->json([
            'success' => true,
            'data'    => $this->formatEstimate($job),
        ]);
    }

    public function send(Request $request, string $uuid): JsonResponse
    {
        $job = $this->resolveJob($request, $uuid);

        $job->update([
            'status'          => 'estimate_pending',
            'approval_status' => 'pending',
        ]);

        AuditLog::record('estimate.sent', 'service_jobs', $job->id, [], []);

        return response()->json([
            'success' => true,
            'data'    => [
                'uuid'   => $job->uuid,
                'status' => $job->status,
                'message'=> 'Estimate sent to customer for approval.',
            ],
        ]);
    }

    public function approve(Request $request, string $uuid): JsonResponse
    {
        $job = $this->resolveJob($request, $uuid);

        $data = $request->validate([
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $job->update([
            'status'               => 'estimate_approved',
            'approval_status'      => 'approved',
            'customer_approved_at' => now(),
            'handover_notes'       => $data['notes'] ?? $job->handover_notes,
        ]);

        AuditLog::record('estimate.approved', 'service_jobs', $job->id, [], ['by' => 'staff']);

        return response()->json([
            'success' => true,
            'data'    => $this->formatEstimate($job->fresh('tasks')),
        ]);
    }

    public function reject(Request $request, string $uuid): JsonResponse
    {
        $job = $this->resolveJob($request, $uuid);

        $data = $request->validate([
            'notes' => ['required', 'string', 'max:2000'],
        ]);

        $job->update([
            'status'          => 'estimate_rejected',
            'approval_status' => 'rejected',
            'handover_notes'  => $data['notes'],
        ]);

        AuditLog::record('estimate.rejected', 'service_jobs', $job->id, [], ['notes' => $data['notes']]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatEstimate($job->fresh('tasks')),
        ]);
    }

    private function resolveJob(Request $request, string $uuid): ServiceJob
    {
        $tenantId = $request->user()->tenant_id;

        return ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();
    }

    private function formatEstimate(ServiceJob $job): array
    {
        $lines = $job->tasks->map(fn ($t) => [
            'id'                         => $t->id,
            'name'                       => $t->name,
            'description'                => $t->description,
            'estimated_price'            => (float) $t->estimated_price,
            'final_price'                => (float) $t->final_price,
            'labor_minutes'              => $t->labor_minutes,
            'is_billable'                => $t->is_billable,
            'requires_customer_approval' => $t->requires_customer_approval,
        ]);

        $subtotal = $lines->where('is_billable', true)->sum('final_price');

        return [
            'job_uuid'             => $job->uuid,
            'job_number'           => $job->job_number,
            'status'               => $job->status,
            'approval_status'      => $job->approval_status,
            'customer_approved_at' => $job->customer_approved_at?->toIso8601String(),
            'lines'                => $lines->values(),
            'subtotal'             => round($subtotal, 2),
            'estimated_amount'     => (float) ($job->estimated_amount ?? $subtotal),
            'currency'             => 'INR',
        ];
    }
}
