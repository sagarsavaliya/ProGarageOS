import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/jobs_repository.dart';
import '../../data/models/estimate_models.dart';
import '../../data/models/inspection_models.dart';

/// Route scope for intake vs delivery inspection flows.
@immutable
class InspectionScope {
  final String jobUuid;
  final String phase;

  const InspectionScope({required this.jobUuid, this.phase = 'intake'});

  bool get isDelivery => phase == 'delivery';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionScope && jobUuid == other.jobUuid && phase == other.phase;

  @override
  int get hashCode => Object.hash(jobUuid, phase);
}

class VehicleInspectionState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<InspectionCheckItem> checklistItems;
  final Map<String, InspectionCondition> conditions;
  final Map<String, DamageSeverity> damageZones;
  final List<InspectionPhotoSlot> photos;
  final bool customerAcknowledged;
  final String notes;
  final bool isReadOnly;
  final String phase;

  const VehicleInspectionState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.checklistItems = intakeInspectionItems,
    this.conditions = const {},
    this.damageZones = const {},
    this.photos = const [],
    this.customerAcknowledged = false,
    this.notes = '',
    this.isReadOnly = false,
    this.phase = 'intake',
  });

  int get completedChecklistCount =>
      conditions.values.where((c) => c != InspectionCondition.none).length;

  int get totalChecklistCount => checklistItems.length;

  bool get photosRequired => phase != 'delivery';

  bool get allPhotosReady =>
      !photosRequired ||
      (photos.length >= requiredPhotoSlotCount &&
          photos.take(requiredPhotoSlotCount).every((p) => p.hasPhoto && !p.isUploading));

  bool get hasUploading => photos.any((p) => p.isUploading);

  bool get canSubmit =>
      !isReadOnly &&
      !isSubmitting &&
      !hasUploading &&
      completedChecklistCount == totalChecklistCount &&
      customerAcknowledged &&
      allPhotosReady;

  VehicleInspectionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<InspectionCheckItem>? checklistItems,
    Map<String, InspectionCondition>? conditions,
    Map<String, DamageSeverity>? damageZones,
    List<InspectionPhotoSlot>? photos,
    bool? customerAcknowledged,
    String? notes,
    bool? isReadOnly,
    String? phase,
  }) {
    return VehicleInspectionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      checklistItems: checklistItems ?? this.checklistItems,
      conditions: conditions ?? this.conditions,
      damageZones: damageZones ?? this.damageZones,
      photos: photos ?? this.photos,
      customerAcknowledged: customerAcknowledged ?? this.customerAcknowledged,
      notes: notes ?? this.notes,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      phase: phase ?? this.phase,
    );
  }
}

class VehicleInspectionNotifier extends StateNotifier<VehicleInspectionState> {
  final JobsRepository _repo;
  final InspectionScope _scope;
  final ImagePicker _picker = ImagePicker();

  VehicleInspectionNotifier(this._repo, this._scope)
      : super(VehicleInspectionState(phase: _scope.phase)) {
    _init();
  }

  Future<void> _init() async {
    List<InspectionCheckItem> items = intakeInspectionItems;
    try {
      final fromApi = await _repo.fetchInspectionTemplate(_scope.phase);
      if (fromApi.isNotEmpty) items = fromApi;
    } catch (_) {
      // Use static checklist when templates unavailable.
    }

    final conditions = <String, InspectionCondition>{};
    for (final item in items) {
      conditions[item.id] = InspectionCondition.none;
    }

    final photos = List<InspectionPhotoSlot>.generate(
      requiredPhotoSlotCount,
      (i) => InspectionPhotoSlot(slot: '$i', label: photoSlotLabels[i]),
    );

    state = state.copyWith(
      isLoading: true,
      checklistItems: items,
      conditions: conditions,
      damageZones: {},
      photos: photos,
      phase: _scope.phase,
    );

    try {
      final saved = await _repo.fetchInspection(_scope.jobUuid, phase: _scope.phase);
      if (saved.hasSavedData) {
        final mergedConditions = Map<String, InspectionCondition>.from(conditions);
        mergedConditions.addAll(saved.conditions);

        final mergedPhotos = List<InspectionPhotoSlot>.generate(
          requiredPhotoSlotCount,
          (i) {
            final slotId = '$i';
            InspectionPhotoSlot? existing;
            for (final p in saved.photos) {
              if (p.slot == slotId) {
                existing = p;
                break;
              }
            }
            return existing ??
                InspectionPhotoSlot(slot: slotId, label: photoSlotLabels[i]);
          },
        );

        state = state.copyWith(
          isLoading: false,
          conditions: mergedConditions,
          damageZones: Map<String, DamageSeverity>.from(saved.damageZones),
          photos: mergedPhotos,
          customerAcknowledged: saved.customerAcknowledged,
          notes: saved.notes ?? '',
        );
        return;
      }
    } catch (_) {
      // No saved inspection yet — fresh form.
    }

    state = state.copyWith(isLoading: false);
  }

