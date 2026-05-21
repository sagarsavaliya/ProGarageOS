import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/auth_models.dart';

/// Repository for all authentication API calls.
class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  const AuthRepository({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  /// POST /auth/staff/login — PIN-based staff authentication.
  Future<StaffAuthResponse> loginStaff(StaffLoginRequest request) async {
    final response = await _dio.post(
      '/auth/staff/login',
      data: request.toJson(),
    );
    return StaffAuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /auth/me — current staff profile.
  Future<UserModel> fetchMe() async {
    final response = await _dio.get('/auth/me');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final roles = userJson['roles'] as List<dynamic>?;
    final role = userJson['role'] as String? ??
        (roles != null && roles.isNotEmpty ? roles.first as String : 'technician');
    return UserModel.fromJson({
      ...userJson,
      'role': role,
      if (roles != null) 'roles': roles,
    });
  }

  /// POST /auth/logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignore API errors on logout — always clear local state.
    }
    await _storage.clearAll();
  }

  /// POST /auth/customer/otp/request
  /// Returns the Retry-After seconds from the response header (default 30).
  Future<int> requestOtp(String phone) async {
    final response = await _dio.post(
      '/auth/customer/otp/request',
      data: {'phone': phone},
    );
    final retryAfterHeader = response.headers.value('Retry-After');
    final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '') ?? 30;
    return retryAfterSeconds;
  }

  /// POST /auth/customer/otp/verify
  Future<StaffAuthResponse> verifyOtp(OtpVerifyRequest request) async {
    final response = await _dio.post(
      '/auth/customer/otp/verify',
      data: request.toJson(),
    );
    return StaffAuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/staff/pin-otp/request
  Future<String> requestStaffPinOtp(StaffPinOtpRequest request) async {
    final response = await _dio.post(
      '/auth/staff/pin-otp/request',
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    return inner['phone_masked'] as String? ?? '';
  }

  /// POST /auth/staff/pin-otp/reset
  Future<void> resetStaffPin(StaffPinResetRequest request) async {
    await _dio.post(
      '/auth/staff/pin-otp/reset',
      data: request.toJson(),
    );
  }
}

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});
