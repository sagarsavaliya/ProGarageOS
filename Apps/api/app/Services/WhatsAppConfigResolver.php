<?php

namespace App\Services;

use App\Models\TenantIntegration;

class WhatsAppConfigResolver
{
    public static function resolve(?int $tenantId = null): array
    {
        $integration = TenantIntegration::whatsappForTenant($tenantId);

        if ($integration && !empty($integration->credentials['token'])) {
            $settings = $integration->settings ?? [];

            return [
                'source'              => 'tenant',
                'token'               => $integration->credentials['token'],
                'phone_number_id'     => $integration->credentials['phone_number_id'] ?? '',
                'business_account_id' => $integration->credentials['business_account_id'] ?? '',
                'api_version'         => $settings['api_version'] ?? config('whatsapp.api_version', 'v20.0'),
                'template_language'   => $settings['template_language'] ?? config('whatsapp.template_language', 'en'),
                'templates'           => array_merge(config('whatsapp.templates', []), $settings['templates'] ?? []),
                'base_url'            => config('whatsapp.base_url', 'https://graph.facebook.com'),
            ];
        }

        return [
            'source'              => 'platform',
            'token'               => config('whatsapp.token'),
            'phone_number_id'     => config('whatsapp.phone_number_id'),
            'business_account_id' => config('whatsapp.business_account_id'),
            'api_version'         => config('whatsapp.api_version', 'v20.0'),
            'template_language'   => config('whatsapp.template_language', 'en'),
            'templates'           => config('whatsapp.templates', []),
            'base_url'            => config('whatsapp.base_url', 'https://graph.facebook.com'),
        ];
    }

    public static function isConfigured(?int $tenantId = null): bool
    {
        $config = self::resolve($tenantId);

        return !empty($config['token']) && !empty($config['phone_number_id']);
    }
}
