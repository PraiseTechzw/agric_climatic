import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions
      await _requestPermissions();

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
      LoggingService.info('Notification service initialized');
    } catch (e) {
      LoggingService.error(
        'Failed to initialize notification service',
        error: e,
      );
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      LoggingService.info('Firebase messaging permission granted');
    } else {
      LoggingService.warning('Firebase messaging permission denied');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> _createNotificationChannels() async {
    const weatherChannel = AndroidNotificationChannel(
      _weatherChannelId,
      'Weather Alerts',
      description: 'Notifications for weather alerts and warnings',
      importance: Importance.high,
      playSound: true,
    );

    const agroChannel = AndroidNotificationChannel(
      _agroChannelId,
      'Agricultural Recommendations',
      description: 'Notifications for farming recommendations and advice',
      importance: Importance.high,
      playSound: true,
    );

    const systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Notifications',
      description: 'General system notifications',
      importance: Importance.defaultImportance,
      playSound: false,
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
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      LoggingService.info('Notification permission granted');
    } else {
      LoggingService.warning('Notification permission denied');
    }

    // Request SMS permission
    final smsStatus = await Permission.sms.request();
    if (smsStatus.isGranted) {
      LoggingService.info('SMS permission granted');
    } else {
      LoggingService.warning('SMS permission denied');
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

      // Send SMS for critical alerts
      if (severity.toLowerCase() == 'high' ||
          severity.toLowerCase() == 'critical') {
        await _sendSMS(
          message:
              'AgriClimatic Alert: $title - $message (Location: $location)',
        );
      }

      LoggingService.info(
        'Weather alert sent',
        extra: {'title': title, 'severity': severity, 'location': location},
      );
    } catch (e) {
      LoggingService.error('Failed to send weather alert', error: e);
    }
  }

  // Agricultural recommendation notifications
  static Future<void> sendAgroRecommendation({
    required String title,
    required String message,
    required String cropType,
    required String location,
  }) async {
    try {
      await _sendLocalNotification(
        title: '🌱 $title',
        body: message,
        channelId: _agroChannelId,
        priority: Priority.high,
      );

      LoggingService.info(
        'Agro recommendation sent',
        extra: {'title': title, 'crop_type': cropType, 'location': location},
      );
    } catch (e) {
      LoggingService.error('Failed to send agro recommendation', error: e);
    }
  }

  // Long-term prediction notifications
  static Future<void> sendPredictionUpdate({
    required String title,
    required String message,
    required String predictionType,
    required String location,
  }) async {
    try {
      await _sendLocalNotification(
        title: '📊 $title',
        body: message,
        channelId: _agroChannelId,
        priority: Priority.high,
      );

      LoggingService.info(
        'Prediction update sent',
        extra: {
          'title': title,
          'prediction_type': predictionType,
          'location': location,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to send prediction update', error: e);
    }
  }

  // Pattern analysis notifications
  static Future<void> sendPatternAnalysis({
    required String title,
    required String message,
    required String patternType,
    required String location,
  }) async {
    try {
      await _sendLocalNotification(
        title: '📈 $title',
        body: message,
        channelId: _agroChannelId,
        priority: Priority.high,
      );

      LoggingService.info(
        'Pattern analysis sent',
        extra: {
          'title': title,
          'pattern_type': patternType,
          'location': location,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to send pattern analysis', error: e);
    }
  }

  // System notifications
  static Future<void> sendSystemNotification({
    required String title,
    required String message,
    Priority priority = Priority.high,
  }) async {
    try {
      await _sendLocalNotification(
        title: title,
        body: message,
        channelId: _systemChannelId,
        priority: priority,
      );

      LoggingService.info(
        'System notification sent',
        extra: {'title': title, 'priority': priority.toString()},
      );
    } catch (e) {
      LoggingService.error('Failed to send system notification', error: e);
    }
  }

  // Send local notification
  static Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required String channelId,
    required Priority priority,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agric_climatic',
      'AgriClimatic Notifications',
      channelDescription: 'Notifications for agricultural climate predictions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data != null ? data.toString() : null,
    );
  }

  // Send SMS using Twilio
  static Future<void> _sendSMS({
    required String message,
    String? phoneNumber,
  }) async {
    try {
      if (_twilioFlutter == null) {
        LoggingService.warning('Twilio not initialized, skipping SMS');
        return;
      }

      // Use a default phone number if none provided
      final recipientNumber =
          phoneNumber ??
          '+263XXXXXXXXX'; // Replace with default Zimbabwe number

      // Send SMS using Twilio
      await _twilioFlutter!.sendSMS(
        toNumber: recipientNumber,
        messageBody: message,
      );

      LoggingService.info('SMS sent successfully via Twilio');
    } catch (e) {
      LoggingService.error('Failed to send SMS via Twilio', error: e);

      // Fallback to SMS app if Twilio fails
      try {
        final uri = Uri(scheme: 'sms', queryParameters: {'body': message});
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          LoggingService.info('SMS launched via SMS app as fallback');
        }
      } catch (fallbackError) {
        LoggingService.error('SMS fallback also failed', error: fallbackError);
      }
    }
  }

  // Get priority from severity
  static Priority _getPriorityFromSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Priority.max;
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.high;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    LoggingService.info(
      'Notification tapped',
      extra: {'payload': response.payload},
    );

    // Handle different notification types based on payload
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      // This would be implemented based on your app's navigation structure
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    LoggingService.info(
      'Foreground message received',
      extra: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      },
    );

    // Show local notification for foreground messages
    if (message.notification != null) {
      _sendLocalNotification(
        title: message.notification!.title ?? 'AgriClimatic',
        body: message.notification!.body ?? '',
        channelId: _systemChannelId,
        priority: Priority.high,
        data: message.data,
      );
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    LoggingService.info(
      'Background message received',
      extra: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      },
    );
  }

  // Schedule recurring notifications
  static Future<void> scheduleRecurringNotifications() async {
    try {
      // Schedule daily weather summary
      await _scheduleDailyWeatherSummary();

      // Schedule weekly agro recommendations
      await _scheduleWeeklyAgroRecommendations();

      // Schedule monthly pattern analysis
      await _scheduleMonthlyPatternAnalysis();

      LoggingService.info('Recurring notifications scheduled');
    } catch (e) {
      LoggingService.error(
        'Failed to schedule recurring notifications',
        error: e,
      );
    }
  }

  static Future<void> _scheduleDailyWeatherSummary() async {
    // Schedule for 7:00 AM daily
    await _localNotifications.zonedSchedule(
      1,
      'Daily Weather Summary',
      'Check today\'s weather conditions and farming recommendations',
      _nextInstanceOfTime(7, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_weather',
          'Daily Weather Summary',
          channelDescription: 'Daily weather summary notifications',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleWeeklyAgroRecommendations() async {
    // Schedule for Monday 8:00 AM
    await _localNotifications.zonedSchedule(
      2,
      'Weekly Agricultural Recommendations',
      'Your weekly farming recommendations and crop advice',
      _nextInstanceOfTime(8, 0, DateTime.monday),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_agro',
          'Weekly Agricultural Recommendations',
          channelDescription: 'Weekly agricultural recommendations',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> _scheduleMonthlyPatternAnalysis() async {
    // Schedule for 1st of every month at 9:00 AM
    await _localNotifications.zonedSchedule(
      3,
      'Monthly Pattern Analysis',
      'Monthly weather pattern analysis and long-term predictions',
      _nextInstanceOfTime(9, 0, null, 1),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_patterns',
          'Monthly Pattern Analysis',
          channelDescription: 'Monthly weather pattern analysis',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(
    int hour,
    int minute, [
    int? weekday,
    int? dayOfMonth,
  ]) {
    final now = DateTime.now();
    var scheduledDate = tz.TZDateTime.from(
      now,
      tz.getLocation('Africa/Harare'),
    );

    scheduledDate = tz.TZDateTime(
      scheduledDate.location,
      scheduledDate.year,
      scheduledDate.month,
      dayOfMonth ?? scheduledDate.day,
      hour,
      minute,
    );

    if (weekday != null) {
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    if (scheduledDate.isBefore(now)) {
      if (weekday != null) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else if (dayOfMonth != null) {
        scheduledDate = tz.TZDateTime(
          scheduledDate.location,
          scheduledDate.year,
          scheduledDate.month + 1,
          dayOfMonth,
          hour,
          minute,
        );
      } else {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    return scheduledDate;
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    LoggingService.info('All notifications cancelled');
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    LoggingService.info('Notification $id cancelled');
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
