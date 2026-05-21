import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/garage_resources_repository.dart';
import '../../data/jobs_repository.dart';
import '../../data/models/job_models.dart';
import 'create_job_provider.dart';
import 'jobs_provider.dart';

class EditJobState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final JobDetail? job;
  final String complaint;
  final String priority;
  final String? selectedBayUuid;
  final String? selectedTechnicianUuid;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final List<BayOption> bays;
  final List<TechnicianOption> technicians;
  final bool isLoadingResources;

  const EditJobState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.job,
    this.complaint = '',
    this.priority = 'normal',
    this.selectedBayUuid,
    this.selectedTechnicianUuid,
    this.scheduledDate,
    this.scheduledTime,
    this.bays = const [],
    this.technicians = const [],
    this.isLoadingResources = false,
  });

  EditJobState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    JobDetail? job,
    String? complaint,
    String? priority,
    String? selectedBayUuid,
    String? selectedTechnicianUuid,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    List<BayOption>? bays,
    List<TechnicianOption>? technicians,
    bool? isLoadingResources,
    bool clearError = false,
  }) {
    return EditJobState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      job: job ?? this.job,
      complaint: complaint ?? this.complaint,
      priority: priority ?? this.priority,
      selectedBayUuid: selectedBayUuid ?? this.selectedBayUuid,
      selectedTechnicianUuid: selectedTechnicianUuid ?? this.selectedTechnicianUuid,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      bays: bays ?? this.bays,
      technicians: technicians ?? this.technicians,
      isLoadingResources: isLoadingResources ?? this.isLoadingResources,
    );
  }
}

class EditJobNotifier extends StateNotifier<EditJobState> {
  final JobsRepository _jobsRepo;
  final GarageResourcesRepository _resourcesRepo;
  final Ref _ref;
  final String _jobUuid;

  EditJobNotifier(this._jobsRepo, this._resourcesRepo, this._ref, this._jobUuid)
      : super(const EditJobState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final job = await _jobsRepo.fetchJob(_jobUuid);
      final scheduled = job.timeline['scheduled_start_at'] as String?;
      DateTime? scheduledDate;
      TimeOfDay? scheduledTime;
      if (scheduled != null) {
        final dt = DateTime.tryParse(scheduled);
        if (dt != null) {
          scheduledDate = DateTime(dt.year, dt.month, dt.day);
          scheduledTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
      }

      state = EditJobState(
        isLoading: false,
        job: job,
        complaint: job.customerComplaint ?? '',
        priority: job.priority == JobPriority.urgent
            ? 'urgent'
            : job.priority == JobPriority.vip
                ? 'vip'
                : 'normal',
        selectedBayUuid: job.serviceBay?.uuid,
        selectedTechnicianUuid: job.primaryTechnician?.uuid,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
      await loadResources();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: failureMessage(e));
    }
  }

  Future<void> loadResources() async {
    if (state.isLoadingResources) return;
    state = state.copyWith(isLoadingResources: true);
    try {
      final bays = await _resourcesRepo.fetchBays();
      final techs = await _resourcesRepo.fetchTechnicians();
      state = state.copyWith(bays: bays, technicians: techs, isLoadingResources: false);
    } catch (e) {
      state = state.copyWith(
        bays: const [],
        technicians: const [],
        isLoadingResources: false,
        errorMessage: failureMessage(e),
      );
    }
  }

  void setComplaint(String v) => state = state.copyWith(complaint: v);
  void setPriority(String p) => state = state.copyWith(priority: p);
  void selectBay(String uuid) => state = state.copyWith(selectedBayUuid: uuid);
  void selectTechnician(String uuid) => state = state.copyWith(selectedTechnicianUuid: uuid);

  void setSchedule(DateTime date, TimeOfDay time) {
    state = state.copyWith(scheduledDate: date, scheduledTime: time);
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      DateTime? scheduled;
      if (state.scheduledDate != null && state.scheduledTime != null) {
        scheduled = DateTime(
          state.scheduledDate!.year,
          state.scheduledDate!.month,
          state.scheduledDate!.day,
          state.scheduledTime!.hour,
          state.scheduledTime!.minute,
        );
      }

      await _jobsRepo.updateJob(_jobUuid, {
        'priority': state.priority,
        'customer_complaint': state.complaint,
        if (state.selectedTechnicianUuid != null)
          'primary_technician_uuid': state.selectedTechnicianUuid,
        if (state.selectedBayUuid != null) 'assigned_bay_uuid': state.selectedBayUuid,
        if (scheduled != null) 'scheduled_start_at': scheduled.toIso8601String(),
      });

      _ref.invalidate(jobDetailProvider(_jobUuid));
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: failureMessage(e));
      return false;
    }
  }
}

final editJobProvider =
    StateNotifierProvider.autoDispose.family<EditJobNotifier, EditJobState, String>(
  (ref, jobUuid) => EditJobNotifier(
    ref.watch(jobsRepositoryProvider),
    ref.watch(garageResourcesRepositoryProvider),
    ref,
    jobUuid,
  ),
);
