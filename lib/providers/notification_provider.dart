import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../models/agricultural_recommendation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  int get unreadCount => unreadNotifications.length;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _error = null;

    try {
      await _notificationService.initialize();
      await loadNotifications();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _error = null;

    try {
      _notifications = _notificationService.getNotifications();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Send prediction update notification
  Future<void> sendPredictionUpdate({
    required String location,
    required String cropType,
    required String message,
  }) async {
    try {
      await _notificationService.sendPredictionUpdate(
        location: location,
        cropType: cropType,
        message: message,
      );
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to send prediction update: $e';
      notifyListeners();
    }
  }

  // Send agricultural recommendation notification
  Future<void> sendAgriculturalRecommendation(AgriculturalRecommendation recommendation) async {
    try {
      await _notificationService.sendAgriculturalRecommendation(recommendation);
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to send recommendation: $e';
      notifyListeners();
    }
  }

  // Send weather alert notification
  Future<void> sendWeatherAlert({
    required String title,
    required String message,
    required String severity,
    required String location,
  }) async {
    try {
      await _notificationService.sendWeatherAlert(
        title: title,
        message: message,
        severity: severity,
        location: location,
      );
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to send weather alert: $e';
      notifyListeners();
    }
  }

  // Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationService.sendLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to send local notification: $e';
      notifyListeners();
    }
  }

  // Send SMS notification
  Future<void> sendSMSNotification({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      await _notificationService.sendSMSNotification(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      _error = 'Failed to send SMS notification: $e';
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to mark notification as read: $e';
      notifyListeners();
    }
  }

  // Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _notificationService.dismissNotification(notificationId);
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to dismiss notification: $e';
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to clear notifications: $e';
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      for (final notification in unreadNotifications) {
        await _notificationService.markAsRead(notification.id);
      }
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get high priority notifications
  List<AppNotification> getHighPriorityNotifications() {
    return _notifications.where((n) => n.priority == 'high').toList();
  }

  // Get recent notifications (last 7 days)
  List<AppNotification> getRecentNotifications() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications.where((n) => n.timestamp.isAfter(weekAgo)).toList();
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _notificationService.getFCMToken();
    } catch (e) {
      _error = 'Failed to get FCM token: $e';
      notifyListeners();
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
    } catch (e) {
      _error = 'Failed to subscribe to topic: $e';
      notifyListeners();
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      _error = 'Failed to unsubscribe from topic: $e';
      notifyListeners();
    }
  }

  // Get notification statistics
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': _notifications.length,
      'unread': unreadNotifications.length,
      'prediction': getNotificationsByType('prediction').length,
      'recommendation': getNotificationsByType('recommendation').length,
      'weather_alert': getNotificationsByType('weather_alert').length,
      'high_priority': getHighPriorityNotifications().length,
    };

    return stats;
  }

  // Get notifications by date range
  List<AppNotification> getNotificationsByDateRange(DateTime start, DateTime end) {
    return _notifications.where((notification) {
      return notification.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             notification.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Search notifications
  List<AppNotification> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;

    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowercaseQuery) ||
             notification.body.toLowerCase().contains(lowercaseQuery) ||
             notification.type.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get notification by ID
  AppNotification? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}


