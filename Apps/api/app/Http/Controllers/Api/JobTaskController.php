<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\JobTask;
use App\Models\ServiceJob;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobTaskController extends Controller
{
    public function index(Request $request, string $jobUuid): JsonResponse
    {
        $job = $this->resolveJob($request, $jobUuid);

        $tasks = $job->tasks()
            ->with('assignedTechnician:id,uuid,first_name,last_name')
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $tasks->map(fn (JobTask $t) => $this->formatTask($t)),
        ]);
    }

    public function store(Request $request, string $jobUuid): JsonResponse
    {
        $job = $this->resolveJob($request, $jobUuid);

        $data = $request->validate([
            'name'                        => ['required', 'string', 'max:255'],
            'description'                 => ['nullable', 'string'],
            'source'                      => ['in:planned,discovered,accidental_damage,upsell,customer_request'],
            'status'                      => ['in:pending_approval,approved,in_progress,completed,cancelled,waived'],
            'estimated_price'             => ['numeric', 'min:0'],
            'final_price'                 => ['numeric', 'min:0'],
            'labor_minutes'               => ['integer', 'min:0'],
            'requires_customer_approval'  => ['boolean'],
            'is_billable'                 => ['boolean'],
            'assigned_technician_uuid'    => ['nullable', 'string', 'exists:users,uuid'],
        ]);

        if (! empty($data['assigned_technician_uuid'])) {
            $tech = User::where('uuid', $data['assigned_technician_uuid'])->first();
            $data['assigned_technician_id'] = $tech?->id;
            unset($data['assigned_technician_uuid']);
        }

        $task = $job->tasks()->create($data);
        AuditLog::record('job_task.created', 'job_tasks', $task->id, [], ['name' => $task->name]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatTask($task->load('assignedTechnician')),
        ], 201);
    }

    public function update(Request $request, string $jobUuid, int $taskId): JsonResponse
    {
        $job  = $this->resolveJob($request, $jobUuid);
        $task = $job->tasks()->where('id', $taskId)->firstOrFail();

        $data = $request->validate([
            'name'                        => ['sometimes', 'string', 'max:255'],
            'description'                 => ['nullable', 'string'],
            'status'                      => ['in:pending_approval,approved,in_progress,completed,cancelled,waived'],
            'estimated_price'             => ['numeric', 'min:0'],
            'final_price'                 => ['numeric', 'min:0'],
            'labor_minutes'               => ['integer', 'min:0'],
            'requires_customer_approval'  => ['boolean'],
            'is_billable'                 => ['boolean'],
            'assigned_technician_uuid'    => ['nullable', 'string', 'exists:users,uuid'],
        ]);

        if (array_key_exists('assigned_technician_uuid', $data)) {
            $tech = $data['assigned_technician_uuid']
                ? User::where('uuid', $data['assigned_technician_uuid'])->first()
                : null;
            $data['assigned_technician_id'] = $tech?->id;
            unset($data['assigned_technician_uuid']);
        }

        $task->update($data);

        return response()->json([
            'success' => true,
            'data'    => $this->formatTask($task->fresh('assignedTechnician')),
        ]);
    }

    public function destroy(Request $request, string $jobUuid, int $taskId): JsonResponse
    {
        $job  = $this->resolveJob($request, $jobUuid);
        $task = $job->tasks()->where('id', $taskId)->firstOrFail();
        $task->delete();

        return response()->json(['success' => true, 'data' => null]);
    }

    private function resolveJob(Request $request, string $uuid): ServiceJob
    {
        $tenantId = $request->user()->tenant_id;

        return ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();
    }

    private function formatTask(JobTask $task): array
    {
        return [
            'id'                         => $task->id,
            'name'                       => $task->name,
            'description'                => $task->description,
            'source'                     => $task->source,
            'status'                     => $task->status,
            'estimated_price'            => (float) $task->estimated_price,
            'final_price'                => (float) $task->final_price,
            'labor_minutes'              => $task->labor_minutes,
            'requires_customer_approval' => $task->requires_customer_approval,
            'is_billable'                => $task->is_billable,
            'technician'                 => $task->assignedTechnician ? [
                'uuid' => $task->assignedTechnician->uuid,
                'name' => $task->assignedTechnician->full_name,
            ] : null,
        ];
    }
}
