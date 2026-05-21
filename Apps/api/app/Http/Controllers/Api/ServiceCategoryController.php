<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;

        $categories = ServiceCategory::where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $categories->map(fn (ServiceCategory $c) => [
                'uuid'                     => $c->uuid,
                'id'                       => $c->id,
                'name'                     => $c->name,
                'code'                     => $c->code,
                'default_duration_min'     => $c->default_duration_min,
                'requires_intake_inspection' => $c->requires_intake_inspection,
                'requires_approval'        => $c->requires_approval,
            ]),
        ]);
    }
}
