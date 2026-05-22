import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/payments_repository.dart';
import '../../data/models/outstanding_models.dart';

class PaymentsHubState {
  final String searchQuery;
  final List<OutstandingInvoice> invoices;
  final double totalOutstanding;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaymentsHubState({
    this.searchQuery = '',
    this.invoices = const [],
    this.totalOutstanding = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  PaymentsHubState copyWith({
    String? searchQuery,
    List<OutstandingInvoice>? invoices,
    double? totalOutstanding,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? error = _sentinel,
  }) {
    return PaymentsHubState(
      searchQuery: searchQuery ?? this.searchQuery,
      invoices: invoices ?? this.invoices,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class PaymentsHubNotifier extends StateNotifier<PaymentsHubState> {
  final PaymentsRepository _repo;
  Timer? _debounce;

  PaymentsHubNotifier(this._repo) : super(const PaymentsHubState()) {
    refresh();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refresh);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null, invoices: [], currentPage: 1);
    await _load(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(page: state.currentPage + 1, append: true);
  }

  Future<void> _load({required int page, required bool append}) async {
    state = state.copyWith(isLoading: !append, isLoadingMore: append);
    try {
      final result = await _repo.fetchOutstanding(
        search: state.searchQuery,
        page: page,
      );
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        invoices: append ? [...state.invoices, ...result.invoices] : result.invoices,
        totalOutstanding: result.totalOutstanding,
        hasMore: result.hasMore,
        currentPage: result.currentPage,
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

final paymentsHubProvider =
    StateNotifierProvider.autoDispose<PaymentsHubNotifier, PaymentsHubState>((ref) {
  return PaymentsHubNotifier(ref.watch(paymentsRepositoryProvider));
});
