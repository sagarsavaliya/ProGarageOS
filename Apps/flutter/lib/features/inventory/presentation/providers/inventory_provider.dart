import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/inventory_repository.dart';
import '../../data/models/inventory_models.dart';

// ---------------------------------------------------------------------------
// InventoryState
// ---------------------------------------------------------------------------

class InventoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<InventoryItem> items;
  final String? errorMessage;
  final String searchQuery;
  final int? selectedCategoryId;
  final bool showLowStockOnly;
  final bool hasMore;
  final int currentPage;

  const InventoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.items = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.showLowStockOnly = false,
    this.hasMore = false,
    this.currentPage = 1,
  });

  InventoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<InventoryItem>? items,
    Object? errorMessage = _sentinel,
    String? searchQuery,
    Object? selectedCategoryId = _sentinel,
    bool? showLowStockOnly,
    bool? hasMore,
    int? currentPage,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      items: items ?? this.items,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId == _sentinel
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      showLowStockOnly: showLowStockOnly ?? this.showLowStockOnly,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// InventoryNotifier
// ---------------------------------------------------------------------------

class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repo;
  Timer? _debounce;

  InventoryNotifier(this._repo) : super(const InventoryState()) {
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(items: [], currentPage: 1, hasMore: false);
      _load(reset: true);
    });
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      items: [],
      currentPage: 1,
      hasMore: false,
    );
    _load(reset: true);
  }

  void toggleLowStockFilter() {
    state = state.copyWith(
      showLowStockOnly: !state.showLowStockOnly,
      items: [],
      currentPage: 1,
      hasMore: false,
    );
    _load(reset: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(items: [], currentPage: 1, hasMore: false);
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 1 : state.currentPage + 1;
      final result = await _repo.fetchItems(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryId: state.selectedCategoryId,
        lowStockOnly: state.showLowStockOnly,
      );
      final merged = reset ? result.data : [...state.items, ...result.data];
      state = state.copyWith(
        items: merged,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (reset) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: failureMessage(e),
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// InventoryDetailNotifier
// ---------------------------------------------------------------------------

class InventoryDetailNotifier
    extends StateNotifier<AsyncValue<InventoryDetail>> {
  final InventoryRepository _repo;
  final String _uuid;

  InventoryDetailNotifier(this._repo, this._uuid)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.fetchItem(_uuid);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> adjustStock(AddStockAdjustmentRequest request) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newQty = await _repo.adjustStock(
      _uuid,
      request,
      currentStock: current.stockQuantity,
    );
    state = AsyncValue.data(InventoryDetail(
      item: current.withStockQuantity(newQty).item,
      recentAdjustments: [
        StockAdjustment(
          type: request.type,
          quantity: request.quantity,
          reason: request.reason,
          adjustedBy: 'You',
          createdAt: DateTime.now(),
        ),
        ...current.recentAdjustments,
      ],
    ));
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final inventoryProvider =
    StateNotifierProvider.autoDispose<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier(ref.watch(inventoryRepositoryProvider));
});

final inventoryDetailProvider = StateNotifierProvider.autoDispose
    .family<InventoryDetailNotifier, AsyncValue<InventoryDetail>, String>(
  (ref, uuid) =>
      InventoryDetailNotifier(ref.watch(inventoryRepositoryProvider), uuid),
);

final partsCategoriesProvider =
    FutureProvider.autoDispose<List<PartsCategory>>((ref) async {
  return ref.watch(inventoryRepositoryProvider).fetchCategories();
});
