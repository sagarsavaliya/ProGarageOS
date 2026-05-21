<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentMethodController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;

        $methods = PaymentMethod::query()
            ->where('is_active', true)
            ->where(fn ($q) => $q->whereNull('tenant_id')->orWhere('tenant_id', $tenantId))
            ->orderBy('sort_order')
            ->get(['id', 'name', 'code', 'type', 'requires_reference']);

        return response()->json([
            'success' => true,
            'data'    => $methods->map(fn (PaymentMethod $method) => [
                'id'                 => $method->id,
                'name'               => $method->name,
                'code'               => $method->code,
                'type'               => $method->type,
                'requires_reference' => $method->requires_reference,
            ]),
        ]);
    }
}
