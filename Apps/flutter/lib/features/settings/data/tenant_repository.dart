import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class TenantProfile {
  final String uuid;
  final String businessName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstNumber;
  final String currency;
  final String timezone;
  final String setupStep;
  final int? setupBayCount;
  final DateTime? setupCompletedAt;

  const TenantProfile({
    required this.uuid,
    required this.businessName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstNumber,
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.setupStep = 'welcome',
    this.setupBayCount,
    this.setupCompletedAt,
  });

  bool get isSetupComplete => setupCompletedAt != null;

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['setup_completed_at'] as String?;
    return TenantProfile(
      uuid: json['uuid'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      gstNumber: json['gst_number'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      setupStep: json['setup_step'] as String? ?? 'welcome',
      setupBayCount: (json['setup_bay_count'] as num?)?.toInt(),
      setupCompletedAt:
          completedRaw != null ? DateTime.tryParse(completedRaw) : null,
    );
  }
}

class TenantRepository {
  final Dio _dio;

  const TenantRepository({required Dio dio}) : _dio = dio;

  Future<TenantProfile> fetchProfile() async {
    final response = await _dio.get('/tenant/profile');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return TenantProfile.fromJson(data);
  }

  Future<TenantProfile> updateProfile({
    String? businessName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstNumber,
  }) async {
    final response = await _dio.put(
      '/tenant/profile',
      data: {
        if (businessName != null) 'business_name': businessName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (gstNumber != null) 'gst_number': gstNumber,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return TenantProfile.fromJson(data);
  }

  Future<TenantProfile> updateSetup({
    String? setupStep,
    int? setupBayCount,
    bool complete = false,
  }) async {
    final response = await _dio.patch(
      '/tenant/setup',
      data: {
        if (setupStep != null) 'setup_step': setupStep,
        if (setupBayCount != null) 'setup_bay_count': setupBayCount,
        if (complete) 'complete': true,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return TenantProfile.fromJson(data);
  }
}

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(dio: ref.watch(apiClientProvider));
});

final tenantProfileProvider = FutureProvider.autoDispose<TenantProfile>((ref) async {
  return ref.watch(tenantRepositoryProvider).fetchProfile();
});

/// Server-first check whether owner setup is finished (falls back to local cache).
Future<bool> resolveGarageSetupComplete({
  required TenantRepository tenantRepo,
  required SecureStorageService storage,
  required String tenantUuid,
}) async {
  try {
    final profile = await tenantRepo.fetchProfile();
    await storage.setGarageSetupCompleted(tenantUuid, profile.isSetupComplete);
    return profile.isSetupComplete;
  } catch (_) {
    return storage.isGarageSetupCompleted(tenantUuid);
  }
}
