class StaffNotificationItem {
  final String uuid;
  final String eventCode;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const StaffNotificationItem({
    required this.uuid,
    required this.eventCode,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  String? get jobUuid => data['job_uuid'] as String?;

  factory StaffNotificationItem.fromJson(Map<String, dynamic> json) {
    return StaffNotificationItem(
      uuid: json['uuid'] as String? ?? '',
      eventCode: json['event_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationsPage {
  final List<StaffNotificationItem> items;
  final int unreadCount;

  const NotificationsPage({required this.items, required this.unreadCount});
}

List<StaffNotificationItem> notificationsDemoData() => [
      StaffNotificationItem(
        uuid: 'ntf-demo-001',
        eventCode: 'job_status_changed',
        title: 'JOB-2026-0047 updated',
        body: 'Status: Estimate Pending',
        data: {'job_uuid': 'job-demo-001', 'type': 'job', 'status': 'estimate_pending'},
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      StaffNotificationItem(
        uuid: 'ntf-demo-002',
        eventCode: 'low_stock',
        title: 'Low stock alert',
        body: 'Engine Oil 10W-40 — 2 units remaining',
        data: {'type': 'inventory'},
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      StaffNotificationItem(
        uuid: 'ntf-demo-003',
        eventCode: 'job_status_changed',
        title: 'JOB-2026-0044 ready',
        body: 'Toyota Innova · Sunita Gupta — Ready for delivery',
        data: {'job_uuid': 'job-demo-002', 'type': 'job', 'status': 'ready_for_delivery'},
        isRead: true,
        readAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
      ),
    ];
