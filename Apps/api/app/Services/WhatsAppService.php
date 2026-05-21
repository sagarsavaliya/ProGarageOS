<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsAppService
{
    private string $baseUrl;
    private string $token;
    private string $phoneNumberId;
    private string $apiVersion;

    public function __construct()
    {
        $this->token         = config('whatsapp.token');
        $this->phoneNumberId = config('whatsapp.phone_number_id');
        $this->apiVersion    = config('whatsapp.api_version', 'v20.0');
        $this->baseUrl       = config('whatsapp.base_url', 'https://graph.facebook.com');
    }

    /**
     * Send OTP to a customer via WhatsApp authentication template.
     *
     * The template must be of category "Authentication" on Meta Business Manager.
     * It receives one body parameter (the OTP code) and optionally a copy-code button.
     */
    public function sendOtp(string $phone, string $otp): bool
    {
        $template = config('whatsapp.templates.otp', 'pro_garage_otp');
        $language = config('whatsapp.template_language', 'en');

        // Authentication templates send OTP in both body and button (copy-code)
        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => $language],
                'components' => [
                    [
                        'type'       => 'body',
                        'parameters' => [
                            ['type' => 'text', 'text' => $otp],
                        ],
                    ],
                    [
                        'type'       => 'button',
                        'sub_type'   => 'url',
                        'index'      => '0',
                        'parameters' => [
                            ['type' => 'text', 'text' => $otp],
                        ],
                    ],
                ],
            ],
        ];

        return $this->sendMessage($payload, "OTP to {$phone}");
    }

    /**
     * Send a job status update notification.
     */
    public function sendJobStatusUpdate(string $phone, string $customerName, string $jobNumber, string $status, string $vehicleInfo): bool
    {
        $template = config('whatsapp.templates.job_status', 'job_status_update');

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => config('whatsapp.template_language', 'en')],
                'components' => [
                    [
                        'type'       => 'body',
                        'parameters' => [
                            ['type' => 'text', 'text' => $customerName],
                            ['type' => 'text', 'text' => $jobNumber],
                            ['type' => 'text', 'text' => $status],
                            ['type' => 'text', 'text' => $vehicleInfo],
                        ],
                    ],
                ],
            ],
        ];

        return $this->sendMessage($payload, "Job status update to {$phone}");
    }

    /**
     * Send an invoice ready notification with PDF link.
     */
    public function sendInvoiceReady(string $phone, string $customerName, string $invoiceNumber, string $amount, string $pdfUrl = null): bool
    {
        $template = config('whatsapp.templates.invoice_ready', 'invoice_ready');

        $components = [
            [
                'type'       => 'body',
                'parameters' => [
                    ['type' => 'text', 'text' => $customerName],
                    ['type' => 'text', 'text' => $invoiceNumber],
                    ['type' => 'text', 'text' => $amount],
                ],
            ],
        ];

        // Attach PDF as document header if URL provided
        if ($pdfUrl) {
            array_unshift($components, [
                'type'       => 'header',
                'parameters' => [
                    [
                        'type'     => 'document',
                        'document' => [
                            'link'     => $pdfUrl,
                            'filename' => "Invoice-{$invoiceNumber}.pdf",
                        ],
                    ],
                ],
            ]);
        }

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => config('whatsapp.template_language', 'en')],
                'components' => $components,
            ],
        ];

        return $this->sendMessage($payload, "Invoice ready to {$phone}");
    }

    /**
     * Send a payment receipt notification.
     */
    public function sendPaymentReceipt(string $phone, string $customerName, string $amount, string $method, string $invoiceNumber): bool
    {
        $template = config('whatsapp.templates.payment_receipt', 'payment_receipt');

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => config('whatsapp.template_language', 'en')],
                'components' => [
                    [
                        'type'       => 'body',
                        'parameters' => [
                            ['type' => 'text', 'text' => $customerName],
                            ['type' => 'text', 'text' => $amount],
                            ['type' => 'text', 'text' => $method],
                            ['type' => 'text', 'text' => $invoiceNumber],
                        ],
                    ],
                ],
            ],
        ];

        return $this->sendMessage($payload, "Payment receipt to {$phone}");
    }

    /**
     * Send an appointment reminder.
     */
    public function sendAppointmentReminder(string $phone, string $customerName, string $date, string $time, string $vehicleInfo): bool
    {
        $template = config('whatsapp.templates.appointment', 'appointment_reminder');

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => config('whatsapp.template_language', 'en')],
                'components' => [
                    [
                        'type'       => 'body',
                        'parameters' => [
                            ['type' => 'text', 'text' => $customerName],
                            ['type' => 'text', 'text' => $date],
                            ['type' => 'text', 'text' => $time],
                            ['type' => 'text', 'text' => $vehicleInfo],
                        ],
                    ],
                ],
            ],
        ];

        return $this->sendMessage($payload, "Appointment reminder to {$phone}");
    }

    /**
     * Core send method — posts to Meta Cloud API.
     */
    private function sendMessage(array $payload, string $context = ''): bool
    {
        $url = "{$this->baseUrl}/{$this->apiVersion}/{$this->phoneNumberId}/messages";

        try {
            $response = Http::withToken($this->token)
                ->timeout(10)
                ->post($url, $payload);

            if ($response->successful()) {
                Log::info("WhatsApp message sent: {$context}", [
                    'message_id' => $response->json('messages.0.id'),
                ]);
                return true;
            }

            Log::error("WhatsApp API error: {$context}", [
                'status'   => $response->status(),
                'response' => $response->json(),
            ]);
            return false;

        } catch (\Exception $e) {
            Log::error("WhatsApp send failed: {$context}", [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Normalize phone to E.164 format (India default +91).
     */
    private function normalizePhone(string $phone): string
    {
        // Strip all non-digits
        $digits = preg_replace('/\D/', '', $phone);

        // Already has country code (12+ digits)
        if (strlen($digits) >= 12) {
            return '+' . $digits;
        }

        // Indian 10-digit number — prepend +91
        if (strlen($digits) === 10) {
            return '+91' . $digits;
        }

        // Return as-is with + prefix
        return '+' . $digits;
    }
}
