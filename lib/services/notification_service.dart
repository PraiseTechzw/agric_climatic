import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/agricultural_recommendation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  List<AppNotification> _notifications = [];

  // Initialize notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
    
    // Initialize Local Notifications
    await _initializeLocalNotifications();
    
    // Request permissions
    await _requestPermissions();
    
    // Load saved notifications
    await _loadNotifications();
    
    _isInitialized = true;
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    // Request SMS permission for SMS notifications
    await Permission.sms.request();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    _notifications = notificationsJson
        .map((json) => AppNotification.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((notification) => jsonEncode(notification.toJson()))
        .toList();
    
    await prefs.setStringList('notifications', notificationsJson);
  }

  // Send prediction update notification
  Future<void> sendPredictionUpdate({
    required String location,
    required String cropType,
    required String message,
  }) async {
    final notification = AppNotification(
      id: 'pred_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Weather Prediction Update',
      body: '$message for $cropType in $location',
      type: 'prediction',
      timestamp: DateTime.now(),
      priority: 'high',
      data: {
        'location': location,
        'cropType': cropType,
        'type': 'prediction_update',
      },
    );

    await _sendNotification(notification);
  }

  // Send agricultural recommendation notification
  Future<void> sendAgriculturalRecommendation(AgriculturalRecommendation recommendation) async {
    final notification = AppNotification(
      id: 'rec_${recommendation.id}',
      title: recommendation.title,
      body: recommendation.description,
      type: 'recommendation',
      timestamp: DateTime.now(),
      priority: recommendation.priority,
      data: {
        'recommendationId': recommendation.id,
        'category': recommendation.category,
        'cropType': recommendation.cropType,
        'location': recommendation.location,
      },
    );

    await _sendNotification(notification);
  }

  // Send weather alert notification
  Future<void> sendWeatherAlert({
    required String title,
    required String message,
    required String severity,
    required String location,
  }) async {
    final notification = AppNotification(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: message,
      type: 'weather_alert',
      timestamp: DateTime.now(),
      priority: severity == 'high' ? 'high' : 'normal',
      data: {
        'severity': severity,
        'location': location,
        'type': 'weather_alert',
      },
    );

    await _sendNotification(notification);
  }

  // Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'agric_climatic_channel',
      'AgriClimatic Notifications',
      channelDescription: 'Notifications for agricultural and weather updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Send SMS notification (simulated - would require SMS service integration)
  Future<void> sendSMSNotification({
    required String phoneNumber,
    required String message,
  }) async {
    // In a real implementation, you would integrate with an SMS service
    // like Twilio, AWS SNS, or a local SMS gateway
    print('SMS would be sent to $phoneNumber: $message');
    
    // For now, we'll create a local notification instead
    await sendLocalNotification(
      title: 'SMS Alert',
      body: 'SMS sent to $phoneNumber: $message',
    );
  }

  Future<void> _sendNotification(AppNotification notification) async {
    // Add to local list
    _notifications.insert(0, notification);
    await _saveNotifications();

    // Send push notification
    await sendLocalNotification(
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(notification.toJson()),
    );

    // Send SMS for high priority notifications
    if (notification.priority == 'high') {
      await sendSMSNotification(
        phoneNumber: '+263XXXXXXXXX', // Would be user's phone number
        message: '${notification.title}: ${notification.body}',
      );
    }
  }

  // Get all notifications
  List<AppNotification> getNotifications() {
    return List.from(_notifications);
  }

  // Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  // Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Create notification from message
    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'AgriClimatic Alert',
      body: message.notification?.body ?? 'New update available',
      type: message.data['type'] ?? 'general',
      timestamp: DateTime.now(),
      data: message.data,
    );

    _notifications.insert(0, notification);
    _saveNotifications();
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on notification type
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = AppNotification.fromJson(data);
        markAsRead(notification.id);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}