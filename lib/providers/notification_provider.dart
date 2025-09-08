import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeAlerts => _notifications.where((n) => !n.isRead).length;
  int get smsCount => _notifications.where((n) => n.type == 'sms').length;
  int get pushCount => _notifications.where((n) => n.type == 'push').length;

  Future<void> loadNotifications() async {
    _setLoading(true);
    try {
      _notifications = await _notificationService.getNotifications();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendNotification(AppNotification notification) async {
    try {
      await _notificationService.sendNotification(notification);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> dismissNotification(String notificationId) async {
    try {
      await _notificationService.dismissNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
