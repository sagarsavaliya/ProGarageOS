<?php

namespace App\Jobs;

use App\Models\Invoice;
use App\Services\TenantStorageService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateInvoicePdfJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $invoiceId,
    ) {}

    public function handle(): void
    {
        $invoice = Invoice::with(['customer', 'vehicle', 'items', 'tenant', 'payments.paymentMethod', 'job'])
            ->find($this->invoiceId);

        if (! $invoice) {
            return;
        }

        $html = view('pdf.invoice', [
            'invoice' => $invoice,
            'tenant'  => $invoice->tenant,
        ])->render();

        $storage = app(TenantStorageService::class);
        $path = $storage->invoicePath($invoice->tenant_id, $invoice->uuid);
        $storage->put($path, $html);

        $invoice->update(['pdf_url' => $storage->publicUrl($path)]);
    }
}
