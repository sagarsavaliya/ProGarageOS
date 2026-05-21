import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/inventory_repository.dart';
import '../../data/models/inventory_models.dart';

class CreateInventoryState {
  final bool isSubmitting;
  final String? errorMessage;
  final InventoryItem? created;

  const CreateInventoryState({
    this.isSubmitting = false,
    this.errorMessage,
    this.created,
  });

  CreateInventoryState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    InventoryItem? created,
  }) {
    return CreateInventoryState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      created: created ?? this.created,
    );
  }
}

class CreateInventoryNotifier extends StateNotifier<CreateInventoryState> {
  final InventoryRepository _repo;

  CreateInventoryNotifier(this._repo) : super(const CreateInventoryState());

  Future<InventoryItem?> submit({
    required String sku,
    required String name,
    String? brand,
    required String unit,
    required double costPrice,
    required double sellingPrice,
    required int stockOnHand,
    required int lowStockThreshold,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final item = await _repo.createItem({
        'sku': sku.trim(),
        'name': name.trim(),
        if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
        'unit_of_measure': unit,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_on_hand': stockOnHand,
        'low_stock_threshold': lowStockThreshold,
        'reorder_quantity': lowStockThreshold > 0 ? lowStockThreshold : 1,
      });
      state = state.copyWith(isSubmitting: false, created: item);
      return item;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.response?.statusCode == 422
            ? 'Check SKU and required fields.'
            : 'Could not save part. Check connection.',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not save part. Try again.',
      );
      return null;
    }
  }
}

final createInventoryProvider =
    StateNotifierProvider.autoDispose<CreateInventoryNotifier, CreateInventoryState>((ref) {
  return CreateInventoryNotifier(ref.watch(inventoryRepositoryProvider));
});
