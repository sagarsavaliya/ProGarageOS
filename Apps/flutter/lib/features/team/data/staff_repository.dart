import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/staff_models.dart';

class StaffRepository {
  final Dio _dio;

  const StaffRepository(this._dio);

  Future<List<StaffMember>> listStaff() async {
    final response = await _dio.get('/staff');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return list.map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StaffMember> showStaff(String uuid) async {
    final response = await _dio.get('/staff/$uuid');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return StaffMember.fromJson(data);
  }

  Future<StaffMember> createStaff({
    required String firstName,
    String? lastName,
    required String phone,
    String? email,
    required String role,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/staff',
      data: {
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'role': role,
        'pin': pin,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return StaffMember.fromJson(data);
  }

  Future<StaffMember> updateStaff(String uuid, Map<String, dynamic> body) async {
    final response = await _dio.patch('/staff/$uuid', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return StaffMember.fromJson(data);
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(apiClientProvider));
});
