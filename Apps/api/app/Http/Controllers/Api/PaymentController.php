<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    /**
     * GET /payments/outstanding — invoices with balance due (payments hub).
     */
    public function outstanding(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = Invoice::where('tenant_id', $tenantId)
            ->where('balance_due', '>', 0)
            ->whereIn('status', ['sent', 'partially_paid', 'overdue'])
            ->with([
                'customer:id,uuid,first_name,last_name,phone_primary',
                'vehicle:id,uuid,registration_number,maker,model',
            ])
            ->orderByDesc('balance_due');

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('invoice_number', 'like', "%{$search}%")
                    ->orWhereHas('customer', fn ($c) => $c
                        ->where('first_name', 'like', "%{$search}%")
                        ->orWhere('last_name', 'like', "%{$search}%")
                        ->orWhere('phone_primary', 'like', "%{$search}%"))
                    ->orWhereHas('vehicle', fn ($v) => $v
                        ->where('registration_number', 'like', "%{$search}%"));
            });
        }

        $invoices = $query->paginate($request->query('per_page', 25));

        $totalOutstanding = (float) Invoice::where('tenant_id', $tenantId)
            ->where('balance_due', '>', 0)
            ->whereIn('status', ['sent', 'partially_paid', 'overdue'])
            ->sum('balance_due');

        return response()->json([
            'success' => true,
            'data'    => $invoices->map(fn ($inv) => $this->formatOutstanding($inv)),
            'meta'    => [
                'current_page'      => $invoices->currentPage(),
                'per_page'          => $invoices->perPage(),
                'total'             => $invoices->total(),
                'last_page'         => $invoices->lastPage(),
                'total_outstanding' => $totalOutstanding,
            ],
        ]);
    }

    private function formatOutstanding(Invoice $invoice): array
    {
        return [
            'uuid'            => $invoice->uuid,
            'invoice_number'  => $invoice->invoice_number,
            'status'          => $invoice->status,
            'grand_total'     => (float) $invoice->grand_total,
            'amount_paid'     => (float) $invoice->amount_paid,
            'balance_due'     => (float) $invoice->balance_due,
            'issued_date'     => $invoice->issued_date?->toIso8601String(),
            'due_date'        => $invoice->due_date?->toIso8601String(),
            'customer'        => $invoice->customer ? [
                'uuid'  => $invoice->customer->uuid,
                'name'  => $invoice->customer->full_name,
                'phone' => $invoice->customer->phone_primary,
            ] : null,
            'vehicle'         => $invoice->vehicle ? [
                'uuid'                => $invoice->vehicle->uuid,
                'registration_number' => $invoice->vehicle->registration_number,
                'display'             => $invoice->vehicle->display_name,
            ] : null,
        ];
    }
}
