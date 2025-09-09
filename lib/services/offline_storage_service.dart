import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';
import '../models/soil_data.dart';
import '../models/agro_climatic_prediction.dart';

class OfflineStorageService {
  static const String _weatherKey = 'cached_weather_data';
  static const String _soilKey = 'cached_soil_data';
  static const String _predictionsKey = 'cached_predictions';
  static const String _lastUpdateKey = 'last_data_update';

  // Save weather data offline
  static Future<void> saveWeatherData(Weather weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_weatherKey) ?? [];

      // Add new weather data
      existingData.add(jsonEncode(weather.toJson()));

      // Keep only last 100 entries
      if (existingData.length > 100) {
        existingData.removeRange(0, existingData.length - 100);
      }

      await prefs.setStringList(_weatherKey, existingData);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to save weather data offline: $e');
    }
  }

  // Get cached weather data
  static Future<List<Weather>> getCachedWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_weatherKey) ?? [];

      return data.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return Weather.fromJson(json);
      }).toList();
    } catch (e) {
      print('Failed to get cached weather data: $e');
      return [];
    }
  }

  // Save soil data offline
  static Future<void> saveSoilData(SoilData soilData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_soilKey, jsonEncode(soilData.toJson()));
    } catch (e) {
      print('Failed to save soil data offline: $e');
    }
  }

  // Get cached soil data
  static Future<SoilData?> getCachedSoilData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_soilKey);

      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return SoilData.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Failed to get cached soil data: $e');
      return null;
    }
  }

  // Save predictions offline
  static Future<void> savePredictions(
    List<AgroClimaticPrediction> predictions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = predictions.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_predictionsKey, data);
    } catch (e) {
      print('Failed to save predictions offline: $e');
    }
  }

  // Get cached predictions
  static Future<List<AgroClimaticPrediction>> getCachedPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_predictionsKey) ?? [];

      return data.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return AgroClimaticPrediction.fromJson(json);
      }).toList();
    } catch (e) {
      print('Failed to get cached predictions: $e');
      return [];
    }
  }

  // Check if data is fresh (less than 1 hour old)
  static Future<bool> isDataFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);

      if (lastUpdate == null) return false;

      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);

      return difference.inHours < 1;
    } catch (e) {
      return false;
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weatherKey);
      await prefs.remove(_soilKey);
      await prefs.remove(_predictionsKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  // Get cache size info
  static Future<Map<String, int>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherData = prefs.getStringList(_weatherKey) ?? [];
      final soilData = prefs.getString(_soilKey);
      final predictionsData = prefs.getStringList(_predictionsKey) ?? [];

      return {
        'weather_entries': weatherData.length,
        'has_soil_data': soilData != null ? 1 : 0,
        'prediction_entries': predictionsData.length,
      };
    } catch (e) {
      return {'error': 1};
    }
  }
}
