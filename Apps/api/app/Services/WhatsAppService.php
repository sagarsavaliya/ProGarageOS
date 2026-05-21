<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsAppService
{
    /**
     * Send OTP to a customer via WhatsApp authentication template.
     */
    public function sendOtp(string $phone, string $otp, ?int $tenantId = null): bool
    {
        $config   = WhatsAppConfigResolver::resolve($tenantId);
        $template = $config['templates']['otp'] ?? 'pro_garage_otp';
        $language = $config['template_language'] ?? 'en';

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

        return $this->sendMessage($payload, "OTP to {$phone}", $config);
    }

    public function sendJobStatusUpdate(
        string $phone,
        string $customerName,
        string $jobNumber,
        string $status,
        string $vehicleInfo,
        ?int $tenantId = null
    ): bool {
        $config   = WhatsAppConfigResolver::resolve($tenantId);
        $template = $config['templates']['job_status'] ?? 'job_status_update';

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => $config['template_language'] ?? 'en'],
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

        return $this->sendMessage($payload, "Job status update to {$phone}", $config);
    }

    public function sendInvoiceReady(
        string $phone,
        string $customerName,
        string $invoiceNumber,
        string $amount,
        ?string $pdfUrl = null,
        ?int $tenantId = null
    ): bool {
        $config   = WhatsAppConfigResolver::resolve($tenantId);
        $template = $config['templates']['invoice_ready'] ?? 'invoice_ready';

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
                'language'   => ['code' => $config['template_language'] ?? 'en'],
                'components' => $components,
            ],
        ];

        return $this->sendMessage($payload, "Invoice ready to {$phone}", $config);
    }

    public function sendPaymentReceipt(
        string $phone,
        string $customerName,
        string $amount,
        string $method,
        string $invoiceNumber,
        ?int $tenantId = null
    ): bool {
        $config   = WhatsAppConfigResolver::resolve($tenantId);
        $template = $config['templates']['payment_receipt'] ?? 'payment_receipt';

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => $config['template_language'] ?? 'en'],
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

        return $this->sendMessage($payload, "Payment receipt to {$phone}", $config);
    }

    public function sendAppointmentReminder(
        string $phone,
        string $customerName,
        string $date,
        string $time,
        string $vehicleInfo,
        ?int $tenantId = null
    ): bool {
        $config   = WhatsAppConfigResolver::resolve($tenantId);
        $template = $config['templates']['appointment'] ?? 'appointment_reminder';

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $this->normalizePhone($phone),
            'type'              => 'template',
            'template'          => [
                'name'       => $template,
                'language'   => ['code' => $config['template_language'] ?? 'en'],
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

        return $this->sendMessage($payload, "Appointment reminder to {$phone}", $config);
    }

    /**
     * Verify credentials by fetching phone number metadata from Meta.
     */
    public function testConnection(?int $tenantId = null): array
    {
        $config = WhatsAppConfigResolver::resolve($tenantId);

        if (empty($config['token']) || empty($config['phone_number_id'])) {
            return ['ok' => false, 'message' => 'WhatsApp credentials are incomplete.'];
        }

        try {
            $url      = "{$config['base_url']}/{$config['api_version']}/{$config['phone_number_id']}";
            $response = Http::withToken($config['token'])->timeout(10)->get($url);

            if ($response->successful()) {
                return [
                    'ok'      => true,
                    'message' => 'WhatsApp connection successful.',
                    'source'  => $config['source'],
                ];
            }

            return [
                'ok'      => false,
                'message' => $response->json('error.message') ?? 'Meta API rejected the credentials.',
            ];
        } catch (\Exception $e) {
            return ['ok' => false, 'message' => 'Could not reach Meta WhatsApp API.'];
        }
    }

    private function sendMessage(array $payload, string $context, array $config): bool
    {
        if (empty($config['token']) || empty($config['phone_number_id'])) {
            Log::warning("WhatsApp skipped — not configured ({$context})");
            return false;
        }

        $url = "{$config['base_url']}/{$config['api_version']}/{$config['phone_number_id']}/messages";

        try {
            $response = Http::withToken($config['token'])
                ->timeout(10)
                ->post($url, $payload);

            if ($response->successful()) {
                Log::info("WhatsApp message sent: {$context}", [
                    'message_id' => $response->json('messages.0.id'),
                    'source'     => $config['source'] ?? 'platform',
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

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone);

        if (strlen($digits) >= 12) {
            return '+' . $digits;
        }

        if (strlen($digits) === 10) {
            return '+91' . $digits;
        }

        return '+' . $digits;
    }
}
