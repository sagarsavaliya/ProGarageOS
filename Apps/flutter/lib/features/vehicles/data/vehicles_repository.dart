import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/fleet_models.dart';

class VehiclesRepository {
  final Dio _dio;

  const VehiclesRepository(this._dio);

  Future<PaginatedFleetVehicles> fetchVehicles({
    int page = 1,
    String? search,
  }) async {
    final response = await _dio.get(
      '/vehicles',
      queryParameters: {
        'page': page,
        'per_page': 25,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedFleetVehicles.fromJson(response.data as Map<String, dynamic>);
  }
}

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return VehiclesRepository(ref.watch(apiClientProvider));
});
