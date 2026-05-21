import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/models/dashboard_models.dart';

// ---------------------------------------------------------------------------
// Period
// ---------------------------------------------------------------------------

enum DashboardPeriod { today, week, month }

extension DashboardPeriodExt on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.week:
        return 'This Week';
      case DashboardPeriod.month:
        return 'This Month';
    }
  }

  String get apiValue {
    switch (this) {
      case DashboardPeriod.today:
        return 'today';
      case DashboardPeriod.week:
        return 'week';
      case DashboardPeriod.month:
        return 'month';
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final DashboardPeriod period;
  final AsyncValue<DashboardSummary> data;

  const DashboardState({
    this.period = DashboardPeriod.today,
    this.data = const AsyncValue.loading(),
  });

  DashboardState copyWith({DashboardPeriod? period, AsyncValue<DashboardSummary>? data}) =>
      DashboardState(period: period ?? this.period, data: data ?? this.data);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Dio _dio;
  Timer? _refreshTimer;

  DashboardNotifier(this._dio) : super(const DashboardState()) {
    _fetch();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final response = await _dio.get(
        '/dashboard/summary',
        queryParameters: {'period': state.period.apiValue},
      );
      final summary = DashboardSummary.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(data: AsyncValue.data(summary));
    } on DioException catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(failureMessage(e), st));
    } catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(failureMessage(e), st));
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> setPeriod(DashboardPeriod period) async {
    state = state.copyWith(period: period, data: const AsyncValue.loading());
    await _fetch();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(apiClientProvider));
});
