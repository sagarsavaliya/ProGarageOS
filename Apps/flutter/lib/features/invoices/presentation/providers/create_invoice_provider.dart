import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jobs/data/jobs_repository.dart';
import '../../../jobs/data/models/job_models.dart';
import '../../data/invoices_repository.dart';

class InvoiceLineDraft {
  final String lineType;
  final String name;
  double quantity;
  double unitPrice;

  InvoiceLineDraft({
    this.lineType = 'service',
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  Map<String, dynamic> toJson() => {
        'line_type': lineType,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class CreateInvoiceState {
  final bool isLoadingJobs;
  final bool isSubmitting;
  final String? errorMessage;
  final List<Job> billableJobs;
  final Job? selectedJob;
  final List<InvoiceLineDraft> lines;
  final String? createdInvoiceUuid;

  const CreateInvoiceState({
    this.isLoadingJobs = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.billableJobs = const [],
    this.selectedJob,
    this.lines = const [],
    this.createdInvoiceUuid,
  });

  double get subtotal =>
      lines.fold(0, (s, l) => s + l.quantity * l.unitPrice);

  CreateInvoiceState copyWith({
    bool? isLoadingJobs,
    bool? isSubmitting,
    String? errorMessage,
    List<Job>? billableJobs,
    Job? selectedJob,
    bool clearJob = false,
    List<InvoiceLineDraft>? lines,
    String? createdInvoiceUuid,
  }) {
    return CreateInvoiceState(
      isLoadingJobs: isLoadingJobs ?? this.isLoadingJobs,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      billableJobs: billableJobs ?? this.billableJobs,
      selectedJob: clearJob ? null : (selectedJob ?? this.selectedJob),
      lines: lines ?? this.lines,
      createdInvoiceUuid: createdInvoiceUuid ?? this.createdInvoiceUuid,
    );
  }
}

class CreateInvoiceNotifier extends StateNotifier<CreateInvoiceState> {
  final InvoicesRepository _invoicesRepo;
  final JobsRepository _jobsRepo;
  final String? preselectedJobUuid;

  CreateInvoiceNotifier(this._invoicesRepo, this._jobsRepo, this.preselectedJobUuid)
      : super(const CreateInvoiceState()) {
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final result = await _jobsRepo.fetchJobs(perPage: 50);
      final jobs = result.jobs.where((j) {
        final s = j.status;
        return s == JobStatus.estimateApproved ||
            s == JobStatus.inProgress ||
            s == JobStatus.readyForDelivery ||
            s == JobStatus.qcPending;
      }).toList();
      Job? selected;
      if (preselectedJobUuid != null) {
        for (final j in jobs) {
          if (j.uuid == preselectedJobUuid) {
            selected = j;
            break;
          }
        }
      }
      state = state.copyWith(
        isLoadingJobs: false,
        billableJobs: jobs,
        selectedJob: selected,
        lines: selected != null
            ? [InvoiceLineDraft(name: 'Service charges', unitPrice: 0)]
            : const [],
      );
    } catch (_) {
      state = state.copyWith(isLoadingJobs: false, billableJobs: []);
    }
  }

  void selectJob(Job job) {
    state = state.copyWith(
      selectedJob: job,
      lines: [
        InvoiceLineDraft(
          name: 'Service — ${job.jobNumber}',
          unitPrice: 0,
        ),
      ],
    );
  }

  void updateLine(int index, InvoiceLineDraft line) {
    final next = [...state.lines];
    if (index >= 0 && index < next.length) {
      next[index] = line;
      state = state.copyWith(lines: next);
    }
  }

  void addLine() {
    state = state.copyWith(
      lines: [...state.lines, InvoiceLineDraft(name: 'Line item')],
    );
  }

  void removeLine(int index) {
    final next = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: next);
  }

  Future<String?> submit() async {
    final job = state.selectedJob;
    if (job == null || state.lines.isEmpty) {
      state = state.copyWith(errorMessage: 'Select a job and add at least one line.');
      return null;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final created = await _invoicesRepo.createInvoice({
        'job_uuid': job.uuid,
        'type': 'final',
        'items': state.lines.map((l) => l.toJson()).toList(),
      });
      state = state.copyWith(isSubmitting: false, createdInvoiceUuid: created.uuid);
      return created.uuid;
    } on DioException catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not create invoice. Check job and line items.',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not create invoice. Try again.',
      );
      return null;
    }
  }
}

final createInvoiceProvider = StateNotifierProvider.autoDispose
    .family<CreateInvoiceNotifier, CreateInvoiceState, String?>((ref, jobUuid) {
  return CreateInvoiceNotifier(
    ref.watch(invoicesRepositoryProvider),
    ref.watch(jobsRepositoryProvider),
    jobUuid,
  );
});
