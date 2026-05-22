import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/jobs_repository.dart';
import '../../data/models/job_models.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'jobs_provider.dart';

class JobTasksState {
  final List<TaskItem> tasks;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  const JobTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.error,
  });

  JobTasksState copyWith({
    List<TaskItem>? tasks,
    bool? isLoading,
    bool? isMutating,
    Object? error = _sentinel,
  }) {
    return JobTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class JobTasksNotifier extends StateNotifier<JobTasksState> {
  final JobsRepository _repo;
  final String _jobUuid;
  final Ref _ref;

  JobTasksNotifier(this._repo, this._ref, this._jobUuid) : super(const JobTasksState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repo.fetchTasks(_jobUuid);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: failureMessage(e));
    }
  }

  Future<bool> addTask({
    required String name,
    double estimatedPrice = 0,
    int? laborMinutes,
    bool requiresCustomerApproval = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(isMutating: true, error: null);
    try {
      final task = await _repo.createTask(_jobUuid, {
        'name': trimmed,
        'source': 'discovered',
        'status': requiresCustomerApproval ? 'pending_approval' : 'approved',
        'estimated_price': estimatedPrice,
        if (laborMinutes != null) 'labor_minutes': laborMinutes,
        'requires_customer_approval': requiresCustomerApproval,
        'is_billable': true,
      });
      state = state.copyWith(
        tasks: [...state.tasks, task],
        isMutating: false,
      );
      _ref.invalidate(jobDetailProvider(_jobUuid));
      _ref.invalidate(jobsProvider);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: failureMessage(e));
      return false;
    }
  }

  Future<bool> completeTask(TaskItem task) async {
    final taskId = task.id;
    if (taskId == null) return false;

    state = state.copyWith(isMutating: true, error: null);
    try {
      final updated = await _repo.updateTask(_jobUuid, taskId, {'status': 'completed'});
      final next = state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      state = state.copyWith(tasks: next, isMutating: false);
      _ref.invalidate(jobDetailProvider(_jobUuid));
      _ref.invalidate(jobsProvider);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: failureMessage(e));
      return false;
    }
  }
}

final jobTasksProvider =
    StateNotifierProvider.autoDispose.family<JobTasksNotifier, JobTasksState, String>(
  (ref, jobUuid) => JobTasksNotifier(ref.watch(jobsRepositoryProvider), ref, jobUuid),
);
