import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationRepository _notificationRepository;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _recipientUserId;

  NotificationProvider({
    required INotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  Future<void> addNotification(NotificationItem item) async {
    await _notificationRepository.addNotification(item);
    if (item.recipientUserId == _recipientUserId) {
      _notifications = [item, ..._notifications];
      notifyListeners();
    }
  }

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get recipientUserId => _recipientUserId;
  bool get isLoading => _isLoading;

  void setRecipient(String? recipientUserId) {
    if (_recipientUserId == recipientUserId) return;
    _recipientUserId = recipientUserId;
    _notifications = [];
    if (recipientUserId != null) fetchNotifications();
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    final recipientUserId = _recipientUserId;
    if (recipientUserId == null) {
      _notifications = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final notifications = await _notificationRepository.getNotifications(
        recipientUserId,
      );
      if (_recipientUserId == recipientUserId) _notifications = notifications;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final recipient = _recipientUserId;
    if (recipient == null) return;
    await _notificationRepository.markAsRead(id, recipient);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final recipient = _recipientUserId;
    if (recipient == null) return;
    await _notificationRepository.markAllAsRead(recipient);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
