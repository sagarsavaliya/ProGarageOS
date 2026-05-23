<?php

namespace App\Http\Controllers\Api\Platform;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlatformSubscriptionPlanController extends Controller
{
    public function index(): JsonResponse
    {
        $plans = SubscriptionPlan::orderBy('price')->get()->map(fn ($p) => $this->format($p));

        return response()->json(['success' => true, 'data' => $plans]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $plan = SubscriptionPlan::create($data);

        return response()->json(['success' => true, 'data' => $this->format($plan)], 201);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $plan = SubscriptionPlan::where('uuid', $uuid)->firstOrFail();
        $plan->update($this->validated($request, $plan));

        return response()->json(['success' => true, 'data' => $this->format($plan->fresh())]);
    }

    public function destroy(string $uuid): JsonResponse
    {
        $plan = SubscriptionPlan::where('uuid', $uuid)->firstOrFail();
        $plan->update(['status' => 'archived']);

        return response()->json(['success' => true, 'message' => 'Plan archived.']);
    }

    private function validated(Request $request, ?SubscriptionPlan $existing = null): array
    {
        return $request->validate([
            'name'              => [$existing ? 'sometimes' : 'required', 'string', 'max:100'],
            'slug'              => [$existing ? 'sometimes' : 'required', 'string', 'max:50', 'alpha_dash'],
            'price'             => ['sometimes', 'numeric', 'min:0'],
            'billing_cycle'     => ['sometimes', 'in:monthly,yearly,quarterly'],
            'trial_days'        => ['sometimes', 'integer', 'min:0'],
            'max_locations'     => ['sometimes', 'integer', 'min:1'],
            'max_users'         => ['sometimes', 'integer', 'min:1'],
            'max_jobs_per_month'=> ['sometimes', 'integer', 'min:1'],
            'features'          => ['nullable', 'array'],
            'status'            => ['sometimes', 'in:draft,active,archived'],
        ]);
    }

    private function format(SubscriptionPlan $plan): array
    {
        return [
            'uuid'               => $plan->uuid,
            'name'               => $plan->name,
            'slug'               => $plan->slug,
            'price'              => (float) $plan->price,
            'billing_cycle'      => $plan->billing_cycle,
            'trial_days'         => (int) $plan->trial_days,
            'max_locations'      => (int) $plan->max_locations,
            'max_users'          => (int) $plan->max_users,
            'max_jobs_per_month' => (int) $plan->max_jobs_per_month,
            'features'           => $plan->features ?? [],
            'status'             => $plan->status,
        ];
    }
}
