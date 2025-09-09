import 'package:flutter/foundation.dart';
import 'logging_service.dart';

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentService {
  static Environment _currentEnvironment = Environment.development;
  
  // API Configuration
  static const String _supabaseUrl = 'https://vivvsratuajxnjhrbojj.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpdnZzcmF0dWFqeG5qaHJib2pqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0MjQzNTEsImV4cCI6MjA3MzAwMDM1MX0.mgNoeddlkErNvXtp5OqwXZK2Vv0wyGbdty65YIkkUdc';
  
  // Open-Meteo API Configuration
  static const String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  
  // Firebase Configuration
  static const String _firebaseProjectId = 'agric-climatic';
  
  // App Configuration
  static const String _appName = 'AgriClimatic';
  static const String _appVersion = '1.0.0';
  static const String _appBuildNumber = '1';
  
  // Zimbabwe-specific configuration
  static const String _defaultCountry = 'Zimbabwe';
  static const String _defaultTimezone = 'Africa/Harare';
  static const String _defaultLanguage = 'en';
  
  // Cache configuration
  static const Duration _cacheExpiration = Duration(hours: 1);
  static const Duration _weatherCacheExpiration = Duration(minutes: 30);
  static const Duration _predictionCacheExpiration = Duration(hours: 6);
  
  // API rate limiting
  static const int _maxApiRetries = 3;
  static const Duration _apiRetryDelay = Duration(seconds: 2);
  static const Duration _apiTimeout = Duration(seconds: 30);
  
  // Notification configuration
  static const Duration _notificationCheckInterval = Duration(minutes: 15);
  static const int _maxNotificationsPerDay = 10;
  
  // Logging configuration
  static const bool _enableDetailedLogging = kDebugMode;
  static const bool _enablePerformanceLogging = kDebugMode;
  static const bool _enableApiLogging = kDebugMode;
  
  static void initialize() {
    // Determine environment based on build mode
    if (kDebugMode) {
      _currentEnvironment = Environment.development;
    } else if (kProfileMode) {
      _currentEnvironment = Environment.staging;
    } else {
      _currentEnvironment = Environment.production;
    }
    
    LoggingService.info('Environment initialized', extra: {
      'environment': _currentEnvironment.name,
      'is_debug': kDebugMode,
      'is_profile': kProfileMode,
      'is_release': kReleaseMode,
    });
  }
  
  // Getters
  static Environment get currentEnvironment => _currentEnvironment;
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  // API Configuration
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static String get openMeteoBaseUrl => _openMeteoBaseUrl;
  static String get firebaseProjectId => _firebaseProjectId;
  
  // App Configuration
  static String get appName => _appName;
  static String get appVersion => _appVersion;
  static String get appBuildNumber => _appBuildNumber;
  
  // Location Configuration
  static String get defaultCountry => _defaultCountry;
  static String get defaultTimezone => _defaultTimezone;
  static String get defaultLanguage => _defaultLanguage;
  
  // Cache Configuration
  static Duration get cacheExpiration => _cacheExpiration;
  static Duration get weatherCacheExpiration => _weatherCacheExpiration;
  static Duration get predictionCacheExpiration => _predictionCacheExpiration;
  
  // API Configuration
  static int get maxApiRetries => _maxApiRetries;
  static Duration get apiRetryDelay => _apiRetryDelay;
  static Duration get apiTimeout => _apiTimeout;
  
  // Notification Configuration
  static Duration get notificationCheckInterval => _notificationCheckInterval;
  static int get maxNotificationsPerDay => _maxNotificationsPerDay;
  
  // Logging Configuration
  static bool get enableDetailedLogging => _enableDetailedLogging;
  static bool get enablePerformanceLogging => _enablePerformanceLogging;
  static bool get enableApiLogging => _enableApiLogging;
  
  // Environment-specific configurations
  static bool get enableCrashReporting => isProduction;
  static bool get enableAnalytics => isProduction;
  static bool get enablePerformanceMonitoring => isProduction;
  static bool get enableDebugLogging => isDevelopment;
  
  // API endpoints
  static String get weatherApiUrl => '$_openMeteoBaseUrl/forecast';
  static String get soilApiUrl => '$_openMeteoBaseUrl/soil';
  static String get historicalApiUrl => '$_openMeteoBaseUrl/historical';
  
  // Database collections
  static String get weatherDataCollection => 'weather_data';
  static String get soilDataCollection => 'soil_data';
  static String get predictionsCollection => 'predictions';
  static String get alertsCollection => 'weather_alerts';
  static String get userDataCollection => 'user_data';
  static String get analyticsCollection => 'analytics';
  
  // Security configuration
  static bool get requireAuthentication => isProduction;
  static bool get enableDataEncryption => isProduction;
  static bool get enableApiKeyValidation => isProduction;
  
  // Performance configuration
  static int get maxConcurrentRequests => isProduction ? 5 : 10;
  static Duration get requestTimeout => isProduction ? const Duration(seconds: 30) : const Duration(seconds: 60);
  static int get maxCacheSize => isProduction ? 100 : 50;
  
  // Feature flags
  static bool get enableOfflineMode => true;
  static bool get enablePushNotifications => true;
  static bool get enableLocationServices => true;
  static bool get enableBackgroundSync => isProduction;
  static bool get enableDataExport => true;
  static bool get enableAdvancedAnalytics => isProduction;
  
  // Zimbabwe-specific feature flags
  static bool get enableZimbabweWeatherData => true;
  static bool get enableZimbabweCropData => true;
  static bool get enableZimbabweSoilData => true;
  static bool get enableZimbabweAlerts => true;
  
  // Development-only features
  static bool get enableMockData => isDevelopment;
  static bool get enableDebugMenu => isDevelopment;
  static bool get enableTestMode => isDevelopment;
  
  // Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig() {
    return {
      'environment': _currentEnvironment.name,
      'app_name': _appName,
      'app_version': _appVersion,
      'app_build_number': _appBuildNumber,
      'is_debug': kDebugMode,
      'is_profile': kProfileMode,
      'is_release': kReleaseMode,
      'enable_crash_reporting': enableCrashReporting,
      'enable_analytics': enableAnalytics,
      'enable_performance_monitoring': enablePerformanceMonitoring,
      'enable_debug_logging': enableDebugLogging,
      'enable_offline_mode': enableOfflineMode,
      'enable_push_notifications': enablePushNotifications,
      'enable_location_services': enableLocationServices,
      'enable_background_sync': enableBackgroundSync,
      'enable_data_export': enableDataExport,
      'enable_advanced_analytics': enableAdvancedAnalytics,
      'enable_zimbabwe_weather_data': enableZimbabweWeatherData,
      'enable_zimbabwe_crop_data': enableZimbabweCropData,
      'enable_zimbabwe_soil_data': enableZimbabweSoilData,
      'enable_zimbabwe_alerts': enableZimbabweAlerts,
      'enable_mock_data': enableMockData,
      'enable_debug_menu': enableDebugMenu,
      'enable_test_mode': enableTestMode,
    };
  }
  
  // Validate configuration
  static bool validateConfiguration() {
    try {
      // Validate required URLs
      if (_supabaseUrl.isEmpty || _openMeteoBaseUrl.isEmpty) {
        LoggingService.error('Required API URLs are empty');
        return false;
      }
      
      // Validate API keys
      if (_supabaseAnonKey.isEmpty) {
        LoggingService.error('Supabase API key is empty');
        return false;
      }
      
      // Validate app configuration
      if (_appName.isEmpty || _appVersion.isEmpty) {
        LoggingService.error('App configuration is invalid');
        return false;
      }
      
      LoggingService.info('Configuration validation passed');
      return true;
    } catch (e) {
      LoggingService.error('Configuration validation failed', error: e);
      return false;
    }
  }
}
