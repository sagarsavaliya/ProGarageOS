import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/jobs_repository.dart';
import '../../data/models/estimate_models.dart';

class EstimateState {
  final bool isLoading;
  final bool isSaving;
  final bool isSending;
  final JobEstimate? estimate;
  final Map<int, double> editedPrices;
  final String? errorMessage;
  final String? actionError;

  const EstimateState({
    this.isLoading = true,
    this.isSaving = false,
    this.isSending = false,
    this.estimate,
    this.editedPrices = const {},
    this.errorMessage,
    this.actionError,
  });

  double linePrice(EstimateLine line) => editedPrices[line.id] ?? line.finalPrice;

  double get subtotal {
    final est = estimate;
    if (est == null) return 0;
    return est.lines
        .where((l) => l.isBillable)
        .fold(0.0, (sum, l) => sum + linePrice(l));
  }

  bool get hasChanges {
    final est = estimate;
    if (est == null) return false;
    for (final line in est.lines) {
      if (editedPrices.containsKey(line.id) && editedPrices[line.id] != line.finalPrice) {
        return true;
      }
    }
    return false;
  }

  EstimateState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSending,
    JobEstimate? estimate,
    Map<int, double>? editedPrices,
    String? errorMessage,
    String? actionError,
    bool clearActionError = false,
  }) {
    return EstimateState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSending: isSending ?? this.isSending,
      estimate: estimate ?? this.estimate,
      editedPrices: editedPrices ?? this.editedPrices,
      errorMessage: errorMessage,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class EstimateNotifier extends StateNotifier<EstimateState> {
  final JobsRepository _repo;
  final String _jobUuid;

  EstimateNotifier(this._repo, this._jobUuid) : super(const EstimateState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final estimate = await _repo.fetchEstimate(_jobUuid);
      state = state.copyWith(isLoading: false, estimate: estimate, editedPrices: {});
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: failureMessage(e));
    }
  }

  void setLinePrice(int lineId, double price) {
    final next = Map<int, double>.from(state.editedPrices);
    next[lineId] = price;
    state = state.copyWith(editedPrices: next, clearActionError: true);
  }

  Future<bool> save() async {
    final est = state.estimate;
    if (est == null || est.lines.isEmpty) return false;

    state = state.copyWith(isSaving: true, clearActionError: true);
    try {
      final lines = est.lines.map((line) {
        final price = state.linePrice(line);
        return {
          'id': line.id,
          'estimated_price': price,
          'final_price': price,
          if (line.laborMinutes != null) 'labor_minutes': line.laborMinutes,
        };
      }).toList();

      final updated = await _repo.updateEstimate(_jobUuid, {'lines': lines});
      state = state.copyWith(isSaving: false, estimate: updated, editedPrices: {});
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, actionError: failureMessage(e));
      return false;
    }
  }

  Future<bool> send() async {
    state = state.copyWith(isSending: true, clearActionError: true);
    try {
      if (state.hasChanges) {
        final saved = await save();
        if (!saved) {
          state = state.copyWith(isSending: false);
          return false;
        }
      }
      await _repo.sendEstimate(_jobUuid);
      await load();
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, actionError: failureMessage(e));
      return false;
    }
  }

  Future<bool> approve({String? notes}) async {
    state = state.copyWith(isSaving: true, clearActionError: true);
    try {
      final updated = await _repo.approveEstimate(_jobUuid, notes: notes);
      state = state.copyWith(isSaving: false, estimate: updated, editedPrices: {});
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, actionError: failureMessage(e));
      return false;
    }
  }

  Future<bool> reject(String notes) async {
    state = state.copyWith(isSaving: true, clearActionError: true);
    try {
      final updated = await _repo.rejectEstimate(_jobUuid, notes: notes);
      state = state.copyWith(isSaving: false, estimate: updated, editedPrices: {});
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, actionError: failureMessage(e));
      return false;
    }
  }
}

final estimateProvider = StateNotifierProvider.autoDispose
    .family<EstimateNotifier, EstimateState, String>(
  (ref, jobUuid) => EstimateNotifier(ref.watch(jobsRepositoryProvider), jobUuid),
);
