<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Meta WhatsApp Cloud API Configuration
    |--------------------------------------------------------------------------
    */

    'token'               => env('WHATSAPP_TOKEN'),
    'phone_number_id'     => env('WHATSAPP_PHONE_NUMBER_ID'),
    'business_account_id' => env('WHATSAPP_BUSINESS_ACCOUNT_ID'),
    'api_version'         => env('WHATSAPP_API_VERSION', 'v20.0'),
    'template_language'   => env('WHATSAPP_TEMPLATE_LANGUAGE', 'en'),

    'templates' => [
        'otp'              => env('WHATSAPP_OTP_TEMPLATE', 'pro_garage_otp'),
        'job_status'       => env('WHATSAPP_JOB_STATUS_TEMPLATE', 'job_status_update'),
        'invoice_ready'    => env('WHATSAPP_INVOICE_TEMPLATE', 'invoice_ready'),
        'appointment'      => env('WHATSAPP_APPOINTMENT_TEMPLATE', 'appointment_reminder'),
        'payment_receipt'  => env('WHATSAPP_RECEIPT_TEMPLATE', 'payment_receipt'),
    ],

    'base_url' => 'https://graph.facebook.com',
];
