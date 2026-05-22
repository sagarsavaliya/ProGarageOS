import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/jobs_repository.dart';
import '../../data/models/job_models.dart';

// ---------------------------------------------------------------------------
// Status filter tabs shown in the jobs screen
// ---------------------------------------------------------------------------

const jobFilterTabs = [
  null, // "All"
  'in_progress',
  'estimate_pending',
  'quality_check',
  'ready_for_delivery',
  'draft',
  'delivered',
];

const jobFilterTabLabels = [
  'All',
  'In Progress',
  'Estimate',
  'QC',
  'Ready',
  'Draft',
  'Delivered',
];

// ---------------------------------------------------------------------------
// Jobs list state
// ---------------------------------------------------------------------------

class JobsState {
  final String? statusFilter; // null = all
  final String searchQuery;
  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const JobsState({
    this.statusFilter,
    this.searchQuery = '',
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  JobsState copyWith({
    Object? statusFilter = _sentinel,
    String? searchQuery,
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? error = _sentinel,
  }) {
    return JobsState(
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

// Sentinel so null can be passed explicitly to copyWith.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class JobsNotifier extends StateNotifier<JobsState> {
  final JobsRepository _repo;
  Timer? _debounce;

  JobsNotifier(this._repo) : super(const JobsState()) {
    _load(reset: true);
  }

  // -- Public actions --------------------------------------------------------

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, jobs: [], currentPage: 1, hasMore: false);
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(jobs: [], currentPage: 1, hasMore: false);
      _load(reset: true);
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(jobs: [], currentPage: 1, hasMore: false);
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(reset: false);
  }

  // -- Internal --------------------------------------------------------------

  Future<void> _load({required bool reset}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 1 : state.currentPage + 1;
      final result = await _repo.fetchJobs(
        status: state.statusFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: page,
      );

      final merged = reset ? result.jobs : [...state.jobs, ...result.jobs];
      state = state.copyWith(
        jobs: merged,
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

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final jobsProvider = StateNotifierProvider.autoDispose<JobsNotifier, JobsState>((ref) {
  return JobsNotifier(ref.watch(jobsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Job detail provider
// ---------------------------------------------------------------------------

class JobDetailNotifier extends StateNotifier<AsyncValue<JobDetail>> {
  final JobsRepository _repo;
  final String _uuid;

  JobDetailNotifier(this._repo, this._uuid) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.fetchJob(_uuid);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> updateStatus(String apiStatus, {String? notes}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await _repo.updateStatus(_uuid, apiStatus, notes: notes);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }

  Future<void> updateInsuranceClaim({
    String? insuranceClaimStatus,
    String? insuranceCompany,
    String? claimNumber,
    double? customerLiabilityAmount,
    double? jobInsuranceClaimAmount,
  }) async {
    try {
      await _repo.updateInsuranceClaim(
        _uuid,
        insuranceClaimStatus: insuranceClaimStatus,
        insuranceCompany: insuranceCompany,
        claimNumber: claimNumber,
        customerLiabilityAmount: customerLiabilityAmount,
        jobInsuranceClaimAmount: jobInsuranceClaimAmount,
      );
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(failureMessage(e), st);
    }
  }
}

final jobDetailProvider =
    StateNotifierProvider.autoDispose.family<JobDetailNotifier, AsyncValue<JobDetail>, String>(
  (ref, uuid) => JobDetailNotifier(ref.watch(jobsRepositoryProvider), uuid),
);
