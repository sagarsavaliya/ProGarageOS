<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ServiceJob;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class StaffController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;

        $staff = User::where('tenant_id', $tenantId)
            ->whereIn('role', ['technician', 'service_advisor', 'owner'])
            ->orderBy('first_name')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $staff->map(fn (User $u) => $this->formatStaffMember($u, $tenantId)),
        ]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $user     = User::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => $this->formatStaffMember($user, $tenantId, true),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;

        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'last_name'  => ['nullable', 'string', 'max:100'],
            'phone'      => ['required', 'string', 'max:20'],
            'email'      => ['nullable', 'email'],
            'role'       => ['required', 'in:technician,service_advisor'],
            'pin'        => ['required', 'string', 'size:6'],
        ]);

        $user = User::create([
            'tenant_id'  => $tenantId,
            'first_name' => $data['first_name'],
            'last_name'  => $data['last_name'] ?? '',
            'phone'      => $data['phone'],
            'email'      => $data['email'] ?? null,
            'role'       => $data['role'],
            'pin_hash'   => Hash::make($data['pin']),
        ]);

        AuditLog::record('staff.created', 'users', $user->id, [], ['role' => $user->role]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatStaffMember($user, $tenantId),
        ], 201);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $user     = User::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();

        $data = $request->validate([
            'first_name' => ['sometimes', 'string', 'max:100'],
            'last_name'  => ['nullable', 'string', 'max:100'],
            'phone'      => ['sometimes', 'string', 'max:20'],
            'email'      => ['nullable', 'email'],
            'role'       => ['sometimes', 'in:technician,service_advisor,owner'],
        ]);

        unset($data['is_active']);
        $user->update($data);

        return response()->json([
            'success' => true,
            'data'    => $this->formatStaffMember($user->fresh(), $tenantId, true),
        ]);
    }

    /**
     * Technicians and advisors available for job assignment.
     */
    public function technicians(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;

        $staff = User::where('tenant_id', $tenantId)
            ->whereIn('role', ['technician', 'service_advisor', 'owner'])
            ->orderBy('first_name')
            ->get();

        $openCounts = ServiceJob::where('tenant_id', $tenantId)
            ->whereIn('primary_technician_id', $staff->pluck('id'))
            ->whereNotIn('status', ['delivered', 'cancelled'])
            ->selectRaw('primary_technician_id, count(*) as open_count')
            ->groupBy('primary_technician_id')
            ->pluck('open_count', 'primary_technician_id');

        return response()->json([
            'success' => true,
            'data'    => $staff->map(fn (User $u) => [
                'uuid'          => $u->uuid,
                'name'          => $u->full_name,
                'role'          => $u->role,
                'specialty'     => ucfirst(str_replace('_', ' ', $u->role)),
                'is_available'  => ($openCounts[$u->id] ?? 0) < 4,
                'open_jobs'     => (int) ($openCounts[$u->id] ?? 0),
            ]),
        ]);
    }

    private function formatStaffMember(User $user, int $tenantId, bool $full = false): array
    {
        $openJobs = ServiceJob::where('tenant_id', $tenantId)
            ->where('primary_technician_id', $user->id)
            ->whereNotIn('status', ['delivered', 'cancelled'])
            ->count();

        $completed = ServiceJob::where('tenant_id', $tenantId)
            ->where('primary_technician_id', $user->id)
            ->where('status', 'delivered')
            ->count();

        $base = [
            'uuid'          => $user->uuid,
            'name'          => $user->full_name,
            'first_name'    => $user->first_name,
            'last_name'     => $user->last_name,
            'phone'         => $user->phone,
            'email'         => $user->email,
            'role'          => $user->role,
            'specialty'     => ucfirst(str_replace('_', ' ', $user->role)),
            'is_available'  => $openJobs < 4,
            'open_jobs'     => $openJobs,
        ];

        if ($full) {
            $base['completed_jobs'] = $completed;
            $base['avg_rating']     = null;
        }

        return $base;
    }
}
