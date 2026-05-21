<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceBay;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceBayController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $bays     = ServiceBay::where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->with(['currentJobs' => fn ($q) => $q->with('vehicle:id,maker,model,registration_number', 'primaryTechnician:id,first_name,last_name')])
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $bays->map(fn ($b) => [
                'uuid'     => $b->uuid,
                'name'     => $b->name,
                'code'     => $b->code,
                'bay_type' => $b->bay_type,
                'status'   => $b->status,
                'current_job' => $b->currentJobs->first() ? [
                    'uuid'       => $b->currentJobs->first()->uuid,
                    'job_number' => $b->currentJobs->first()->job_number,
                    'status'     => $b->currentJobs->first()->status,
                    'vehicle'    => $b->currentJobs->first()->vehicle?->display_name,
                    'technician' => $b->currentJobs->first()->primaryTechnician?->full_name,
                ] : null,
            ]),
        ]);
    }

    public function updateStatus(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $bay      = ServiceBay::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();

        $data = $request->validate([
            'status' => ['required', 'in:available,occupied,maintenance,reserved'],
        ]);

        $bay->update($data);
        return response()->json(['success' => true, 'data' => ['uuid' => $bay->uuid, 'status' => $bay->status]]);
    }
}
