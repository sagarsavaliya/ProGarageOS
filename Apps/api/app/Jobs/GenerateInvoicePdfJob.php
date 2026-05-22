<?php

namespace App\Jobs;

use App\Models\Invoice;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

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

        $path = "invoices/{$invoice->tenant_id}/{$invoice->uuid}.html";
        Storage::disk('public')->put($path, $html);

        $relativeUrl = Storage::disk('public')->url($path);
        $invoice->update(['pdf_url' => url($relativeUrl)]);
    }
}
