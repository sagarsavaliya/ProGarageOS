import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../presentation/providers/create_job_provider.dart' show BayOption, ServiceCategoryOption, TechnicianOption;

class GarageResourcesRepository {
  final Dio _dio;

  const GarageResourcesRepository(this._dio);

  Future<List<BayOption>> fetchBays() async {
    final response = await _dio.get('/service-bays');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return BayOption(
        uuid: m['uuid'] as String? ?? '',
        name: m['name'] as String? ?? 'Bay',
        type: m['bay_type'] as String? ?? 'general',
        status: m['status'] as String? ?? 'available',
      );
    }).toList();
  }

  Future<List<ServiceCategoryOption>> fetchServiceCategories() async {
    final response = await _dio.get('/service-categories');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final durationMin = (m['default_duration_min'] as num?)?.toInt() ?? 60;
      final name = m['name'] as String? ?? 'Service';
      final code = m['code'] as String? ?? name;
      return ServiceCategoryOption(
        uuid: m['uuid'] as String? ?? '',
        name: name,
        durationLabel: durationMin >= 60 ? '~${(durationMin / 60).round()} hrs' : '~$durationMin min',
        iconLabel: _iconLabelFor(code, name),
        requiresInspection: m['requires_intake_inspection'] as bool? ?? false,
        requiresApproval: m['requires_approval'] as bool? ?? false,
      );
    }).toList();
  }

  static String _iconLabelFor(String code, String name) {
    final key = code.toUpperCase();
    if (key.length >= 2) return key.substring(0, 2);
    return name.isNotEmpty ? name.substring(0, name.length.clamp(1, 2)).toUpperCase() : 'SV';
  }

  Future<List<TechnicianOption>> fetchTechnicians() async {
    final response = await _dio.get('/staff/technicians');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final open = (m['open_jobs'] as num?)?.toInt() ?? 0;
      return TechnicianOption(
        uuid: m['uuid'] as String? ?? '',
        name: m['name'] as String? ?? 'Technician',
        specialty: '${m['specialty'] ?? 'Technician'} · $open open',
        isAvailable: m['is_available'] as bool? ?? true,
      );
    }).toList();
  }
}

final garageResourcesRepositoryProvider = Provider<GarageResourcesRepository>((ref) {
  return GarageResourcesRepository(ref.watch(apiClientProvider));
});
