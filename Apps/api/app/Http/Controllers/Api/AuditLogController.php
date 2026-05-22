<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ServiceJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! in_array($user->role, ['owner', 'advisor', 'manager'], true)) {
            return response()->json([
                'success' => false,
                'error'   => ['code' => 'FORBIDDEN', 'message' => 'Audit log access is restricted to owners and advisors.'],
            ], 403);
        }

        $tenantId = $user->tenant_id;
        $query    = AuditLog::where('tenant_id', $tenantId)
            ->with('user:id,first_name,last_name,role');

        if ($jobUuid = $request->query('job_uuid')) {
            $job = ServiceJob::withoutGlobalScope('tenant')
                ->where('uuid', $jobUuid)
                ->where('tenant_id', $tenantId)
                ->first();

            if ($job) {
                $query->where('target_type', 'service_jobs')
                    ->where('target_id', $job->id);
            } else {
                $query->whereRaw('1 = 0');
            }
        } else {
            if ($targetType = $request->query('target_type')) {
                $query->where('target_type', $targetType);
            }
            if ($targetId = $request->query('target_id')) {
                $query->where('target_id', (int) $targetId);
            }
        }

        if ($actionType = $request->query('action_type')) {
            $query->where('action_type', $actionType);
        }

        $logs = $query->orderByDesc('created_at')
            ->paginate($request->query('per_page', 30));

        return response()->json([
            'success' => true,
            'data'    => $logs->map(fn ($log) => $this->formatLog($log)),
            'meta'    => [
                'current_page' => $logs->currentPage(),
                'per_page'     => $logs->perPage(),
                'total'        => $logs->total(),
                'last_page'    => $logs->lastPage(),
            ],
        ]);
    }

    private function formatLog(AuditLog $log): array
    {
        $user = $log->user;

        return [
            'id'          => $log->id,
            'action_type' => $log->action_type,
            'target_type' => $log->target_type,
            'target_id'   => $log->target_id,
            'old_values'  => $log->old_values,
            'new_values'  => $log->new_values,
            'notes'       => $log->notes,
            'created_at'  => $log->created_at?->toIso8601String(),
            'user'        => $user ? [
                'name' => trim($user->first_name . ' ' . $user->last_name),
                'role' => $user->role,
            ] : null,
        ];
    }
}
