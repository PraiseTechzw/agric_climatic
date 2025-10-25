import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'logging_service.dart';
import 'user_profile_service.dart';
import 'environment_service.dart';
import 'vonage_sms_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  // Infobip uses simple HTTPS; no SDK needed
  static bool _isInitialized = false;
  // Removed unused fields: _isInitializing, _permissionsRequested

  // Notification channels
  static const String _weatherChannelId = 'weather_alerts';
  static const String _agroChannelId = 'agro_recommendations';
  static const String _systemChannelId = 'system_notifications';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database and set local location
      try {
        tzData.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Africa/Harare'));
      } catch (_) {}

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions
      await _requestPermissions();

      // Initialize Vonage SMS service
      await _initializeVonageSMS();

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
    // Only request FCM permission on iOS/macOS; Android grants at install time
    try {
      if (Platform.isIOS || Platform.isMacOS) {
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
      }
    } catch (e) {
      // Ignore duplicate permission requests
      LoggingService.warning(
        'Firebase messaging permission request skipped',
        extra: {'error': e.toString()},
      );
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
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

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(weatherChannel);
        await androidPlugin.createNotificationChannel(agroChannel);
        await androidPlugin.createNotificationChannel(systemChannel);
      }
    }
  }

  static Future<void> _initializeVonageSMS() async {
    try {
      LoggingService.info(
        'Initializing Vonage SMS with credentials',
        extra: {
          'api_key': EnvironmentService.vonageApiKey,
          'api_secret': EnvironmentService.vonageApiSecret,
          'from_number': EnvironmentService.vonageFrom,
          'api_key_length': EnvironmentService.vonageApiKey.length,
          'api_secret_length': EnvironmentService.vonageApiSecret.length,
        },
      );

      await VonageSMSService.initialize(
        apiKey: EnvironmentService.vonageApiKey,
        apiSecret: EnvironmentService.vonageApiSecret,
        fromNumber: EnvironmentService.vonageFrom,
      );
      LoggingService.info('Vonage SMS service initialized successfully');
    } catch (e) {
      LoggingService.warning(
        'Failed to initialize Vonage SMS service',
        extra: {'error': e.toString()},
      );
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      // Request notification permission
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

      // Request SMS permission (only on Android)
      if (Platform.isAndroid) {
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
    bool sendSmsIfCritical = true,
  }) async {
    try {
      LoggingService.info(
        'Dispatching weather alert',
        extra: {
          'title': title,
          'severity': severity,
          'location': location,
          'sendSmsIfCritical': sendSmsIfCritical,
        },
      );
      // Send push notification
      await _sendLocalNotification(
        title: '🌦️ Weather Alert: $title',
        body: message,
        channelId: _weatherChannelId,
        priority: _getPriorityFromSeverity(severity),
      );

      // Send SMS for critical alerts - ALWAYS send for high/critical/severe
      if (severity.toLowerCase() == 'high' ||
          severity.toLowerCase() == 'critical' ||
          severity.toLowerCase() == 'severe') {
        LoggingService.info('Attempting SMS send for critical alert');
        await _sendSMS(
          message:
              'AgriClimatic Alert: $title - $message (Location: $location)',
        );
      } else {
        LoggingService.info(
          'SMS not sent - severity not critical enough',
          extra: {'severity': severity},
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
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportanceFromPriority(priority),
      priority: priority,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data?.toString(),
    );
  }

  // Send SMS using Vonage or Infobip (with fallback)
  static Future<void> _sendSMS({
    required String message,
    String? phoneNumber,
    String? clientRef,
  }) async {
    try {
      LoggingService.info('Preparing SMS send');
      // Use saved user phone if not provided
      final recipientNumber = phoneNumber ?? await _getDefaultUserPhone();
      if (recipientNumber == null || recipientNumber.isEmpty) {
        LoggingService.warning(
          'No recipient phone available, skipping SMS',
          extra: {
            'reason': 'No phone number found in user profile or provided',
            'user_authenticated': phoneNumber != null,
          },
        );
        return;
      }
      LoggingService.info(
        'Resolved recipient number from user profile',
        extra: {
          'to': recipientNumber,
          'source': phoneNumber != null ? 'provided' : 'user_profile',
        },
      );

      // Send SMS via Vonage only
      if (VonageSMSService.isInitialized) {
        try {
          LoggingService.info('Attempting SMS send via Vonage...');
          final response = await VonageSMSService.sendSMS(
            to: recipientNumber,
            text: message,
            clientRef: clientRef,
          );

          if (response.isSuccess) {
            LoggingService.info(
              'SMS sent successfully via Vonage',
              extra: {
                'message_id': response.firstMessageId,
                'status': response.firstStatus,
              },
            );
          } else {
            LoggingService.error(
              'Vonage SMS failed: ${response.firstStatus}',
              extra: {'status': response.firstStatus},
            );
            throw Exception('Vonage SMS failed: ${response.firstStatus}');
          }
        } catch (e) {
          LoggingService.error('Vonage SMS error: ${e.toString()}');
          rethrow;
        }
      } else {
        LoggingService.error('Vonage SMS service not initialized');
        throw Exception('Vonage SMS service not initialized');
      }
    } catch (e) {
      LoggingService.error('Failed to send SMS', error: e);
    }
  }

  static Future<String?> _getDefaultUserPhone() async {
    try {
      // First check if user is authenticated
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        LoggingService.warning(
          'No authenticated user found - cannot retrieve phone number',
        );
        return null;
      }

      LoggingService.info(
        'Retrieving phone number for authenticated user',
        extra: {'user_id': currentUser.uid, 'email': currentUser.email},
      );

      final profile = await UserProfileService.getCurrentUserProfile();
      String? phone = profile?['phone_e164'] as String?;

      // Ensure phone number has +263 prefix for Zimbabwe
      if (phone != null && phone.isNotEmpty) {
        // Remove any spaces and format properly
        phone = phone.replaceAll(' ', '').trim();

        // If it doesn't start with +263, add it
        if (!phone.startsWith('+263')) {
          if (phone.startsWith('263')) {
            phone = '+$phone';
          } else if (phone.startsWith('0')) {
            // Remove leading 0 and add +263
            phone = '+263${phone.substring(1)}';
          } else {
            // Add +263 prefix
            phone = '+263$phone';
          }
        }

        // Validate the final phone number format
        if (phone.length >= 12 && phone.startsWith('+263')) {
          LoggingService.info(
            'Retrieved user phone number from profile',
            extra: {'phone': phone, 'user_id': currentUser.uid},
          );
          return phone;
        } else {
          LoggingService.warning(
            'Invalid phone number format in user profile',
            extra: {'phone': phone, 'user_id': currentUser.uid},
          );
          return null;
        }
      } else {
        LoggingService.warning(
          'No phone number found in user profile',
          extra: {
            'user_id': currentUser.uid,
            'profile_exists': profile != null,
            'profile_keys': profile?.keys.toList(),
          },
        );
        return null;
      }
    } catch (e) {
      LoggingService.error(
        'Failed to retrieve user phone number from profile',
        error: e,
      );
      return null;
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

  // Get channel name from channel ID
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case _weatherChannelId:
        return 'Weather Alerts';
      case _agroChannelId:
        return 'Agricultural Recommendations';
      case _systemChannelId:
        return 'System Notifications';
      default:
        return 'AgriClimatic Notifications';
    }
  }

  // Get channel description from channel ID
  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _weatherChannelId:
        return 'Notifications for weather alerts and warnings';
      case _agroChannelId:
        return 'Notifications for farming recommendations and advice';
      case _systemChannelId:
        return 'General system notifications';
      default:
        return 'Notifications for agricultural climate predictions';
    }
  }

  // Get importance from priority
  static Importance _getImportanceFromPriority(Priority priority) {
    switch (priority) {
      case Priority.max:
        return Importance.max;
      case Priority.high:
        return Importance.high;
      case Priority.low:
        return Importance.low;
      default:
        return Importance.defaultImportance;
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

  // Schedule recurring notifications
  static Future<void> scheduleRecurringNotifications() async {
    try {
      // Schedule six-hourly system updates
      await _scheduleSixHourlyUpdates();

      // Schedule daily weather and recommendations at 06:30
      await _scheduleDailyWeatherAndRecommendations();

      // Schedule weekly SMS summary every Monday at 06:30
      await _scheduleWeeklySMSSummary();

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

  // Schedule notifications every 6 hours (00:00, 06:00, 12:00, 18:00)
  static Future<void> _scheduleSixHourlyUpdates() async {
    // Use distinct IDs to avoid clashing with other schedules
    const ids = [10, 11, 12, 13];
    const times = [
      [0, 0],
      [6, 0],
      [12, 0],
      [18, 0],
    ];

    for (var i = 0; i < times.length; i++) {
      final hour = times[i][0];
      final minute = times[i][1];
      await _localNotifications.zonedSchedule(
        ids[i],
        '6-hour Update',
        'Regular update every 6 hours.',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'six_hour_updates',
            '6-hour Updates',
            channelDescription: 'Repeating updates every 6 hours',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> _scheduleDailyWeatherAndRecommendations() async {
    // Schedule for 06:30 AM daily
    await _localNotifications.zonedSchedule(
      1,
      'Daily Weather & Recommendations',
      'Today\'s weather conditions and farming recommendations',
      _nextInstanceOfTime(6, 30),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_weather',
          'Daily Weather & Recommendations',
          channelDescription: 'Daily weather and recommendation notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleWeeklySMSSummary() async {
    // Schedule for Monday 06:30 AM - Weekly SMS Summary
    await _localNotifications.zonedSchedule(
      2,
      'Weekly SMS Summary',
      'Sending weekly weather and recommendation summary via SMS',
      _nextInstanceOfTime(6, 30, DateTime.monday),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_sms',
          'Weekly SMS Summary',
          channelDescription: 'Weekly SMS summary notifications',
          importance: Importance.high,
          priority: Priority.high,
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

  // Send weekly SMS summary
  static Future<void> sendWeeklySMSSummary({
    required String location,
    required Map<String, dynamic> weeklyWeatherData,
    required List<String> weeklyRecommendations,
  }) async {
    try {
      final message = _buildWeeklySMSMessage(
        location,
        weeklyWeatherData,
        weeklyRecommendations,
      );

      await _sendSMS(message: message);

      LoggingService.info(
        'Weekly SMS summary sent',
        extra: {'location': location, 'message_length': message.length},
      );
    } catch (e) {
      LoggingService.error('Failed to send weekly SMS summary', error: e);
    }
  }

  // Send daily weather and recommendations
  static Future<void> sendDailyWeatherAndRecommendations({
    required String location,
    required Map<String, dynamic> weatherData,
    required List<String> recommendations,
  }) async {
    try {
      // Send notification
      await sendSystemNotification(
        title: 'Daily Weather & Recommendations',
        message: _buildDailyNotificationMessage(weatherData, recommendations),
      );

      LoggingService.info(
        'Daily weather and recommendations sent',
        extra: {'location': location},
      );
    } catch (e) {
      LoggingService.error(
        'Failed to send daily weather and recommendations',
        error: e,
      );
    }
  }

  // Build weekly SMS message
  static String _buildWeeklySMSMessage(
    String location,
    Map<String, dynamic> weeklyWeatherData,
    List<String> recommendations,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('AgriClimatic Weekly Summary - $location');
    buffer.writeln('Week of ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln('');

    // Weather summary
    buffer.writeln('WEATHER SUMMARY:');
    buffer.writeln(
      'Avg Temp: ${weeklyWeatherData['avgTemp']?.toStringAsFixed(1) ?? 'N/A'}°C',
    );
    buffer.writeln(
      'Total Rain: ${weeklyWeatherData['totalRain']?.toStringAsFixed(1) ?? 'N/A'}mm',
    );
    buffer.writeln(
      'Max Wind: ${weeklyWeatherData['maxWind']?.toStringAsFixed(1) ?? 'N/A'}km/h',
    );
    buffer.writeln('');

    // Recommendations
    buffer.writeln('KEY RECOMMENDATIONS:');
    for (int i = 0; i < recommendations.length && i < 5; i++) {
      buffer.writeln('• ${recommendations[i]}');
    }

    buffer.writeln('');
    buffer.writeln('For detailed info, check the AgriClimatic app.');

    return buffer.toString();
  }

  // Build daily notification message
  static String _buildDailyNotificationMessage(
    Map<String, dynamic> weatherData,
    List<String> recommendations,
  ) {
    final temp = weatherData['temperature']?.toStringAsFixed(1) ?? 'N/A';
    final rain = weatherData['precipitation']?.toStringAsFixed(1) ?? 'N/A';
    final topRecommendation = recommendations.isNotEmpty
        ? recommendations.first
        : 'Check app for details';

    return 'Today: $temp°C, ${rain}mm rain. Top tip: $topRecommendation';
  }

  // Get SMS service status
  static Map<String, dynamic> getSMSServiceStatus() {
    return {
      'vonage_initialized': VonageSMSService.isInitialized,
      'vonage_status': VonageSMSService.getServiceStatus(),
    };
  }

  /// Check if SMS can be sent (user has phone number and service is configured)
  static Future<Map<String, dynamic>> canSendSMS() async {
    try {
      final hasPhone = await UserProfileService.hasValidPhoneNumber();
      final vonageReady = VonageSMSService.isInitialized;

      return {
        'can_send': hasPhone && vonageReady,
        'has_phone_number': hasPhone,
        'vonage_ready': vonageReady,
        'services_configured': vonageReady,
      };
    } catch (e) {
      return {
        'can_send': false,
        'has_phone_number': false,
        'vonage_ready': false,
        'services_configured': false,
        'error': e.toString(),
      };
    }
  }

  /// Get user phone number status and provide guidance
  static Future<Map<String, dynamic>> getUserPhoneStatus() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        return {
          'authenticated': false,
          'has_phone': false,
          'message': 'User not authenticated',
          'action_required': 'Please sign in to enable SMS notifications',
        };
      }

      final profile = await UserProfileService.getCurrentUserProfile();
      final phone = profile?['phone_e164'] as String?;
      final hasValidPhone =
          phone != null && phone.isNotEmpty && phone.startsWith('+263');

      return {
        'authenticated': true,
        'has_phone': hasValidPhone,
        'phone_number': hasValidPhone ? phone : null,
        'profile_exists': profile != null,
        'message': hasValidPhone
            ? 'Phone number configured for SMS notifications'
            : 'No phone number found in profile',
        'action_required': hasValidPhone
            ? null
            : 'Please add your phone number in the app settings to enable SMS notifications',
      };
    } catch (e) {
      return {
        'authenticated': false,
        'has_phone': false,
        'error': e.toString(),
        'message': 'Failed to check phone status',
        'action_required':
            'Please check your internet connection and try again',
      };
    }
  }
}

// Top-level function for Firebase background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggingService.info(
    'Background message received',
    extra: {
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    },
  );
}
