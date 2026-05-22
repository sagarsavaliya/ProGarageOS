import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';

/// Local backup of in-progress setup fields — survives app crash before API save.
class SetupDraft {
  final String? businessName;
  final String? gstNumber;
  final String? address;
  final String? phone;
  final String? bayCount;
  final String? lastStep;

  const SetupDraft({
    this.businessName,
    this.gstNumber,
    this.address,
    this.phone,
    this.bayCount,
    this.lastStep,
  });

  Map<String, dynamic> toJson() => {
        if (businessName != null) 'business_name': businessName,
        if (gstNumber != null) 'gst_number': gstNumber,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (bayCount != null) 'bay_count': bayCount,
        if (lastStep != null) 'last_step': lastStep,
        'saved_at': DateTime.now().toIso8601String(),
      };

  factory SetupDraft.fromJson(Map<String, dynamic> json) {
    return SetupDraft(
      businessName: json['business_name'] as String?,
      gstNumber: json['gst_number'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      bayCount: json['bay_count'] as String?,
      lastStep: json['last_step'] as String?,
    );
  }

  SetupDraft mergeWith(SetupDraft other) {
    return SetupDraft(
      businessName: other.businessName?.isNotEmpty == true ? other.businessName : businessName,
      gstNumber: other.gstNumber?.isNotEmpty == true ? other.gstNumber : gstNumber,
      address: other.address?.isNotEmpty == true ? other.address : address,
      phone: other.phone?.isNotEmpty == true ? other.phone : phone,
      bayCount: other.bayCount?.isNotEmpty == true ? other.bayCount : bayCount,
      lastStep: other.lastStep ?? lastStep,
    );
  }
}

class OnboardingDraftService {
  final SecureStorageService _storage;

  const OnboardingDraftService(this._storage);

  String _key(String tenantUuid) => 'setup_draft_$tenantUuid';

  Future<SetupDraft?> load(String tenantUuid) async {
    final raw = await _storage.readRaw(_key(tenantUuid));
    if (raw == null || raw.isEmpty) return null;
    try {
      return SetupDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String tenantUuid, SetupDraft draft) =>
      _storage.writeRaw(_key(tenantUuid), jsonEncode(draft.toJson()));

  Future<void> clear(String tenantUuid) => _storage.deleteRaw(_key(tenantUuid));
}

final onboardingDraftServiceProvider = Provider<OnboardingDraftService>((ref) {
  return OnboardingDraftService(ref.watch(secureStorageProvider));
});

/// Maps API setup_step to wizard page index (0–3).
int setupStepToPageIndex(String step) {
  switch (step) {
    case 'details':
      return 1;
    case 'bays':
      return 2;
    case 'done':
      return 3;
    case 'welcome':
    default:
      return 0;
  }
}

String pageIndexToSetupStep(int index) {
  switch (index) {
    case 1:
      return 'details';
    case 2:
      return 'bays';
    case 3:
      return 'done';
    default:
      return 'welcome';
  }
}
