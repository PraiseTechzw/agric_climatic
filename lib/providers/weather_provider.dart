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
import '../services/logging_service.dart';
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

        // Trigger automatic notifications based on weather conditions
        await _triggerWeatherNotifications(_currentWeather!);
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
      LoggingService.error('Failed to load cached data', error: e);
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

  // Trigger automatic notifications based on weather conditions
  Future<void> _triggerWeatherNotifications(Weather weather) async {
    try {
      // Temperature-based notifications
      await _checkTemperatureAlerts(weather);

      // Humidity-based notifications
      await _checkHumidityAlerts(weather);

      // Rainfall-based notifications
      await _checkRainfallAlerts(weather);

      // Wind-based notifications
      await _checkWindAlerts(weather);

      // UV Index notifications
      await _checkUVIndexAlerts(weather);

      // Daily farming tips
      await _sendDailyFarmingTips();

      LoggingService.info('Weather notifications triggered successfully');
    } catch (e) {
      LoggingService.error('Failed to trigger weather notifications', error: e);
    }
  }

  // Check temperature alerts
  Future<void> _checkTemperatureAlerts(Weather weather) async {
    final temp = weather.temperature;

    if (temp > 35) {
      await NotificationService.sendWeatherAlert(
        title: 'Extreme Heat Warning',
        message:
            'Temperature is ${temp.toStringAsFixed(1)}°C. Avoid outdoor work during peak hours (10 AM - 4 PM). Increase irrigation frequency and provide shade for livestock.',
        severity: 'high',
        location: _currentLocation,
        sendSmsIfCritical: true,
      );
    } else if (temp > 30) {
      await NotificationService.sendAgroRecommendation(
        title: 'Hot Weather Advisory',
        message:
            'Temperature is ${temp.toStringAsFixed(1)}°C. Consider early morning or evening farming activities. Increase watering for crops.',
        cropType: 'General',
        location: _currentLocation,
      );
    } else if (temp < 5) {
      await NotificationService.sendWeatherAlert(
        title: 'Frost Risk Alert',
        message:
            'Temperature is ${temp.toStringAsFixed(1)}°C. Protect sensitive crops from frost damage. Cover plants or move them indoors.',
        severity: 'high',
        location: _currentLocation,
        sendSmsIfCritical: true,
      );
    } else if (temp < 10) {
      await NotificationService.sendAgroRecommendation(
        title: 'Cold Weather Advisory',
        message:
            'Temperature is ${temp.toStringAsFixed(1)}°C. Consider delaying planting of sensitive crops. Monitor for frost damage.',
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Check humidity alerts
  Future<void> _checkHumidityAlerts(Weather weather) async {
    final humidity = weather.humidity;

    if (humidity > 85) {
      await NotificationService.sendAgroRecommendation(
        title: 'High Humidity Alert',
        message:
            'Humidity is ${humidity.toStringAsFixed(0)}%. High risk of fungal diseases. Avoid watering and ensure good air circulation.',
        cropType: 'General',
        location: _currentLocation,
      );
    } else if (humidity < 30) {
      await NotificationService.sendAgroRecommendation(
        title: 'Low Humidity Alert',
        message:
            'Humidity is ${humidity.toStringAsFixed(0)}%. Very dry conditions. Increase irrigation frequency and consider mulching.',
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Check rainfall alerts
  Future<void> _checkRainfallAlerts(Weather weather) async {
    final precipitation = weather.precipitation;

    if (precipitation > 20) {
      await NotificationService.sendWeatherAlert(
        title: 'Heavy Rainfall Warning',
        message:
            'Heavy rainfall expected (${precipitation.toStringAsFixed(1)}mm). Avoid field work. Check drainage systems and protect crops from waterlogging.',
        severity: 'high',
        location: _currentLocation,
        sendSmsIfCritical: true,
      );
    } else if (precipitation > 10) {
      await NotificationService.sendAgroRecommendation(
        title: 'Rainfall Advisory',
        message:
            'Rainfall expected (${precipitation.toStringAsFixed(1)}mm). Good time for planting. Reduce irrigation accordingly.',
        cropType: 'General',
        location: _currentLocation,
      );
    } else if (precipitation == 0 && _isDrySeason()) {
      await NotificationService.sendAgroRecommendation(
        title: 'Dry Season Reminder',
        message:
            'No rainfall expected. Ensure adequate irrigation for crops. Consider drought-resistant varieties.',
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Check wind alerts
  Future<void> _checkWindAlerts(Weather weather) async {
    final windSpeed = weather.windSpeed;

    if (windSpeed > 25) {
      await NotificationService.sendWeatherAlert(
        title: 'Strong Wind Warning',
        message:
            'Wind speed is ${windSpeed.toStringAsFixed(1)} m/s. Avoid spraying operations. Secure farm structures and protect young plants.',
        severity: 'high',
        location: _currentLocation,
        sendSmsIfCritical: true,
      );
    } else if (windSpeed > 15) {
      await NotificationService.sendAgroRecommendation(
        title: 'Wind Advisory',
        message:
            'Windy conditions (${windSpeed.toStringAsFixed(1)} m/s). Delay spraying operations. Good for natural pollination.',
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Check UV Index alerts
  Future<void> _checkUVIndexAlerts(Weather weather) async {
    final uvIndex = weather.uvIndex ?? 0;

    if (uvIndex > 8) {
      await NotificationService.sendWeatherAlert(
        title: 'Extreme UV Warning',
        message:
            'UV Index is $uvIndex (Very High). Avoid outdoor work 10 AM - 4 PM. Use sun protection for workers and livestock.',
        severity: 'high',
        location: _currentLocation,
        sendSmsIfCritical: true,
      );
    } else if (uvIndex > 6) {
      await NotificationService.sendAgroRecommendation(
        title: 'High UV Advisory',
        message:
            'UV Index is $uvIndex (High). Take sun protection measures during midday. Good for crop photosynthesis.',
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Send daily farming tips
  Future<void> _sendDailyFarmingTips() async {
    final now = DateTime.now();
    final hour = now.hour;

    // Send tips at 6 AM
    if (hour == 6) {
      final tips = _getDailyFarmingTips();
      await NotificationService.sendAgroRecommendation(
        title: 'Daily Farming Tip',
        message: tips,
        cropType: 'General',
        location: _currentLocation,
      );
    }
  }

  // Get daily farming tips
  String _getDailyFarmingTips() {
    final tips = [
      'Early morning (6-8 AM) is the best time for watering plants to minimize evaporation.',
      'Check soil moisture by inserting your finger 2 inches deep. Water if dry.',
      'Inspect plants for pests and diseases early in the morning when they are most active.',
      'Harvest vegetables in the early morning when they are crisp and full of moisture.',
      'Apply fertilizers in the evening to avoid burning plants in hot weather.',
      'Mulch around plants to retain soil moisture and suppress weeds.',
      'Rotate crops annually to prevent soil depletion and pest buildup.',
      'Keep a farming journal to track planting dates, weather, and yields.',
    ];

    final random = DateTime.now().day % tips.length;
    return tips[random];
  }

  // Check if it's dry season
  bool _isDrySeason() {
    final month = DateTime.now().month;
    // Zimbabwe dry season: April to October
    return month >= 4 && month <= 10;
  }
}
