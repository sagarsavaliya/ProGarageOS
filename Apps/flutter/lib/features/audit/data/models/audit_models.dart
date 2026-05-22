// Audit log entries — GET /api/audit-logs

class AuditLogEntry {
  final int id;
  final String actionType;
  final String targetType;
  final int? targetId;
  final String? notes;
  final DateTime createdAt;
  final AuditLogUser? user;

  const AuditLogEntry({
    required this.id,
    required this.actionType,
    required this.targetType,
    this.targetId,
    this.notes,
    required this.createdAt,
    this.user,
  });

  String get actionLabel => actionType.replaceAll('.', ' · ').replaceAll('_', ' ');

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        actionType: json['action_type'] as String? ?? '',
        targetType: json['target_type'] as String? ?? '',
        targetId: (json['target_id'] as num?)?.toInt(),
        notes: json['notes'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        user: json['user'] != null
            ? AuditLogUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}

class AuditLogUser {
  final String name;
  final String? role;

  const AuditLogUser({required this.name, this.role});

  factory AuditLogUser.fromJson(Map<String, dynamic> json) => AuditLogUser(
        name: json['name'] as String? ?? 'Staff',
        role: json['role'] as String?,
      );
}

class PaginatedAuditLogs {
  final List<AuditLogEntry> data;

  const PaginatedAuditLogs({required this.data});

  factory PaginatedAuditLogs.fromJson(Map<String, dynamic> json) =>
      PaginatedAuditLogs(
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
