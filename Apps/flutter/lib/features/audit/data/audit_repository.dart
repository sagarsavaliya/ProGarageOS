import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/audit_models.dart';

class AuditRepository {
  final Dio _dio;

  const AuditRepository(this._dio);

  Future<List<AuditLogEntry>> fetchJobAudit(String jobUuid) async {
    final response = await _dio.get(
      '/audit-logs',
      queryParameters: {
        'job_uuid': jobUuid,
        'per_page': 20,
      },
    );
    return PaginatedAuditLogs.fromJson(response.data as Map<String, dynamic>).data;
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(apiClientProvider));
});
