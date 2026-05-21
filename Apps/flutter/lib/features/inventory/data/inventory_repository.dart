import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/inventory_models.dart';

class InventoryRepository {
  final Dio _dio;

  const InventoryRepository(this._dio);

  /// GET /api/inventory — paginated, filterable list.
  Future<PaginatedInventory> fetchItems({
    int page = 1,
    String? search,
    int? categoryId,
    bool lowStockOnly = false,
  }) async {
    final response = await _dio.get(
      '/inventory',
      queryParameters: {
        'page': page,
        'per_page': 20,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (lowStockOnly) 'low_stock': true,
      },
    );
    return PaginatedInventory.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/inventory/{uuid} — full detail with recent adjustments.
  Future<InventoryDetail> fetchItem(String uuid) async {
    final response = await _dio.get('/inventory/$uuid');
    return InventoryDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /inventory — create a new part.
  Future<InventoryItem> createItem(Map<String, dynamic> body) async {
    final response = await _dio.post('/inventory', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return InventoryItem.fromJson({
      ...data,
      'unit_of_measure': body['unit_of_measure'],
      'stock_on_hand': body['stock_on_hand'],
      'low_stock_threshold': body['low_stock_threshold'],
      'cost_price': body['cost_price'],
      'selling_price': body['selling_price'],
    });
  }

  /// PATCH /inventory/{uuid}/stock — adjust stock.
  Future<int> adjustStock(
    String uuid,
    AddStockAdjustmentRequest request, {
    int currentStock = 0,
  }) async {
    int adjustment;
    switch (request.type) {
      case 'add':
        adjustment = request.quantity;
      case 'remove':
        adjustment = -request.quantity;
      case 'set':
        adjustment = request.quantity - currentStock;
      default:
        adjustment = request.quantity;
    }
    final response = await _dio.patch(
      '/inventory/$uuid/stock',
      data: {
        'adjustment': adjustment,
        'reason': request.reason,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return (data['stock_on_hand'] as num?)?.toInt() ?? currentStock + adjustment;
  }

  /// GET /api/parts-categories — list all categories.
  Future<List<PartsCategory>> fetchCategories() async {
    final response = await _dio.get('/parts-categories');
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => PartsCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(apiClientProvider));
});
