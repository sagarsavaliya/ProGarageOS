import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/invoices_repository.dart';
import '../../data/models/invoice_models.dart';

// ---------------------------------------------------------------------------
// Status filter tabs shown in invoices screen
// ---------------------------------------------------------------------------

const invoiceFilterTabs = [
  null, // "All"
  'draft',
  'sent',
  'overdue',
  'partially_paid',
  'paid',
  'cancelled',
];

const invoiceFilterTabLabels = [
  'All',
  'Draft',
  'Sent',
  'Overdue',
  'Partial',
  'Paid',
  'Cancelled',
];

// ---------------------------------------------------------------------------
// Invoices list state
// ---------------------------------------------------------------------------

class InvoicesState {
  final String? statusFilter;
  final String searchQuery;
  final List<InvoiceListItem> invoices;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const InvoicesState({
    this.statusFilter,
    this.searchQuery = '',
    this.invoices = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.errorMessage,
  });

  InvoicesState copyWith({
    Object? statusFilter = _sentinel,
    String? searchQuery,
    List<InvoiceListItem>? invoices,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? errorMessage = _sentinel,
  }) {
    return InvoicesState(
      statusFilter:
          statusFilter == _sentinel ? this.statusFilter : statusFilter as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// InvoicesNotifier
// ---------------------------------------------------------------------------

class InvoicesNotifier extends StateNotifier<InvoicesState> {
  final InvoicesRepository _repo;
  Timer? _debounce;

  InvoicesNotifier(this._repo) : super(const InvoicesState()) {
    _load(reset: true);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      invoices: [],
      currentPage: 1,
      hasMore: false,
    );
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(invoices: [], currentPage: 1, hasMore: false);
      _load(reset: true);
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(invoices: [], currentPage: 1, hasMore: false);
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
      final result = await _repo.fetchInvoices(
        page: page,
        status: state.statusFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      final merged =
          reset ? result.data : [...state.invoices, ...result.data];
      state = state.copyWith(
        invoices: merged,
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
// Providers
// ---------------------------------------------------------------------------

final invoicesProvider =
    StateNotifierProvider.autoDispose<InvoicesNotifier, InvoicesState>((ref) {
  return InvoicesNotifier(ref.watch(invoicesRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Invoice detail provider
// ---------------------------------------------------------------------------

class InvoiceDetailNotifier extends StateNotifier<AsyncValue<InvoiceDetail>> {
  final InvoicesRepository _repo;
  final String _uuid;

  InvoiceDetailNotifier(this._repo, this._uuid)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.fetchInvoice(_uuid);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> recordPayment(RecordPaymentRequest request) async {
    final updated = await _repo.recordPayment(_uuid, request);
    state = AsyncValue.data(updated);
  }
}

final invoiceDetailProvider = StateNotifierProvider.autoDispose
    .family<InvoiceDetailNotifier, AsyncValue<InvoiceDetail>, String>(
  (ref, uuid) => InvoiceDetailNotifier(ref.watch(invoicesRepositoryProvider), uuid),
);

// ---------------------------------------------------------------------------
// Payment methods provider
// ---------------------------------------------------------------------------

final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  return ref.watch(invoicesRepositoryProvider).fetchPaymentMethods();
});
