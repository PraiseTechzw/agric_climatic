import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  Weather? _currentWeather;
  List<Weather> _hourlyForecast = [];
  List<Weather> _dailyForecast = [];
  List<WeatherAlert> _weatherAlerts = [];
  String _currentLocation = 'Harare';
  bool _isLoading = false;
  String? _error;

  Weather? get currentWeather => _currentWeather;
  List<Weather> get hourlyForecast => _hourlyForecast;
  List<Weather> get dailyForecast => _dailyForecast;
  List<WeatherAlert> get weatherAlerts => _weatherAlerts;
  String get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentWeather() async {
    _setLoading(true);
    try {
      _currentWeather =
          await _weatherService.getCurrentWeather(city: _currentLocation);
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
      final forecast =
          await _weatherService.getForecast(city: _currentLocation);
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

  Future<void> refreshAll() async {
    await Future.wait([
      loadCurrentWeather(),
      loadForecast(),
      loadWeatherAlerts(),
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
