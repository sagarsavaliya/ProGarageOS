import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/customers_repository.dart';
import '../../data/models/customer_models.dart';

// ---------------------------------------------------------------------------
// Customers list state + notifier
// ---------------------------------------------------------------------------

class CustomersState {
  final String searchQuery;
  final List<Customer> customers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const CustomersState({
    this.searchQuery = '',
    this.customers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  CustomersState copyWith({
    String? searchQuery,
    List<Customer>? customers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? error = _sentinel,
  }) {
    return CustomersState(
      searchQuery: searchQuery ?? this.searchQuery,
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class CustomersNotifier extends StateNotifier<CustomersState> {
  final CustomersRepository _repo;
  Timer? _debounce;

  CustomersNotifier(this._repo) : super(const CustomersState()) {
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(customers: [], currentPage: 1, hasMore: false);
      _load(reset: true);
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(customers: [], currentPage: 1, hasMore: false);
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 1 : state.currentPage + 1;
      final result = await _repo.fetchCustomers(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: page,
      );

      final merged = reset ? result.customers : [...state.customers, ...result.customers];
      state = state.copyWith(
        customers: merged,
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
          error: failureMessage(e),
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

final customersProvider =
    StateNotifierProvider.autoDispose<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier(ref.watch(customersRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Customer detail provider
// ---------------------------------------------------------------------------

final customerDetailProvider =
    StateNotifierProvider.autoDispose.family<_CustomerDetailNotifier, AsyncValue<CustomerDetail>, String>(
  (ref, uuid) => _CustomerDetailNotifier(ref.watch(customersRepositoryProvider), uuid),
);

class _CustomerDetailNotifier extends StateNotifier<AsyncValue<CustomerDetail>> {
  final CustomersRepository _repo;
  final String _uuid;

  _CustomerDetailNotifier(this._repo, this._uuid) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.fetchCustomer(_uuid);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }
}

// ---------------------------------------------------------------------------
// Vehicles list provider (per customer)
// ---------------------------------------------------------------------------

final customerVehiclesProvider =
    StateNotifierProvider.autoDispose.family<_VehiclesNotifier, AsyncValue<List<Vehicle>>, String>(
  (ref, customerUuid) => _VehiclesNotifier(ref.watch(customersRepositoryProvider), customerUuid),
);

class _VehiclesNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  final CustomersRepository _repo;
  final String _customerUuid;

  _VehiclesNotifier(this._repo, this._customerUuid) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final vehicles = await _repo.fetchVehicles(_customerUuid);
      state = AsyncValue.data(vehicles);
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }
}

// ---------------------------------------------------------------------------
// Vehicle documents provider (per vehicle)
// ---------------------------------------------------------------------------

final vehicleDocumentsProvider =
    StateNotifierProvider.autoDispose.family<_DocsNotifier, AsyncValue<List<VehicleDocument>>, String>(
  (ref, vehicleUuid) => _DocsNotifier(ref.watch(customersRepositoryProvider), vehicleUuid),
);

class _DocsNotifier extends StateNotifier<AsyncValue<List<VehicleDocument>>> {
  final CustomersRepository _repo;
  final String _vehicleUuid;

  _DocsNotifier(this._repo, this._vehicleUuid) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await _repo.fetchDocuments(_vehicleUuid);
      state = AsyncValue.data(docs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> deleteDocument(String docUuid) async {
    await _repo.deleteVehicleDocument(vehicleUuid: _vehicleUuid, docUuid: docUuid);
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Service history (per customer)
// ---------------------------------------------------------------------------

final customerServiceHistoryProvider =
    FutureProvider.autoDispose.family<List<ServiceHistoryItem>, String>((ref, customerUuid) async {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.fetchServiceHistory(customerUuid);
});

/// Loads one vehicle by UUID when customer context is missing (e.g. Fleet tab).
final vehicleByUuidProvider =
    FutureProvider.autoDispose.family<Vehicle, String>((ref, vehicleUuid) async {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.fetchVehicle(vehicleUuid);
});
