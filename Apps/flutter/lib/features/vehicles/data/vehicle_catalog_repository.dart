import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/vehicle_catalog_models.dart';

class VehicleCatalogRepository {
  final Dio _dio;

  const VehicleCatalogRepository(this._dio);

  Future<List<CatalogOption>> searchMakes({String query = '', int? year}) async {
    return _fetch('/vehicle-catalog/makes', {
      if (query.isNotEmpty) 'q': query,
      if (year != null) 'year': year,
      'limit': 20,
    });
  }

  Future<List<CatalogOption>> searchModels({
    required String makeUuid,
    String query = '',
    int? year,
  }) async {
    return _fetch('/vehicle-catalog/models', {
      'make_uuid': makeUuid,
      if (query.isNotEmpty) 'q': query,
      if (year != null) 'year': year,
      'limit': 20,
    });
  }

  Future<List<CatalogOption>> searchVariants({
    required String modelUuid,
    String query = '',
    int? year,
  }) async {
    return _fetch('/vehicle-catalog/variants', {
      'model_uuid': modelUuid,
      if (query.isNotEmpty) 'q': query,
      if (year != null) 'year': year,
      'limit': 20,
    });
  }

  Future<List<CatalogOption>> searchColors({
    String query = '',
    String? variantUuid,
  }) async {
    return _fetch('/vehicle-catalog/colors', {
      if (query.isNotEmpty) 'q': query,
      if (variantUuid != null && variantUuid.isNotEmpty) 'variant_uuid': variantUuid,
      'limit': 20,
    });
  }

  Future<List<CatalogOption>> _fetch(String path, Map<String, dynamic> query) async {
    final response = await _dio.get(path, queryParameters: query);
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => CatalogOption.fromJson(item as Map<String, dynamic>))
        .where((item) => item.uuid.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }
}

final vehicleCatalogRepositoryProvider = Provider<VehicleCatalogRepository>((ref) {
  return VehicleCatalogRepository(ref.watch(apiClientProvider));
});
