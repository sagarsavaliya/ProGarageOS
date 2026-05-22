<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $tenant = $request->user()->tenant()->with('activeSubscription.plan')->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($tenant),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $this->ensureOwner($request);

        $data = $request->validate([
            'business_name' => ['sometimes', 'string', 'max:200'],
            'business_type' => ['sometimes', 'string', 'max:50'],
            'timezone'      => ['sometimes', 'string', 'max:50'],
            'currency'      => ['sometimes', 'string', 'max:3'],
            'phone'         => ['nullable', 'string', 'max:20'],
            'email'         => ['nullable', 'email', 'max:255'],
            'address'       => ['nullable', 'string', 'max:500'],
            'city'          => ['nullable', 'string', 'max:100'],
            'state'         => ['nullable', 'string', 'max:100'],
            'pincode'       => ['nullable', 'string', 'max:10'],
            'gst_number'    => ['nullable', 'string', 'max:20'],
        ]);

        $tenant = $request->user()->tenant;
        $tenant->update($data);

        AuditLog::record('tenant.profile.updated', 'tenants', $tenant->id);

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($tenant->fresh()->load('activeSubscription.plan')),
        ]);
    }

    /**
     * PATCH /tenant/setup — persist wizard progress (resume-safe, server source of truth).
     */
    public function updateSetup(Request $request): JsonResponse
    {
        $this->ensureOwner($request);

        $data = $request->validate([
            'setup_step'      => ['sometimes', 'in:welcome,details,bays,done'],
            'setup_bay_count' => ['nullable', 'integer', 'min:1', 'max:50'],
            'complete'        => ['sometimes', 'boolean'],
        ]);

        $tenant = $request->user()->tenant;

        if (array_key_exists('setup_step', $data)) {
            $tenant->setup_step = $data['setup_step'];
        }

        if (array_key_exists('setup_bay_count', $data)) {
            $tenant->setup_bay_count = $data['setup_bay_count'];
        }

        if (!empty($data['complete'])) {
            $tenant->setup_step           = 'done';
            $tenant->setup_completed_at ??= now();
        }

        $tenant->save();

        AuditLog::record('tenant.setup.updated', 'tenants', $tenant->id);

        return response()->json([
            'success' => true,
            'data'    => $this->formatTenant($tenant->fresh()->load('activeSubscription.plan')),
        ]);
    }

    private function formatTenant($tenant): array
    {
        $subscription = $tenant->activeSubscription;

        return [
            'uuid'          => $tenant->uuid,
            'business_name' => $tenant->business_name,
            'business_type' => $tenant->business_type,
            'status'        => $tenant->status,
            'currency'      => $tenant->currency,
            'timezone'      => $tenant->timezone,
            'country_code'  => $tenant->country_code,
            'phone'         => $tenant->phone,
            'email'         => $tenant->email,
            'address'       => $tenant->address,
            'city'          => $tenant->city,
            'state'         => $tenant->state,
            'pincode'       => $tenant->pincode,
            'gst_number'    => $tenant->gst_number,
            'logo_url'      => $tenant->logo_url,
            'setup_step'    => $tenant->setup_step ?? 'welcome',
            'setup_bay_count' => $tenant->setup_bay_count,
            'setup_completed_at' => $tenant->setup_completed_at?->toIso8601String(),
            'setup_complete'  => $tenant->setup_completed_at !== null,
            'subscription'  => $subscription ? [
                'status'             => $subscription->status,
                'plan_name'          => $subscription->plan?->name,
                'current_period_end' => $subscription->current_period_end?->toIso8601String(),
                'max_users'          => $subscription->plan?->max_users,
                'max_locations'      => $subscription->plan?->max_locations,
            ] : null,
            'created_at' => $tenant->created_at?->toIso8601String(),
        ];
    }

    private function ensureOwner(Request $request): void
    {
        if ($request->user()->role !== 'owner') {
            abort(response()->json([
                'success' => false,
                'error'   => ['code' => 'FORBIDDEN', 'message' => 'Only the garage owner can manage tenant settings.'],
            ], 403));
        }
    }
}
