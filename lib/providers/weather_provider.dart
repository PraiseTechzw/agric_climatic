import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import '../models/agro_climatic_prediction.dart';
import '../services/weather_service.dart';
import '../services/agro_prediction_service.dart';
import '../services/notification_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final AgroPredictionService _predictionService = AgroPredictionService();
  final NotificationService _notificationService = NotificationService();

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
      _currentWeather = await _weatherService.getCurrentWeather(
        city: _currentLocation,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
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
      _weatherAlerts = await _weatherService.getWeatherAlerts();
      _error = null;
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
    await _notificationService.initialize();
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
