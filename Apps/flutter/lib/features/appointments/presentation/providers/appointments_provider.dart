import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/appointments_repository.dart';
import '../../data/models/appointment_models.dart';

enum AppointmentFilter { today, upcoming, all }

class AppointmentsState {
  final AppointmentFilter filter;
  final List<Appointment> appointments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const AppointmentsState({
    this.filter = AppointmentFilter.today,
    this.appointments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  AppointmentsState copyWith({
    AppointmentFilter? filter,
    List<Appointment>? appointments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? error = _sentinel,
  }) {
    return AppointmentsState(
      filter: filter ?? this.filter,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentsRepository _repo;

  AppointmentsNotifier(this._repo) : super(const AppointmentsState()) {
    refresh();
  }

  Future<void> setFilter(AppointmentFilter filter) async {
    state = state.copyWith(filter: filter, appointments: [], currentPage: 1, hasMore: false);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null, appointments: [], currentPage: 1);
    await _load(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _load(page: state.currentPage + 1, append: true);
  }

  Future<void> _load({required int page, required bool append}) async {
    state = state.copyWith(isLoading: !append, isLoadingMore: append);
    try {
      String? date;
      bool upcoming = false;
      switch (state.filter) {
        case AppointmentFilter.today:
          date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        case AppointmentFilter.upcoming:
          upcoming = true;
        case AppointmentFilter.all:
          break;
      }

      final result = await _repo.fetchAppointments(
        date: date,
        upcoming: upcoming,
        page: page,
      );

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        appointments: append ? [...state.appointments, ...result.items] : result.items,
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
}

final appointmentsProvider =
    StateNotifierProvider.autoDispose<AppointmentsNotifier, AppointmentsState>((ref) {
  return AppointmentsNotifier(ref.watch(appointmentsRepositoryProvider));
});
