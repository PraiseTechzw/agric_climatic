import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import '../models/agro_climatic_prediction.dart';
import '../services/weather_service.dart';
import '../services/agro_prediction_service.dart';
import '../services/notification_service.dart';
import '../services/zimbabwe_api_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../widgets/location_permission_handler.dart';
import '../services/offline_storage_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final AgroPredictionService _predictionService = AgroPredictionService();
  final LocationService _locationService = LocationService();

  Weather? _currentWeather;
  List<Weather> _hourlyForecast = [];
  List<Weather> _dailyForecast = [];
  List<WeatherAlert> _weatherAlerts = [];
  AgroClimaticPrediction? _currentPrediction;
  List<HistoricalWeatherPattern> _historicalPatterns = [];
  String _currentLocation = 'Harare';
  bool _isLoading = false;
  String? _error;

  Weather? get currentWeather => _currentWeather;
  List<Weather> get hourlyForecast => _hourlyForecast;
  List<Weather> get dailyForecast => _dailyForecast;
  List<WeatherAlert> get weatherAlerts => _weatherAlerts;
  AgroClimaticPrediction? get currentPrediction => _currentPrediction;
  List<HistoricalWeatherPattern> get historicalPatterns => _historicalPatterns;
  String get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentWeather() async {
    _setLoading(true);
    try {
      // Try Zimbabwe API first
      _currentWeather = await ZimbabweApiService.getCurrentWeather(
        _currentLocation,
      );

      // Save to Firebase and offline storage
      if (_currentWeather != null) {
        await FirebaseService.saveZimbabweWeatherData(_currentWeather!);
        await OfflineStorageService.saveWeatherData(_currentWeather!);
      }

      _error = null;
    } catch (e) {
      // Fallback to original service
      try {
        _currentWeather = await _weatherService.getCurrentWeather(
          city: _currentLocation,
        );
        _error = null;
      } catch (fallbackError) {
        _error = 'Failed to load weather: $e';
      }
    } finally {
      _setLoading(false);
    }
  }

  // Detect location automatically
  Future<void> detectLocation() async {
    _setLoading(true);
    try {
      // Check and request location permission first
      final hasPermission =
          await LocationPermissionHandler.requestLocationPermission();

      if (!hasPermission) {
        _error = 'Location permission denied. Using default location.';
        _setLoading(false);
        return;
      }

      // Get current location
      await _locationService.getCurrentLocation();

      // Update current location if detected
      if (_locationService.currentCity != null) {
        _currentLocation = _locationService.currentCity!;
        notifyListeners();

        // Load weather for detected location
        await loadCurrentWeather();
      } else {
        _error = 'Could not detect your location. Using default location.';
      }
    } catch (e) {
      _error = 'Location detection failed: $e. Using default location.';
    } finally {
      _setLoading(false);
    }
  }

  // Get location service instance
  LocationService get locationService => _locationService;

  // Load cached data when offline
  Future<void> loadCachedData() async {
    try {
      final cachedWeather = await OfflineStorageService.getCachedWeatherData();
      if (cachedWeather.isNotEmpty) {
        _currentWeather = cachedWeather.last; // Get most recent
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load cached data: $e');
    }
  }

  Future<void> loadForecast() async {
    _setLoading(true);
    try {
      final forecast = await _weatherService.getForecast(
        city: _currentLocation,
      );
      _hourlyForecast = forecast.hourly;
      _dailyForecast = forecast.daily;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadWeatherAlerts() async {
    try {
      final previousIds = _weatherAlerts.map((a) => a.id).toSet();
      final fetched = await _weatherService.getWeatherAlerts();
      _weatherAlerts = fetched;
      _error = null;

      // Notify on newly arrived high/critical alerts
      for (final alert in fetched) {
        if (!previousIds.contains(alert.id)) {
          final sev = (alert.severity).toLowerCase();
          if (sev == 'high' || sev == 'critical' || sev == 'severe') {
            await NotificationService.sendWeatherAlert(
              title: alert.title,
              message: alert.description,
              severity: alert.severity,
              location: alert.location,
            );
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadAgroPrediction() async {
    _setLoading(true);
    try {
      _currentPrediction = await _predictionService.generateLongTermPrediction(
        location: _currentLocation,
        startDate: DateTime.now(),
        daysAhead: 30,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadHistoricalPatterns() async {
    _setLoading(true);
    try {
      _historicalPatterns = await _predictionService.analyzeSequentialPatterns(
        location: _currentLocation,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeNotifications() async {
    await NotificationService.initialize();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadCurrentWeather(),
      loadForecast(),
      loadWeatherAlerts(),
      loadAgroPrediction(),
      loadHistoricalPatterns(),
    ]);
  }

  void changeLocation(String location) {
    _currentLocation = location;
    notifyListeners();
    refreshAll();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
