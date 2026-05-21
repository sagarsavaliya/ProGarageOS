import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'notification_models.dart';

class NotificationsRepository {
  final Dio _dio;

  const NotificationsRepository(this._dio);

  Future<NotificationsPage> fetchNotifications({bool unreadOnly = false}) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: unreadOnly ? {'unread_only': '1'} : null,
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return NotificationsPage(
      items: data.map((e) => StaffNotificationItem.fromJson(e as Map<String, dynamic>)).toList(),
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> registerDeviceToken({
    required String token,
    String platform = 'android',
    String appVersion = '1.0.0',
  }) async {
    try {
      await _dio.post('/device-token', data: {
        'device_token': token,
        'platform': platform,
        'app_version': appVersion,
      });
    } catch (_) {
      // Demo / offline — ignore
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (_) {}
  }

  Future<void> markRead(String uuid) async {
    try {
      await _dio.patch('/notifications/$uuid/read');
    } catch (_) {}
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
