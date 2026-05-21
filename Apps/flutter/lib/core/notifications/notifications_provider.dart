import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_helpers.dart';
import 'notification_models.dart';
import 'notifications_repository.dart';

class NotificationsState {
  final bool isLoading;
  final List<StaffNotificationItem> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState({
    this.isLoading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<StaffNotificationItem>? items,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;

  NotificationsNotifier(this._repo) : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repo.fetchNotifications();
      state = NotificationsState(
        isLoading: false,
        items: page.items,
        unreadCount: page.unreadCount,
      );
    } catch (e) {
      state = NotificationsState(
        isLoading: false,
        items: const [],
        unreadCount: 0,
        errorMessage: failureMessage(e),
      );
    }
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    state = state.copyWith(
      items: state.items
          .map((n) => StaffNotificationItem(
                uuid: n.uuid,
                eventCode: n.eventCode,
                title: n.title,
                body: n.body,
                data: n.data,
                isRead: true,
                readAt: DateTime.now(),
                createdAt: n.createdAt,
              ))
          .toList(),
      unreadCount: 0,
    );
  }

  void prependFromPush(StaffNotificationItem item) {
    final exists = state.items.any((n) => n.uuid == item.uuid);
    if (exists) return;
    state = state.copyWith(
      items: [item, ...state.items],
      unreadCount: state.unreadCount + (item.isRead ? 0 : 1),
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(notificationsRepositoryProvider));
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
