class WhatsAppIntegrationModel {
  final bool enabled;
  final bool usePlatformDefault;
  final bool platformConfigured;
  final String? phoneNumberId;
  final String? businessAccountId;
  final bool tokenSet;
  final String? tokenPreview;
  final String otpTemplate;
  final String templateLanguage;
  final String apiVersion;
  final String? lastTestedAt;

  const WhatsAppIntegrationModel({
    required this.enabled,
    required this.usePlatformDefault,
    required this.platformConfigured,
    this.phoneNumberId,
    this.businessAccountId,
    required this.tokenSet,
    this.tokenPreview,
    required this.otpTemplate,
    required this.templateLanguage,
    required this.apiVersion,
    this.lastTestedAt,
  });

  factory WhatsAppIntegrationModel.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    return WhatsAppIntegrationModel(
      enabled: json['enabled'] as bool? ?? false,
      usePlatformDefault: json['use_platform_default'] as bool? ?? true,
      platformConfigured: json['platform_configured'] as bool? ?? false,
      phoneNumberId: json['phone_number_id'] as String?,
      businessAccountId: json['business_account_id'] as String?,
      tokenSet: json['token_set'] as bool? ?? false,
      tokenPreview: json['token_preview'] as String?,
      otpTemplate: settings['otp_template'] as String? ?? 'pro_garage_otp',
      templateLanguage: settings['template_language'] as String? ?? 'en',
      apiVersion: settings['api_version'] as String? ?? 'v20.0',
      lastTestedAt: json['last_tested_at'] as String?,
    );
  }
}
