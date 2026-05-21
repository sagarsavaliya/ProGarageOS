<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\TenantIntegration;
use App\Services\WhatsAppConfigResolver;
use App\Services\WhatsAppService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IntegrationController extends Controller
{
    public function showWhatsApp(Request $request): JsonResponse
    {
        $this->ensureOwner($request);

        $tenantId    = $request->user()->tenant_id;
        $integration = TenantIntegration::firstOrNew([
            'tenant_id' => $tenantId,
            'provider'  => 'whatsapp',
        ]);

        $platformConfigured = WhatsAppConfigResolver::isConfigured(null);
        $usingPlatform      = !$integration->exists || !$integration->enabled || empty($integration->credentials['token']);

        return response()->json([
            'success' => true,
            'data'    => [
                'enabled'              => (bool) $integration->enabled,
                'use_platform_default' => $usingPlatform,
                'platform_configured'  => $platformConfigured,
                'phone_number_id'      => $this->mask($integration->credentials['phone_number_id'] ?? null),
                'business_account_id'  => $this->mask($integration->credentials['business_account_id'] ?? null),
                'token_set'            => !empty($integration->credentials['token']),
                'token_preview'        => $this->maskToken($integration->credentials['token'] ?? null),
                'settings'             => [
                    'otp_template'        => $integration->settings['templates']['otp'] ?? config('whatsapp.templates.otp'),
                    'template_language'   => $integration->settings['template_language'] ?? config('whatsapp.template_language', 'en'),
                    'api_version'         => $integration->settings['api_version'] ?? config('whatsapp.api_version', 'v20.0'),
                ],
                'last_tested_at'       => $integration->last_tested_at?->toIso8601String(),
            ],
        ]);
    }

    public function updateWhatsApp(Request $request): JsonResponse
    {
        $this->ensureOwner($request);

        $data = $request->validate([
            'enabled'              => ['sometimes', 'boolean'],
            'use_platform_default' => ['sometimes', 'boolean'],
            'token'                => ['nullable', 'string'],
            'phone_number_id'      => ['nullable', 'string', 'max:50'],
            'business_account_id'  => ['nullable', 'string', 'max:50'],
            'otp_template'         => ['nullable', 'string', 'max:100'],
            'template_language'    => ['nullable', 'string', 'max:10'],
            'api_version'          => ['nullable', 'string', 'max:10'],
        ]);

        $tenantId = $request->user()->tenant_id;
        $integration = TenantIntegration::firstOrNew([
            'tenant_id' => $tenantId,
            'provider'  => 'whatsapp',
        ]);

        $credentials = $integration->credentials ?? [];

        if (!empty($data['use_platform_default'])) {
            $integration->enabled     = false;
            $integration->credentials = null;
        } else {
            $integration->enabled = $data['enabled'] ?? true;

            if (!empty($data['token'])) {
                $credentials['token'] = $data['token'];
            }
            if (array_key_exists('phone_number_id', $data) && $data['phone_number_id'] !== null) {
                $credentials['phone_number_id'] = $data['phone_number_id'];
            }
            if (array_key_exists('business_account_id', $data) && $data['business_account_id'] !== null) {
                $credentials['business_account_id'] = $data['business_account_id'];
            }

            $integration->credentials = $credentials;
        }

        $settings = $integration->settings ?? [];
        if (!empty($data['otp_template'])) {
            $settings['templates']['otp'] = $data['otp_template'];
        }
        if (!empty($data['template_language'])) {
            $settings['template_language'] = $data['template_language'];
        }
        if (!empty($data['api_version'])) {
            $settings['api_version'] = $data['api_version'];
        }
        $integration->settings = $settings;
        $integration->save();

        AuditLog::record('integration.whatsapp.updated', 'tenant_integrations', $integration->id);

        return $this->showWhatsApp($request);
    }

    public function testWhatsApp(Request $request, WhatsAppService $whatsapp): JsonResponse
    {
        $this->ensureOwner($request);

        $tenantId = $request->user()->tenant_id;
        $result   = $whatsapp->testConnection($tenantId);

        if ($result['ok']) {
            TenantIntegration::where('tenant_id', $tenantId)
                ->where('provider', 'whatsapp')
                ->update(['last_tested_at' => now()]);
        }

        return response()->json([
            'success' => $result['ok'],
            'data'    => $result,
        ], $result['ok'] ? 200 : 422);
    }

    private function ensureOwner(Request $request): void
    {
        if ($request->user()->role !== 'owner') {
            abort(response()->json([
                'success' => false,
                'error'   => ['code' => 'FORBIDDEN', 'message' => 'Only the garage owner can manage integrations.'],
            ], 403));
        }
    }

    private function mask(?string $value): ?string
    {
        if (!$value || strlen($value) < 4) {
            return $value;
        }

        return str_repeat('•', max(0, strlen($value) - 4)) . substr($value, -4);
    }

    private function maskToken(?string $token): ?string
    {
        if (!$token) {
            return null;
        }

        return '••••' . substr($token, -6);
    }
}
