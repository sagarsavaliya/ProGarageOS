import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_models.dart';
import 'notifications_provider.dart';
import 'notifications_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  final NotificationsRepository _repo;
  final NotificationsNotifier _notifications;

  FcmService(this._repo, this._notifications);

  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromPush);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handlePayload(initial.data, initial.notification);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  Future<void> registerTokenIfAvailable() async {
    if (kIsWeb || !_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _repo.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _repo.registerDeviceToken(
          token: newToken,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
      });
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    _handlePayload(message.data, message.notification);
  }

  void _onOpenedFromPush(RemoteMessage message) {
    _handlePayload(message.data, message.notification);
  }

  void _handlePayload(Map<String, dynamic> data, RemoteNotification? notification) {
    final title = notification?.title ?? data['title']?.toString() ?? 'GarageFlow';
    final body = notification?.body ?? data['body']?.toString() ?? '';

    final item = StaffNotificationItem(
      uuid: data['notification_uuid']?.toString() ??
          'push-${DateTime.now().millisecondsSinceEpoch}',
      eventCode: data['event_code']?.toString() ?? 'push',
      title: title,
      body: body,
      data: Map<String, dynamic>.from(data),
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notifications.prependFromPush(item);
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    ref.watch(notificationsRepositoryProvider),
    ref.read(notificationsProvider.notifier),
  );
});
