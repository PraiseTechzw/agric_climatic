import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/weather_alert.dart';
import '../models/agro_climatic_prediction.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  List<NotificationPreference> _preferences = [];

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Initialize Firebase messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Load user preferences
    await _loadPreferences();

    _isInitialized = true;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = prefs.getString('notification_preferences');
    if (preferencesJson != null) {
      final List<dynamic> preferencesList = json.decode(preferencesJson);
      _preferences = preferencesList
          .map((json) => NotificationPreference.fromJson(json))
          .toList();
    } else {
      // Set default preferences
      _preferences = [
        NotificationPreference(
          type: NotificationType.weatherAlert,
          enabled: true,
          channels: [NotificationChannel.push, NotificationChannel.sms],
          severity: ['high', 'critical'],
        ),
        NotificationPreference(
          type: NotificationType.cropRecommendation,
          enabled: true,
          channels: [NotificationChannel.push],
          severity: ['medium', 'high'],
        ),
        NotificationPreference(
          type: NotificationType.irrigationAlert,
          enabled: true,
          channels: [NotificationChannel.push, NotificationChannel.sms],
          severity: ['high'],
        ),
        NotificationPreference(
          type: NotificationType.pestDiseaseAlert,
          enabled: true,
          channels: [NotificationChannel.push],
          severity: ['medium', 'high', 'critical'],
        ),
      ];
      await _savePreferences();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = json.encode(
      _preferences.map((pref) => pref.toJson()).toList(),
    );
    await prefs.setString('notification_preferences', preferencesJson);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      final data = json.decode(payload);
      _handleNotificationAction(data);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Weather Alert',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    _handleNotificationAction(message.data);
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    // Handle different notification actions based on type
    final type = data['type'] as String?;
    switch (type) {
      case 'weather_alert':
        // Navigate to weather alerts screen
        break;
      case 'crop_recommendation':
        // Navigate to crop recommendations
        break;
      case 'irrigation_alert':
        // Navigate to irrigation management
        break;
      case 'pest_disease_alert':
        // Navigate to pest/disease management
        break;
    }
  }

  Future<void> sendWeatherAlert(WeatherAlert alert) async {
    final preference = _getPreference(NotificationType.weatherAlert);
    if (!preference.enabled) return;

    if (!_shouldSendNotification(preference, alert.severity)) return;

    final title = 'Weather Alert: ${alert.title}';
    final body = '${alert.description}\nLocation: ${alert.location}\nDuration: ${alert.duration}';

    if (preference.channels.contains(NotificationChannel.push)) {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: json.encode({
          'type': 'weather_alert',
          'alert_id': alert.id,
        }),
      );
    }

    if (preference.channels.contains(NotificationChannel.sms)) {
      await _sendSMS(title, body);
    }
  }

  Future<void> sendCropRecommendation(CropRecommendation recommendation) async {
    final preference = _getPreference(NotificationType.cropRecommendation);
    if (!preference.enabled) return;

    final title = 'Crop Recommendation: ${recommendation.cropName}';
    final body = 'Optimal planting date: ${recommendation.optimalPlantingDate.day}/${recommendation.optimalPlantingDate.month}\nExpected yield: ${recommendation.expectedYield.toStringAsFixed(1)} tons/ha';

    if (preference.channels.contains(NotificationChannel.push)) {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: json.encode({
          'type': 'crop_recommendation',
          'crop_name': recommendation.cropName,
        }),
      );
    }
  }

  Future<void> sendIrrigationAlert(String message, String severity) async {
    final preference = _getPreference(NotificationType.irrigationAlert);
    if (!preference.enabled) return;

    if (!_shouldSendNotification(preference, severity)) return;

    final title = 'Irrigation Alert';
    final body = message;

    if (preference.channels.contains(NotificationChannel.push)) {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: json.encode({
          'type': 'irrigation_alert',
        }),
      );
    }

    if (preference.channels.contains(NotificationChannel.sms)) {
      await _sendSMS(title, body);
    }
  }

  Future<void> sendPestDiseaseAlert(String pestDisease, String severity, String recommendation) async {
    final preference = _getPreference(NotificationType.pestDiseaseAlert);
    if (!preference.enabled) return;

    if (!_shouldSendNotification(preference, severity)) return;

    final title = 'Pest/Disease Alert: $pestDisease';
    final body = 'Risk Level: $severity\nRecommendation: $recommendation';

    if (preference.channels.contains(NotificationChannel.push)) {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: json.encode({
          'type': 'pest_disease_alert',
          'pest_disease': pestDisease,
        }),
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agric_climatic_channel',
      'Agricultural Climate Alerts',
      channelDescription: 'Notifications for agricultural climate alerts and recommendations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _sendSMS(String title, String body) async {
    // Note: SMS sending requires additional setup and permissions
    // This is a placeholder for SMS integration
    // You would typically integrate with a service like Twilio, AWS SNS, or local SMS gateway
    
    // For now, we'll just log the SMS content
    print('SMS would be sent:');
    print('Title: $title');
    print('Body: $body');
    
    // TODO: Implement actual SMS sending
    // Example with Twilio:
    // await _twilioClient.messages.create(
    //   body: '$title\n\n$body',
    //   from: '+1234567890',
    //   to: '+0987654321',
    // );
  }

  NotificationPreference _getPreference(NotificationType type) {
    return _preferences.firstWhere(
      (pref) => pref.type == type,
      orElse: () => NotificationPreference(
        type: type,
        enabled: false,
        channels: [],
        severity: [],
      ),
    );
  }

  bool _shouldSendNotification(NotificationPreference preference, String severity) {
    return preference.severity.contains(severity.toLowerCase());
  }

  Future<void> updatePreference(NotificationPreference preference) async {
    final index = _preferences.indexWhere((p) => p.type == preference.type);
    if (index != -1) {
      _preferences[index] = preference;
    } else {
      _preferences.add(preference);
    }
    await _savePreferences();
  }

  List<NotificationPreference> get preferences => _preferences;

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

enum NotificationType {
  weatherAlert,
  cropRecommendation,
  irrigationAlert,
  pestDiseaseAlert,
}

enum NotificationChannel {
  push,
  sms,
  email,
}

class NotificationPreference {
  final NotificationType type;
  final bool enabled;
  final List<NotificationChannel> channels;
  final List<String> severity;

  NotificationPreference({
    required this.type,
    required this.enabled,
    required this.channels,
    required this.severity,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.weatherAlert,
      ),
      enabled: json['enabled'] ?? false,
      channels: (json['channels'] as List<dynamic>?)
          ?.map((e) => NotificationChannel.values.firstWhere(
                (c) => c.toString() == 'NotificationChannel.$e',
                orElse: () => NotificationChannel.push,
              ))
          .toList() ?? [],
      severity: List<String>.from(json['severity'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'enabled': enabled,
      'channels': channels.map((c) => c.toString().split('.').last).toList(),
      'severity': severity,
    };
  }
}
