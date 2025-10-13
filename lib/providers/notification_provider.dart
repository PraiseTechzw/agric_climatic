import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../models/agricultural_recommendation.dart';
import '../services/notification_service.dart';
import '../services/logging_service.dart';

class NotificationProvider with ChangeNotifier {
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
      await NotificationService.initialize();
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
      // Load notifications from local storage or create sample data
      _notifications = await _loadStoredNotifications();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load stored notifications from local storage
  Future<List<AppNotification>> _loadStoredNotifications() async {
    // For now, return sample notifications for testing
    // In a real app, this would load from local storage or backend service
    return _createSampleNotifications();
  }

  // Create sample notifications for testing
  List<AppNotification> _createSampleNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        title: 'Weather Alert: Heavy Rain Expected',
        body:
            'Heavy rainfall is expected in your area tomorrow. Consider postponing outdoor farming activities.',
        type: 'weather_alert',
        timestamp: now.subtract(const Duration(hours: 2)),
        priority: 'high',
      ),
      AppNotification(
        id: '2',
        title: 'Crop Recommendation: Maize Planting',
        body:
            'Optimal conditions for maize planting are expected this week. Soil moisture levels are ideal.',
        type: 'recommendation',
        timestamp: now.subtract(const Duration(days: 1)),
        priority: 'normal',
      ),
      AppNotification(
        id: '3',
        title: 'Weather Prediction Update',
        body:
            'Long-term weather patterns suggest a dry spell in the coming weeks. Plan irrigation accordingly.',
        type: 'prediction',
        timestamp: now.subtract(const Duration(days: 2)),
        priority: 'normal',
      ),
    ];
  }

  // Send prediction update notification
  Future<void> sendPredictionUpdate({
    required String location,
    required String cropType,
    required String message,
  }) async {
    try {
      await NotificationService.sendPredictionUpdate(
        title: 'Prediction Update',
        message: message,
        predictionType: 'crop_prediction',
        location: location,
      );
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to send prediction update: $e';
      notifyListeners();
    }
  }

  // Send agricultural recommendation notification
  Future<void> sendAgriculturalRecommendation(
    AgriculturalRecommendation recommendation,
  ) async {
    try {
      await NotificationService.sendAgroRecommendation(
        title: recommendation.title,
        message: recommendation.description,
        cropType: recommendation.cropType,
        location: recommendation.location,
      );
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
      await NotificationService.sendWeatherAlert(
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
    String type = 'general',
    String priority = 'normal',
  }) async {
    try {
      await NotificationService.sendSystemNotification(
        title: title,
        message: body,
      );

      // Add to local notifications list
      final newNotification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        priority: priority,
      );

      _notifications.insert(0, newNotification);
      notifyListeners();
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
      // SMS functionality would be implemented here
      // For now, just log the action
      print('SMS would be sent to $phoneNumber: $message');
    } catch (e) {
      _error = 'Failed to send SMS notification: $e';
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Mark as read functionality would be implemented here
      // For now, just update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to mark notification as read: $e';
      notifyListeners();
    }
  }

  // Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      // Dismiss notification functionality would be implemented here
      // For now, just remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to dismiss notification: $e';
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
      _notifications.clear();
      await loadNotifications();
    } catch (e) {
      _error = 'Failed to clear notifications: $e';
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
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
      // FCM token functionality would be implemented here
      return null;
    } catch (e) {
      _error = 'Failed to get FCM token: $e';
      notifyListeners();
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      // Topic subscription functionality would be implemented here
      print('Subscribed to topic: $topic');
    } catch (e) {
      _error = 'Failed to subscribe to topic: $e';
      notifyListeners();
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // Topic unsubscription functionality would be implemented here
      print('Unsubscribed from topic: $topic');
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
  List<AppNotification> getNotificationsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _notifications.where((notification) {
      return notification.timestamp.isAfter(
            start.subtract(const Duration(days: 1)),
          ) &&
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

  // Test notification system
  Future<void> testNotificationSystem() async {
    try {
      _setLoading(true);
      _error = null;

      // Test the notification service
      await NotificationService.testNotificationSystem();

      // Add test notifications to the list
      final testNotifications = [
        AppNotification(
          id: 'test_1',
          title: 'Test System Notification',
          body: 'This is a test system notification.',
          type: 'system',
          timestamp: DateTime.now(),
          priority: 'normal',
        ),
        AppNotification(
          id: 'test_2',
          title: 'Test Weather Alert',
          body: 'This is a test weather alert.',
          type: 'weather_alert',
          timestamp: DateTime.now(),
          priority: 'high',
        ),
        AppNotification(
          id: 'test_3',
          title: 'Test Recommendation',
          body: 'This is a test agricultural recommendation.',
          type: 'recommendation',
          timestamp: DateTime.now(),
          priority: 'normal',
        ),
      ];

      _notifications.insertAll(0, testNotifications);
      notifyListeners();

      LoggingService.info('Notification system test completed');
    } catch (e) {
      _error = 'Failed to test notification system: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