  void setCondition(String id, InspectionCondition c) {
    if (state.isReadOnly) return;
    final next = Map<String, InspectionCondition>.from(state.conditions);
    next[id] = c;
    state = state.copyWith(conditions: next);
  }

  void cycleDamage(String zone) {
    if (state.isReadOnly) return;
    final next = Map<String, DamageSeverity>.from(state.damageZones);
    final current = next[zone] ?? DamageSeverity.none;
    final severity = switch (current) {
      DamageSeverity.none => DamageSeverity.minor,
      DamageSeverity.minor => DamageSeverity.major,
      DamageSeverity.major => DamageSeverity.none,
    };
    if (severity == DamageSeverity.none) {
      next.remove(zone);
    } else {
      next[zone] = severity;
    }
    state = state.copyWith(damageZones: next);
  }

  void clearDamage() {
    if (state.isReadOnly) return;
    state = state.copyWith(damageZones: {});
  }

  void setNotes(String v) => state = state.copyWith(notes: v);

  void setAcknowledged(bool v) {
    if (state.isReadOnly) return;
    state = state.copyWith(customerAcknowledged: v);
  }

  Future<void> capturePhoto(int index) async {
    if (state.isReadOnly || index < 0 || index >= state.photos.length) return;

    final source = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (source == null) return;

    await _uploadPhotoAt(index, File(source.path));
  }

  Future<void> pickPhotoFromGallery(int index) async {
    if (state.isReadOnly || index < 0 || index >= state.photos.length) return;

    final source = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (source == null) return;

    await _uploadPhotoAt(index, File(source.path));
  }

  Future<void> _uploadPhotoAt(int index, File file) async {
    final slot = state.photos[index];
    final photos = [...state.photos];
    photos[index] = slot.copyWith(
      localPath: file.path,
      isUploading: true,
      clearError: true,
    );
    state = state.copyWith(photos: photos);

    try {
      final uploaded = await _repo.uploadInspectionPhoto(
        jobUuid: _scope.jobUuid,
        slot: slot.slot,
        label: slot.label,
        file: file,
      );
      photos[index] = uploaded.copyWith(isUploading: false, clearError: true);
      state = state.copyWith(photos: photos);
    } on DioException catch (_) {
      photos[index] = slot.copyWith(
        isUploading: false,
        uploadError: 'Upload failed. Tap to retry.',
      );
      state = state.copyWith(photos: photos);
    } catch (_) {
      photos[index] = slot.copyWith(
        isUploading: false,
        uploadError: 'Could not upload photo.',
      );
      state = state.copyWith(photos: photos);
    }
  }

  String _mapCondition(InspectionCondition c) {
    return switch (c) {
      InspectionCondition.ok => 'good',
      InspectionCondition.issue => 'fair',
      InspectionCondition.damage => 'damaged',
      InspectionCondition.none => 'na',
    };
  }

  String _mapDamageSeverity(DamageSeverity s) {
    return switch (s) {
      DamageSeverity.minor => 'minor',
      DamageSeverity.major => 'severe',
      DamageSeverity.none => 'none',
    };
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _repo.saveInspection(_scope.jobUuid, {
        'inspection_phase': _scope.phase,
        'customer_acknowledged': state.customerAcknowledged,
        if (state.notes.trim().isNotEmpty) 'notes': state.notes.trim(),
        'items': state.checklistItems.map((item) {
          final c = state.conditions[item.id] ?? InspectionCondition.none;
          return {
            'component_key': item.id,
            'component_name': item.name,
            'category': item.group,
            'condition_status': _mapCondition(c),
            'severity': c == InspectionCondition.damage ? 'moderate' : 'none',
          };
        }).toList(),
        'damage_zones': state.damageZones.entries
            .map((e) => {'zone': e.key, 'severity': _mapDamageSeverity(e.value)})
            .toList(),
        'photos': state.photos
            .where((p) => p.hasPhoto)
            .map((p) => p.toApiJson())
            .toList(),
      });

      if (_scope.phase == 'intake') {
        await _repo.updateStatus(
          _scope.jobUuid,
          'estimate_pending',
          notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
        );
      }

      state = state.copyWith(isSubmitting: false);
      return true;
    } on DioException catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not save inspection. Check connection and try again.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not save inspection.',
      );
      return false;
    }
  }
}

final vehicleInspectionProvider = StateNotifierProvider.autoDispose
    .family<VehicleInspectionNotifier, VehicleInspectionState, InspectionScope>(
  (ref, scope) => VehicleInspectionNotifier(ref.watch(jobsRepositoryProvider), scope),
);

/// Compare intake vs delivery — used on job detail for QC / ready states.
final inspectionCompareProvider = FutureProvider.autoDispose
    .family<InspectionCompareResult, String>((ref, jobUuid) async {
  return ref.watch(jobsRepositoryProvider).compareInspections(jobUuid);
});
