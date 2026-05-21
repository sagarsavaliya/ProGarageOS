// Intake inspection checklist + damage map models.

enum InspectionCondition { none, ok, issue, damage }

enum DamageSeverity { none, minor, major }

class InspectionCheckItem {
  final String id;
  final String group;
  final String name;

  const InspectionCheckItem({
    required this.id,
    required this.group,
    required this.name,
  });
}

const intakeInspectionItems = [
  InspectionCheckItem(id: 'body', group: 'Exterior', name: 'Body & Paint'),
  InspectionCheckItem(id: 'windshield-front', group: 'Exterior', name: 'Front windshield'),
  InspectionCheckItem(id: 'windshield-rear', group: 'Exterior', name: 'Rear windshield'),
  InspectionCheckItem(id: 'side-mirrors', group: 'Exterior', name: 'Side mirrors'),
  InspectionCheckItem(id: 'lights', group: 'Exterior', name: 'Headlights & tail lights'),
  InspectionCheckItem(id: 'dashboard', group: 'Interior', name: 'Dashboard & console'),
  InspectionCheckItem(id: 'steering', group: 'Interior', name: 'Steering wheel'),
  InspectionCheckItem(id: 'seats', group: 'Interior', name: 'Seats & upholstery'),
  InspectionCheckItem(id: 'ac', group: 'Interior', name: 'AC & ventilation'),
  InspectionCheckItem(id: 'engine-oil', group: 'Under Hood', name: 'Engine oil level'),
  InspectionCheckItem(id: 'coolant', group: 'Under Hood', name: 'Coolant level'),
  InspectionCheckItem(id: 'battery', group: 'Under Hood', name: 'Battery condition'),
  InspectionCheckItem(id: 'tyres', group: 'Wheels', name: 'Tyre tread & pressure'),
  InspectionCheckItem(id: 'spare', group: 'Wheels', name: 'Spare wheel'),
  InspectionCheckItem(id: 'tools', group: 'Accessories', name: 'Tool kit & jack'),
  InspectionCheckItem(id: 'documents', group: 'Accessories', name: 'RC & insurance copy'),
];

const carDamageZones = [
  'Front Bumper',
  'Hood',
  'Front Left Fender',
  'Front Right Fender',
  'Left Door',
  'Right Door',
  'Rear Left Fender',
  'Rear Right Fender',
  'Boot/Trunk',
  'Rear Bumper',
  'Roof',
];

const photoSlotLabels = [
  'Front',
  'Rear',
  'Left',
  'Right',
  'Odometer',
  'Interior',
];

/// Mandatory photo slots for production intake (all 6 required).
const requiredPhotoSlotCount = 6;

class InspectionPhotoSlot {
  final String slot;
  final String label;
  final String? localPath;
  final String? remoteUrl;
  final String? storagePath;
  final bool isUploading;
  final String? uploadError;

  const InspectionPhotoSlot({
    required this.slot,
    required this.label,
    this.localPath,
    this.remoteUrl,
    this.storagePath,
    this.isUploading = false,
    this.uploadError,
  });

  bool get hasPhoto =>
      (remoteUrl != null && remoteUrl!.isNotEmpty) ||
      (localPath != null && localPath!.isNotEmpty);

  InspectionPhotoSlot copyWith({
    String? localPath,
    String? remoteUrl,
    String? storagePath,
    bool? isUploading,
    String? uploadError,
    bool clearError = false,
  }) {
    return InspectionPhotoSlot(
      slot: slot,
      label: label,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      storagePath: storagePath ?? this.storagePath,
      isUploading: isUploading ?? this.isUploading,
      uploadError: clearError ? null : (uploadError ?? this.uploadError),
    );
  }

  factory InspectionPhotoSlot.fromApi(Map<String, dynamic> json) {
    return InspectionPhotoSlot(
      slot: json['slot'] as String? ?? '',
      label: json['label'] as String? ?? '',
      remoteUrl: json['url'] as String?,
      storagePath: json['path'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'slot': slot,
        'label': label,
        'url': remoteUrl ?? '',
        if (storagePath != null) 'path': storagePath,
      };
}

class IntakeInspectionData {
  final String? notes;
  final bool customerAcknowledged;
  final Map<String, InspectionCondition> conditions;
  final Map<String, DamageSeverity> damageZones;
  final List<InspectionPhotoSlot> photos;
  final bool isLoaded;
  final bool isReadOnly;

  const IntakeInspectionData({
    this.notes,
    this.customerAcknowledged = false,
    this.conditions = const {},
    this.damageZones = const {},
    this.photos = const [],
    this.isLoaded = false,
    this.isReadOnly = false,
  });

  bool get hasSavedData => isLoaded && conditions.isNotEmpty;
}
