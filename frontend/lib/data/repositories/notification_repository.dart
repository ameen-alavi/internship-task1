import '../mock/mock_notifications.dart';
import '../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationItem>> getNotifications(String recipientUserId);
  Future<void> markAsRead(String id, String recipientUserId);
  Future<void> markAllAsRead(String recipientUserId);
  Future<void> addNotification(NotificationItem item);
}

class MockNotificationRepository implements INotificationRepository {
  final List<NotificationItem> _notifications = List.from(
    MockNotifications.initialNotifications,
  );

  @override
  Future<List<NotificationItem>> getNotifications(
    String recipientUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(
      _notifications.where((n) => n.recipientUserId == recipientUserId),
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markAsRead(String id, String recipientUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere(
      (n) => n.id == id && n.recipientUserId == recipientUserId,
    );
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String recipientUserId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUserId == recipientUserId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> addNotification(NotificationItem item) async {
    _notifications.insert(0, item);
  }
}
