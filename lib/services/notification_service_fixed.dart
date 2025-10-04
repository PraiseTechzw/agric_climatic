import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:twilio_flutter/twilio_flutter.dart';
import 'logging_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static TwilioFlutter? _twilioFlutter;
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static bool _permissionsRequested = false;

  // Notification channels
  static const String _weatherChannelId = 'weather_alerts';
  static const String _agroChannelId = 'agro_recommendations';
  static const String _systemChannelId = 'system_notifications';

  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions only once
      if (!_permissionsRequested) {
        await _requestPermissions();
        _permissionsRequested = true;
      }

      // Initialize Twilio (you'll need to add your credentials)
      _twilioFlutter = TwilioFlutter(
        accountSid:
            'YOUR_TWILIO_ACCOUNT_SID', // Replace with your Twilio Account SID
        authToken:
            'YOUR_TWILIO_AUTH_TOKEN', // Replace with your Twilio Auth Token
        twilioNumber:
            'YOUR_TWILIO_PHONE_NUMBER', // Replace with your Twilio phone number
      );

      _isInitialized = true;
      _isInitializing = false;
      LoggingService.info('Notification service initialized');
    } catch (e) {
      _isInitializing = false;
      LoggingService.error(
        'Failed to initialize notification service',
        error: e,
      );
      rethrow;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
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

    // Create notification channels
    await _createNotificationChannels();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    // Request permission for Firebase messaging
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      LoggingService.info('Firebase messaging permission granted');
    } else {
      LoggingService.warning('Firebase messaging permission denied');
    }

    // Configure message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel weatherChannel =
        AndroidNotificationChannel(
          _weatherChannelId,
          'Weather Alerts',
          description: 'Notifications for weather alerts and warnings',
          importance: Importance.high,
        );

    const AndroidNotificationChannel agroChannel = AndroidNotificationChannel(
      _agroChannelId,
      'Agricultural Recommendations',
      description: 'Notifications for agricultural recommendations',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Notifications',
      description: 'General system notifications',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(weatherChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(agroChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(systemChannel);
  }

  static Future<void> _requestPermissions() async {
    try {
      // Check current permission status first
      final notificationStatus = await Permission.notification.status;
      if (notificationStatus.isDenied) {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          LoggingService.info('Notification permission granted');
        } else {
          LoggingService.warning('Notification permission denied');
        }
      } else if (notificationStatus.isGranted) {
        LoggingService.info('Notification permission already granted');
      }

      // Check SMS permission status
      final smsStatus = await Permission.sms.status;
      if (smsStatus.isDenied) {
        final result = await Permission.sms.request();
        if (result.isGranted) {
          LoggingService.info('SMS permission granted');
        } else {
          LoggingService.warning('SMS permission denied');
        }
      } else if (smsStatus.isGranted) {
        LoggingService.info('SMS permission already granted');
      }
    } catch (e) {
      LoggingService.error('Error requesting permissions', error: e);
    }
  }

  // Weather alert notifications
  static Future<void> sendWeatherAlert({
    required String title,
    required String message,
    required String severity,
    required String location,
  }) async {
    try {
      // Send push notification
      await _sendLocalNotification(
        title: '🌦️ Weather Alert: $title',
        body: message,
        channelId: _weatherChannelId,
        priority: _getPriorityFromSeverity(severity),
      );

      // Send SMS if critical
      if (severity.toLowerCase() == 'critical') {
        await _sendSMS(
          message: 'CRITICAL WEATHER ALERT: $title - $message',
          location: location,
        );
      }

      LoggingService.info('Weather alert sent: $title');
    } catch (e) {
      LoggingService.error('Failed to send weather alert', error: e);
    }
  }

  // Agricultural recommendation notifications
  static Future<void> sendAgriculturalRecommendation({
    required String title,
    required String message,
    required String cropType,
    required String priority,
  }) async {
    try {
      await _sendLocalNotification(
        title: '🌾 $title',
        body: message,
        channelId: _agroChannelId,
        priority: _getPriorityFromSeverity(priority),
      );

      LoggingService.info('Agricultural recommendation sent: $title');
    } catch (e) {
      LoggingService.error(
        'Failed to send agricultural recommendation',
        error: e,
      );
    }
  }

  // System notifications
  static Future<void> sendSystemNotification({
    required String title,
    required String message,
  }) async {
    try {
      await _sendLocalNotification(
        title: title,
        body: message,
        channelId: _systemChannelId,
        priority: Importance.low,
      );

      LoggingService.info('System notification sent: $title');
    } catch (e) {
      LoggingService.error('Failed to send system notification', error: e);
    }
  }

  // Scheduled notifications
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = _systemChannelId,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Scheduled Notification',
            channelDescription: 'A scheduled notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      LoggingService.info('Notification scheduled: $title');
    } catch (e) {
      LoggingService.error('Failed to schedule notification', error: e);
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      LoggingService.info('Notification cancelled: $id');
    } catch (e) {
      LoggingService.error('Failed to cancel notification', error: e);
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      LoggingService.info('All notifications cancelled');
    } catch (e) {
      LoggingService.error('Failed to cancel all notifications', error: e);
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      LoggingService.error('Failed to get pending notifications', error: e);
      return [];
    }
  }

  // Private helper methods
  static Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required String channelId,
    required Importance priority,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'Default notification channel',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> _sendSMS({
    required String message,
    required String location,
  }) async {
    try {
      if (_twilioFlutter != null) {
        // You would implement SMS sending logic here
        // For now, just log the message
        LoggingService.info('SMS would be sent: $message');
      }
    } catch (e) {
      LoggingService.error('Failed to send SMS', error: e);
    }
  }

  static Importance _getPriorityFromSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'medium':
        return Importance.defaultImportance;
      case 'low':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  // Message handlers
  static void _onNotificationTapped(NotificationResponse response) {
    LoggingService.info('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    LoggingService.info('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await _sendLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      channelId: _systemChannelId,
      priority: Importance.high,
    );
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    LoggingService.info('Message opened app: ${message.messageId}');
    // Handle message that opened the app
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    LoggingService.info('Received background message: ${message.messageId}');
    // Handle background message
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      LoggingService.error('Failed to get FCM token', error: e);
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      LoggingService.info('Subscribed to topic: $topic');
    } catch (e) {
      LoggingService.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      LoggingService.info('Unsubscribed from topic: $topic');
    } catch (e) {
      LoggingService.error(
        'Failed to unsubscribe from topic: $topic',
        error: e,
      );
    }
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      LoggingService.info('Opened app settings');
    } catch (e) {
      LoggingService.error('Failed to open app settings', error: e);
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      LoggingService.error('Failed to check notification status', error: e);
      return false;
    }
  }

  // Request notification permission manually
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      LoggingService.error(
        'Failed to request notification permission',
        error: e,
      );
      return false;
    }
  }
}
