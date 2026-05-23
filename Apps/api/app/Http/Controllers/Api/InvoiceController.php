<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\GenerateInvoicePdfJob;
use App\Models\AuditLog;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\ServiceJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use App\Services\PushNotificationService;

class InvoiceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $query    = Invoice::where('tenant_id', $tenantId)
            ->with(['customer:id,uuid,first_name,last_name', 'vehicle:id,uuid,registration_number']);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $invoices = $query->orderByDesc('created_at')->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data'    => $invoices->map(fn ($inv) => $this->formatInvoice($inv)),
            'meta'    => [
                'current_page' => $invoices->currentPage(),
                'per_page'     => $invoices->perPage(),
                'total'        => $invoices->total(),
                'last_page'    => $invoices->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $invoice  = Invoice::where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->with(['customer', 'vehicle', 'job:id,uuid,job_number', 'items.taxRate', 'payments.paymentMethod'])
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $this->formatInvoice($invoice, true)]);
    }

    public function store(Request $request): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $data = $request->validate([
            'job_uuid'          => ['required', 'string', 'exists:service_jobs,uuid'],
            'type'              => ['in:final,advance,proforma'],
            'customer_notes'    => ['nullable', 'string'],
            'terms_conditions'  => ['nullable', 'string'],
            'items'             => ['required', 'array', 'min:1'],
            'items.*.line_type' => ['required', 'in:service,part,labor,package,manual,discount,tax'],
            'items.*.name'      => ['required', 'string'],
            'items.*.quantity'  => ['required', 'numeric', 'min:0.001'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
            'items.*.tax_rate_id' => ['nullable', 'integer', 'exists:tax_rates,id'],
            'items.*.discount_amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        $job = ServiceJob::withoutGlobalScope('tenant')
            ->where('uuid', $data['job_uuid'])
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $invoice = Invoice::create([
            'tenant_id'        => $tenantId,
            'customer_id'      => $job->customer_id,
            'vehicle_id'       => $job->vehicle_id,
            'job_id'           => $job->id,
            'type'             => $data['type'] ?? 'final',
            'customer_notes'   => $data['customer_notes'] ?? null,
            'terms_conditions' => $data['terms_conditions'] ?? null,
            'issued_date'      => now(),
        ]);

        foreach ($data['items'] as $i => $item) {
            $taxAmount = 0;
            if (!empty($item['tax_rate_id'])) {
                $taxRate   = \App\Models\TaxRate::find($item['tax_rate_id']);
                $taxAmount = $taxRate ? round(($item['unit_price'] * $item['quantity']) * ($taxRate->rate_percentage / 100), 2) : 0;
            }
            $total = ($item['unit_price'] * $item['quantity']) + $taxAmount - ($item['discount_amount'] ?? 0);
            InvoiceItem::create([
                'invoice_id'      => $invoice->id,
                'line_type'       => $item['line_type'],
                'name'            => $item['name'],
                'quantity'        => $item['quantity'],
                'unit_price'      => $item['unit_price'],
                'tax_rate_id'     => $item['tax_rate_id'] ?? null,
                'tax_amount'      => $taxAmount,
                'discount_amount' => $item['discount_amount'] ?? 0,
                'total_amount'    => $total,
                'sort_order'      => $i,
            ]);
        }

        $invoice->recalculate();

        AuditLog::record('invoice.created', 'invoices', $invoice->id, [], [
            'invoice_number' => $invoice->invoice_number,
            'job_id'         => $job->id,
        ]);

        GenerateInvoicePdfJob::dispatch($invoice->id);

        return response()->json(['success' => true, 'data' => $this->formatInvoice($invoice->fresh(['items', 'customer', 'vehicle']))], 201);
    }

    public function recordPayment(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $invoice  = Invoice::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();

        $data = $request->validate([
            'amount'            => ['required', 'numeric', 'min:0.01'],
            'payment_method_id' => ['nullable', 'integer', 'exists:payment_methods,id'],
            'payment_type'      => ['in:customer_pay,insurance_claim,advance'],
            'reference_number'  => ['nullable', 'string', 'max:100'],
            'notes'             => ['nullable', 'string'],
        ]);

        $payment = $invoice->payments()->create([
            'tenant_id'         => $tenantId,
            'amount'            => $data['amount'],
            'payment_method_id' => $data['payment_method_id'] ?? null,
            'payment_type'      => $data['payment_type'] ?? 'customer_pay',
            'reference_number'  => $data['reference_number'] ?? null,
            'notes'             => $data['notes'] ?? null,
            'status'            => 'success',
            'paid_at'           => now(),
            'currency'          => 'INR',
        ]);

        $invoice->recalculate();
        $invoice->refresh();

        if ($invoice->balance_due <= 0) {
            $invoice->update(['status' => 'paid', 'paid_at' => now()]);
        } elseif ($invoice->amount_paid > 0) {
            $invoice->update(['status' => 'partially_paid']);
        }

        AuditLog::record('invoice.payment_recorded', 'invoices', $invoice->id, [], [
            'amount'  => (float) $payment->amount,
            'balance' => (float) $invoice->balance_due,
        ]);

        $this->pushPaymentAlert($request, $invoice, (float) $payment->amount);

        return response()->json([
            'success' => true,
            'data'    => [
                'payment_uuid'  => $payment->uuid,
                'amount'        => (float) $payment->amount,
                'grand_total'   => (float) $invoice->grand_total,
                'amount_paid'   => (float) $invoice->amount_paid,
                'balance_due'   => (float) $invoice->balance_due,
                'status'        => $invoice->status,
            ],
        ]);
    }

    public function updateSplitBilling(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $invoice  = Invoice::where('uuid', $uuid)->where('tenant_id', $tenantId)->firstOrFail();

        $data = $request->validate([
            'customer_pay_amount'    => ['required', 'numeric', 'min:0'],
            'insurance_claim_amount' => ['required', 'numeric', 'min:0'],
        ]);

        $splitTotal = round($data['customer_pay_amount'] + $data['insurance_claim_amount'], 2);
        $grandTotal = round((float) $invoice->grand_total, 2);

        if (abs($splitTotal - $grandTotal) > 1.0) {
            throw ValidationException::withMessages([
                'customer_pay_amount' => ['Customer + insurance amounts must equal invoice total (₹' . number_format($grandTotal, 2) . ').'],
            ]);
        }

        $invoice->update([
            'customer_pay_amount'    => $data['customer_pay_amount'],
            'insurance_claim_amount' => $data['insurance_claim_amount'],
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->formatInvoice($invoice->fresh(['customer', 'vehicle', 'items', 'payments']), true),
        ]);
    }

    public function pdf(Request $request, string $uuid): JsonResponse
    {
        $tenantId = $request->user()->tenant_id;
        $invoice  = Invoice::where('uuid', $uuid)
            ->where('tenant_id', $tenantId)
            ->firstOrFail();

        $path = "invoices/{$invoice->tenant_id}/{$invoice->uuid}.html";
        if (! $invoice->pdf_url || ! Storage::disk('public')->exists($path)) {
            GenerateInvoicePdfJob::dispatchSync($invoice->id);
            $invoice->refresh();
        }

        $url = $invoice->pdf_url;
        if (! $url && Storage::disk('public')->exists($path)) {
            $url = url(Storage::disk('public')->url($path));
            $invoice->update(['pdf_url' => $url]);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'pdf_url'        => $url,
                'invoice_number' => $invoice->invoice_number,
            ],
        ]);
    }

    private function formatInvoice(Invoice $invoice, bool $full = false): array
    {
        $base = [
            'uuid'           => $invoice->uuid,
            'invoice_number' => $invoice->invoice_number,
            'type'           => $invoice->type,
            'status'         => $invoice->status,
            'grand_total'    => (float) $invoice->grand_total,
            'balance_due'    => (float) $invoice->balance_due,
            'amount_paid'    => (float) $invoice->amount_paid,
            'issued_date'    => $invoice->issued_date?->toIso8601String(),
            'pdf_url'        => $invoice->pdf_url,
            'customer_pay_amount'    => $invoice->customer_pay_amount !== null
                ? (float) $invoice->customer_pay_amount
                : null,
            'insurance_claim_amount' => $invoice->insurance_claim_amount !== null
                ? (float) $invoice->insurance_claim_amount
                : null,
            'customer'       => $invoice->customer ? [
                'uuid'       => $invoice->customer->uuid,
                'name'       => $invoice->customer->full_name,
                'full_name'  => $invoice->customer->full_name,
                'phone'      => $invoice->customer->phone_primary,
            ] : null,
            'vehicle'        => $invoice->vehicle ? [
                'registration_number' => $invoice->vehicle->registration_number,
                'make'                => $invoice->vehicle->maker,
                'model'               => $invoice->vehicle->model,
                'year'                => $invoice->vehicle->year ? (int) $invoice->vehicle->year : null,
            ] : null,
        ];

        if ($full) {
            $base['subtotal']      = (float) $invoice->subtotal;
            $base['tax_total']     = (float) $invoice->tax_total;
            $base['discount_total'] = (float) $invoice->discount_total;
            $base['due_date']      = $invoice->due_date?->format('Y-m-d');
            $base['customer_notes'] = $invoice->customer_notes;
            $base['service_job']    = $invoice->job ? [
                'uuid'       => $invoice->job->uuid,
                'job_number' => $invoice->job->job_number,
            ] : null;
            $base['items']         = $invoice->items->map(fn ($i) => [
                'line_type'    => $i->line_type,
                'name'         => $i->name,
                'description'  => $i->name,
                'quantity'     => (float) $i->quantity,
                'unit_price'   => (float) $i->unit_price,
                'tax_amount'   => (float) $i->tax_amount,
                'total_amount' => (float) $i->total_amount,
            ]);
            $base['payments']      = $invoice->payments->map(fn ($p) => [
                'amount'    => (float) $p->amount,
                'status'    => $p->status,
                'paid_at'   => $p->paid_at?->toIso8601String(),
                'method'    => $p->paymentMethod?->name,
                'payment_type' => $p->payment_type,
            ]);
        }

        return $base;
    }

    private function pushPaymentAlert(Request $request, Invoice $invoice, float $amount): void
    {
        $tenantId = $request->user()->tenant_id;
        $invoice->loadMissing('customer', 'job');

        dispatch(function () use ($tenantId, $invoice, $amount, $request) {
            $push = app(PushNotificationService::class);
            $title = "Payment received — {$invoice->invoice_number}";
            $body  = '₹' . number_format($amount, 2) . ' recorded'
                . ($invoice->customer ? ' · ' . $invoice->customer->full_name : '');

            $data = [
                'type'         => 'invoice',
                'invoice_uuid' => $invoice->uuid,
            ];
            if ($invoice->job) {
                $data['job_uuid'] = $invoice->job->uuid;
            }

            $push->notifyTenantStaff(
                $tenantId,
                'payment_received',
                $title,
                $body,
                $data,
                $request->user()->id,
            );
        })->afterResponse();
    }
}
