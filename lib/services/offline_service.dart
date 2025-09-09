import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logging_service.dart';
import 'environment_service.dart';

class OfflineService {
  static SharedPreferences? _prefs;
  static bool _isOnline = true;
  static final List<Function> _onlineListeners = [];
  static final List<Function> _offlineListeners = [];
  
  // Cache keys
  static const String _weatherCacheKey = 'weather_cache';
  static const String _soilDataCacheKey = 'soil_data_cache';
  static const String _predictionsCacheKey = 'predictions_cache';
  static const String _alertsCacheKey = 'alerts_cache';
  static const String _userDataCacheKey = 'user_data_cache';
  static const String _lastSyncKey = 'last_sync';
  
  // Cache expiration times
  static const Duration _weatherCacheExpiration = Duration(minutes: 30);
  static const Duration _soilDataCacheExpiration = Duration(hours: 2);
  static const Duration _predictionsCacheExpiration = Duration(hours: 6);
  static const Duration _alertsCacheExpiration = Duration(minutes: 15);
  static const Duration _userDataCacheExpiration = Duration(hours: 24);
  
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check initial connectivity
      await _checkConnectivity();
      
      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        _handleConnectivityChange(result);
      });
      
      LoggingService.info('Offline service initialized');
    } catch (e) {
      LoggingService.error('Failed to initialize offline service', error: e);
    }
  }
  
  static Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      
      LoggingService.info('Connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      LoggingService.error('Failed to check connectivity', error: e);
      _isOnline = false;
    }
  }
  
  static void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOnline != _isOnline) {
      LoggingService.info('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      
      if (_isOnline) {
        _notifyOnlineListeners();
      } else {
        _notifyOfflineListeners();
      }
    }
  }
  
  static void _notifyOnlineListeners() {
    for (final listener in _onlineListeners) {
      try {
        listener();
      } catch (e) {
        LoggingService.error('Error in online listener', error: e);
      }
    }
  }
  
  static void _notifyOfflineListeners() {
    for (final listener in _offlineListeners) {
      try {
        listener();
      } catch (e) {
        LoggingService.error('Error in offline listener', error: e);
      }
    }
  }
  
  // Connectivity status
  static bool get isOnline => _isOnline;
  static bool get isOffline => !_isOnline;
  
  // Add listeners
  static void addOnlineListener(Function listener) {
    _onlineListeners.add(listener);
  }
  
  static void addOfflineListener(Function listener) {
    _offlineListeners.add(listener);
  }
  
  // Remove listeners
  static void removeOnlineListener(Function listener) {
    _onlineListeners.remove(listener);
  }
  
  static void removeOfflineListener(Function listener) {
    _offlineListeners.remove(listener);
  }
  
  // Cache management
  static Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      if (_prefs == null) return;
      
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': EnvironmentService.appVersion,
      };
      
      await _prefs!.setString(key, json.encode(cacheData));
      LoggingService.debug('Data cached for key: $key');
    } catch (e) {
      LoggingService.error('Failed to cache data for key: $key', error: e);
    }
  }
  
  static Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      if (_prefs == null) return null;
      
      final cachedString = _prefs!.getString(key);
      if (cachedString == null) return null;
      
      final cacheData = json.decode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp'] as int);
      final version = cacheData['version'] as String;
      
      // Check if cache is expired
      if (_isCacheExpired(key, timestamp)) {
        LoggingService.debug('Cache expired for key: $key');
        return null;
      }
      
      // Check if version is compatible
      if (version != EnvironmentService.appVersion) {
        LoggingService.debug('Cache version mismatch for key: $key');
        return null;
      }
      
      LoggingService.debug('Cache hit for key: $key');
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggingService.error('Failed to get cached data for key: $key', error: e);
      return null;
    }
  }
  
  static bool _isCacheExpired(String key, DateTime timestamp) {
    final now = DateTime.now();
    final age = now.difference(timestamp);
    
    switch (key) {
      case _weatherCacheKey:
        return age > _weatherCacheExpiration;
      case _soilDataCacheKey:
        return age > _soilDataCacheExpiration;
      case _predictionsCacheKey:
        return age > _predictionsCacheExpiration;
      case _alertsCacheKey:
        return age > _alertsCacheExpiration;
      case _userDataCacheKey:
        return age > _userDataCacheExpiration;
      default:
        return age > const Duration(hours: 1);
    }
  }
  
  static Future<void> clearCache() async {
    try {
      if (_prefs == null) return;
      
      await _prefs!.remove(_weatherCacheKey);
      await _prefs!.remove(_soilDataCacheKey);
      await _prefs!.remove(_predictionsCacheKey);
      await _prefs!.remove(_alertsCacheKey);
      await _prefs!.remove(_userDataCacheKey);
      await _prefs!.remove(_lastSyncKey);
      
      LoggingService.info('Cache cleared');
    } catch (e) {
      LoggingService.error('Failed to clear cache', error: e);
    }
  }
  
  static Future<void> clearExpiredCache() async {
    try {
      if (_prefs == null) return;
      
      final keys = [
        _weatherCacheKey,
        _soilDataCacheKey,
        _predictionsCacheKey,
        _alertsCacheKey,
        _userDataCacheKey,
      ];
      
      for (final key in keys) {
        final cachedData = await getCachedData(key);
        if (cachedData == null) {
          await _prefs!.remove(key);
        }
      }
      
      LoggingService.info('Expired cache cleared');
    } catch (e) {
      LoggingService.error('Failed to clear expired cache', error: e);
    }
  }
  
  // Specific cache methods
  static Future<void> cacheWeatherData(Map<String, dynamic> data) async {
    await cacheData(_weatherCacheKey, data);
  }
  
  static Future<Map<String, dynamic>?> getCachedWeatherData() async {
    return await getCachedData(_weatherCacheKey);
  }
  
  static Future<void> cacheSoilData(Map<String, dynamic> data) async {
    await cacheData(_soilDataCacheKey, data);
  }
  
  static Future<Map<String, dynamic>?> getCachedSoilData() async {
    return await getCachedData(_soilDataCacheKey);
  }
  
  static Future<void> cachePredictions(Map<String, dynamic> data) async {
    await cacheData(_predictionsCacheKey, data);
  }
  
  static Future<Map<String, dynamic>?> getCachedPredictions() async {
    return await getCachedData(_predictionsCacheKey);
  }
  
  static Future<void> cacheAlerts(Map<String, dynamic> data) async {
    await cacheData(_alertsCacheKey, data);
  }
  
  static Future<Map<String, dynamic>?> getCachedAlerts() async {
    return await getCachedData(_alertsCacheKey);
  }
  
  static Future<void> cacheUserData(Map<String, dynamic> data) async {
    await cacheData(_userDataCacheKey, data);
  }
  
  static Future<Map<String, dynamic>?> getCachedUserData() async {
    return await getCachedData(_userDataCacheKey);
  }
  
  // Sync management
  static Future<void> setLastSync(DateTime dateTime) async {
    try {
      if (_prefs == null) return;
      
      await _prefs!.setString(_lastSyncKey, dateTime.toIso8601String());
      LoggingService.debug('Last sync time updated: $dateTime');
    } catch (e) {
      LoggingService.error('Failed to set last sync time', error: e);
    }
  }
  
  static Future<DateTime?> getLastSync() async {
    try {
      if (_prefs == null) return null;
      
      final lastSyncString = _prefs!.getString(_lastSyncKey);
      if (lastSyncString == null) return null;
      
      return DateTime.parse(lastSyncString);
    } catch (e) {
      LoggingService.error('Failed to get last sync time', error: e);
      return null;
    }
  }
  
  static Future<bool> needsSync() async {
    try {
      final lastSync = await getLastSync();
      if (lastSync == null) return true;
      
      final now = DateTime.now();
      final timeSinceSync = now.difference(lastSync);
      
      // Sync if more than 1 hour has passed
      return timeSinceSync > const Duration(hours: 1);
    } catch (e) {
      LoggingService.error('Failed to check sync status', error: e);
      return true;
    }
  }
  
  // Offline data management
  static Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    try {
      if (_prefs == null) return;
      
      final offlineData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'offline': true,
      };
      
      await _prefs!.setString('offline_$key', json.encode(offlineData));
      LoggingService.debug('Offline data saved for key: $key');
    } catch (e) {
      LoggingService.error('Failed to save offline data for key: $key', error: e);
    }
  }
  
  static Future<Map<String, dynamic>?> getOfflineData(String key) async {
    try {
      if (_prefs == null) return null;
      
      final offlineString = _prefs!.getString('offline_$key');
      if (offlineString == null) return null;
      
      final offlineData = json.decode(offlineString) as Map<String, dynamic>;
      return offlineData['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggingService.error('Failed to get offline data for key: $key', error: e);
      return null;
    }
  }
  
  static Future<void> clearOfflineData() async {
    try {
      if (_prefs == null) return;
      
      final keys = _prefs!.getKeys().where((key) => key.startsWith('offline_')).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      
      LoggingService.info('Offline data cleared');
    } catch (e) {
      LoggingService.error('Failed to clear offline data', error: e);
    }
  }
  
  // Queue management for offline actions
  static Future<void> queueOfflineAction(String action, Map<String, dynamic> data) async {
    try {
      if (_prefs == null) return;
      
      final queueString = _prefs!.getString('offline_queue') ?? '[]';
      final queue = json.decode(queueString) as List<dynamic>;
      
      queue.add({
        'action': action,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      await _prefs!.setString('offline_queue', json.encode(queue));
      LoggingService.debug('Offline action queued: $action');
    } catch (e) {
      LoggingService.error('Failed to queue offline action: $action', error: e);
    }
  }
  
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      if (_prefs == null) return [];
      
      final queueString = _prefs!.getString('offline_queue') ?? '[]';
      final queue = json.decode(queueString) as List<dynamic>;
      
      return queue.cast<Map<String, dynamic>>();
    } catch (e) {
      LoggingService.error('Failed to get offline queue', error: e);
      return [];
    }
  }
  
  static Future<void> clearOfflineQueue() async {
    try {
      if (_prefs == null) return;
      
      await _prefs!.remove('offline_queue');
      LoggingService.info('Offline queue cleared');
    } catch (e) {
      LoggingService.error('Failed to clear offline queue', error: e);
    }
  }
  
  // Process offline queue when online
  static Future<void> processOfflineQueue() async {
    try {
      if (!_isOnline) return;
      
      final queue = await getOfflineQueue();
      if (queue.isEmpty) return;
      
      LoggingService.info('Processing offline queue: ${queue.length} actions');
      
      for (final action in queue) {
        try {
          // Process the action here
          // This would typically involve making API calls
          LoggingService.debug('Processing offline action: ${action['action']}');
          
          // For now, just log the action
          // In a real implementation, you would make the actual API calls
        } catch (e) {
          LoggingService.error('Failed to process offline action: ${action['action']}', error: e);
        }
      }
      
      // Clear the queue after processing
      await clearOfflineQueue();
      LoggingService.info('Offline queue processed successfully');
    } catch (e) {
      LoggingService.error('Failed to process offline queue', error: e);
    }
  }
}
