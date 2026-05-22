import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/models/fleet_models.dart';
import '../../data/vehicles_repository.dart';

class FleetState {
  final String searchQuery;
  final List<FleetVehicle> vehicles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int total;
  final String? error;

  const FleetState({
    this.searchQuery = '',
    this.vehicles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.total = 0,
    this.error,
  });

  FleetState copyWith({
    String? searchQuery,
    List<FleetVehicle>? vehicles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? total,
    Object? error = _sentinel,
  }) {
    return FleetState(
      searchQuery: searchQuery ?? this.searchQuery,
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class FleetNotifier extends StateNotifier<FleetState> {
  final VehiclesRepository _repo;
  Timer? _debounce;

  FleetNotifier(this._repo) : super(const FleetState()) {
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(vehicles: [], currentPage: 1, hasMore: false);
      _load(reset: true);
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(vehicles: [], currentPage: 1, hasMore: false);
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    final page = reset ? 1 : state.currentPage + 1;
    state = state.copyWith(
      isLoading: reset,
      isLoadingMore: !reset,
      error: null,
    );

    try {
      final result = await _repo.fetchVehicles(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(
        vehicles: reset ? result.data : [...state.vehicles, ...result.data],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failureMessage(e),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final fleetProvider =
    StateNotifierProvider.autoDispose<FleetNotifier, FleetState>((ref) {
  return FleetNotifier(ref.watch(vehiclesRepositoryProvider));
});
