import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/agro_climatic_prediction.dart';
import '../models/agricultural_recommendation.dart';
import '../services/historical_weather_service.dart';
import '../services/logging_service.dart';

class DashboardProvider extends ChangeNotifier {
  final HistoricalWeatherService _historicalService =
      HistoricalWeatherService();

  // State variables
  List<Weather> _historicalWeatherData = [];
  List<WeatherPattern> _weatherPatterns = [];
  List<AgroClimaticPrediction> _predictions = [];
  List<AgriculturalRecommendation> _recommendations = [];
  Map<String, dynamic> _climateStatistics = {};

  bool _isLoading = false;
  String _selectedTimeRange = 'Week';
  String _selectedYear = DateTime.now().year.toString();
  String _selectedLocation = 'Current Location';

  // Getters
  List<Weather> get historicalWeatherData => _historicalWeatherData;
  List<WeatherPattern> get weatherPatterns => _weatherPatterns;
  List<AgroClimaticPrediction> get predictions => _predictions;
  List<AgriculturalRecommendation> get recommendations => _recommendations;
  Map<String, dynamic> get climateStatistics => _climateStatistics;

  bool get isLoading => _isLoading;
  String get selectedTimeRange => _selectedTimeRange;
  String get selectedYear => _selectedYear;
  String get selectedLocation => _selectedLocation;

  // Time range options
  final List<String> timeRanges = ['Week', 'Month', 'Season', 'Year'];
  final List<String> years = ['2024', '2023', '2022', '2021', '2020'];

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadHistoricalData(),
        _loadWeatherPatterns(),
        _loadPredictions(),
        _loadRecommendations(),
        _loadClimateStatistics(),
      ]);

      LoggingService.info('Dashboard data loaded successfully');
    } catch (e) {
      LoggingService.error('Failed to load dashboard data', error: e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load historical weather data
  Future<void> _loadHistoricalData() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _historicalWeatherData = await _historicalService
          .getHistoricalWeatherData(
            startDate: startDate,
            endDate: endDate,
            location: _selectedLocation,
          );

      notifyListeners();
    } catch (e) {
      LoggingService.error('Failed to load historical data', error: e);
      _historicalWeatherData = [];
    }
  }

  /// Load weather patterns
  Future<void> _loadWeatherPatterns() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _weatherPatterns = await _historicalService.analyzeWeatherPatterns(
        startDate: startDate,
        endDate: endDate,
        location: _selectedLocation,
      );

      notifyListeners();
    } catch (e) {
      LoggingService.error('Failed to load weather patterns', error: e);
      _weatherPatterns = [];
    }
  }

  /// Load predictions
  Future<void> _loadPredictions() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _predictions = await _historicalService.generatePredictions(
        startDate: startDate,
        endDate: endDate,
        location: _selectedLocation,
      );

      notifyListeners();
    } catch (e) {
      LoggingService.error('Failed to load predictions', error: e);
      _predictions = [];
    }
  }

  /// Load recommendations
  Future<void> _loadRecommendations() async {
    try {
      // Generate recommendations based on current patterns and predictions
      _recommendations = _generateRecommendationsFromData();

      notifyListeners();
    } catch (e) {
      LoggingService.error('Failed to load recommendations', error: e);
      _recommendations = [];
    }
  }

  /// Load climate statistics
  Future<void> _loadClimateStatistics() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _climateStatistics = await _historicalService.getClimateStatistics(
        startDate: startDate,
        endDate: endDate,
        location: _selectedLocation,
      );

      notifyListeners();
    } catch (e) {
      LoggingService.error('Failed to load climate statistics', error: e);
      _climateStatistics = {};
    }
  }

  /// Update time range selection
  void updateTimeRange(String timeRange) {
    if (_selectedTimeRange != timeRange) {
      _selectedTimeRange = timeRange;
      notifyListeners();
      _loadHistoricalData();
    }
  }

  /// Update year selection
  void updateYear(String year) {
    if (_selectedYear != year) {
      _selectedYear = year;
      notifyListeners();
      _loadHistoricalData();
    }
  }

  /// Update location selection
  void updateLocation(String location) {
    if (_selectedLocation != location) {
      _selectedLocation = location;
      notifyListeners();
      loadDashboardData();
    }
  }

  /// Upload weather data from CSV
  Future<void> uploadWeatherDataFromCSV(String csvData) async {
    _setLoading(true);
    try {
      await _historicalService.uploadWeatherDataFromCSV(csvData);
      await loadDashboardData(); // Refresh all data

      LoggingService.info('Weather data uploaded successfully from CSV');
    } catch (e) {
      LoggingService.error('Failed to upload weather data from CSV', error: e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Store new weather data
  Future<void> storeWeatherData(Weather weather) async {
    try {
      await _historicalService.storeWeatherData(weather);
      await _loadHistoricalData(); // Refresh historical data

      LoggingService.info('Weather data stored successfully');
    } catch (e) {
      LoggingService.error('Failed to store weather data', error: e);
      rethrow;
    }
  }

  /// Update existing weather data
  Future<void> updateWeatherData(Weather weather) async {
    try {
      await _historicalService.updateWeatherData(weather);
      await _loadHistoricalData(); // Refresh historical data

      LoggingService.info('Weather data updated successfully');
    } catch (e) {
      LoggingService.error('Failed to update weather data', error: e);
      rethrow;
    }
  }

  /// Delete weather data
  Future<void> deleteWeatherData(String weatherId) async {
    try {
      await _historicalService.deleteWeatherData(weatherId);
      await _loadHistoricalData(); // Refresh historical data

      LoggingService.info('Weather data deleted successfully');
    } catch (e) {
      LoggingService.error('Failed to delete weather data', error: e);
      rethrow;
    }
  }

  /// Get weather data for specific time periods
  Future<List<Weather>> getWeatherDataForYears(int years) async {
    try {
      return await _historicalService.getWeatherDataForYears(years);
    } catch (e) {
      LoggingService.error('Failed to get weather data for years', error: e);
      return [];
    }
  }

  Future<List<Weather>> getWeatherDataForYear(int year) async {
    try {
      return await _historicalService.getWeatherDataForYear(year);
    } catch (e) {
      LoggingService.error('Failed to get weather data for year', error: e);
      return [];
    }
  }

  Future<List<Weather>> getWeatherDataForMonth(int year, int month) async {
    try {
      return await _historicalService.getWeatherDataForMonth(year, month);
    } catch (e) {
      LoggingService.error('Failed to get weather data for month', error: e);
      return [];
    }
  }

  Future<List<Weather>> getWeatherDataForSeason(int year, String season) async {
    try {
      return await _historicalService.getWeatherDataForSeason(year, season);
    } catch (e) {
      LoggingService.error('Failed to get weather data for season', error: e);
      return [];
    }
  }

  /// Get chart data for visualization
  List<FlSpot> getTemperatureChartData() {
    if (_historicalWeatherData.isEmpty) return [];

    return _historicalWeatherData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.temperature);
    }).toList();
  }

  List<FlSpot> getHumidityChartData() {
    if (_historicalWeatherData.isEmpty) return [];

    return _historicalWeatherData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.humidity);
    }).toList();
  }

  List<FlSpot> getPrecipitationChartData() {
    if (_historicalWeatherData.isEmpty) return [];

    return _historicalWeatherData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.precipitation);
    }).toList();
  }

  /// Get historical comparison data
  Map<String, List<FlSpot>> getHistoricalComparisonData() {
    final Map<String, List<FlSpot>> comparisonData = {};

    // Get data for last 5 years
    for (
      int year = DateTime.now().year - 4;
      year <= DateTime.now().year;
      year++
    ) {
      final yearData = _historicalWeatherData
          .where((w) => w.dateTime.year == year)
          .toList();

      if (yearData.isNotEmpty) {
        final avgTemp =
            yearData.map((w) => w.temperature).reduce((a, b) => a + b) /
            yearData.length;

        comparisonData[year.toString()] = [FlSpot(year.toDouble(), avgTemp)];
      }
    }

    return comparisonData;
  }

  /// Generate recommendations from current data
  List<AgriculturalRecommendation> _generateRecommendationsFromData() {
    final recommendations = <AgriculturalRecommendation>[];

    // Generate recommendations based on weather patterns
    for (final pattern in _weatherPatterns) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'rec_${pattern.id}',
          title: 'Action Required: ${pattern.patternType}',
          description: pattern.description,
          category: _getCategoryFromPattern(pattern.patternType),
          priority: _getPriorityFromSeverity(pattern.severity),
          date: DateTime.now(),
          location: pattern.location,
          cropType: 'General',
          actions: pattern.recommendations,
          conditions: pattern.statistics,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Generate recommendations based on predictions
    for (final prediction in _predictions) {
      if (prediction.pestRisk.toLowerCase() == 'high' ||
          prediction.diseaseRisk.toLowerCase() == 'high') {
        recommendations.add(
          AgriculturalRecommendation(
            id: 'rec_pred_${prediction.id}',
            title: 'Pest/Disease Alert',
            description:
                'High risk of ${prediction.pestRisk} pest and ${prediction.diseaseRisk} disease',
            category: 'Pest Control',
            priority: 'High',
            date: prediction.date,
            location: prediction.location,
            cropType: 'General',
            actions: [
              'Apply preventive treatments',
              'Monitor crop health closely',
              'Implement integrated pest management',
            ],
            conditions: {
              'pest_risk': prediction.pestRisk,
              'disease_risk': prediction.diseaseRisk,
              'temperature': prediction.temperature,
              'humidity': prediction.humidity,
            },
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return recommendations;
  }

  String _getCategoryFromPattern(String patternType) {
    switch (patternType.toLowerCase()) {
      case 'temperature trend':
        return 'Temperature Management';
      case 'precipitation pattern':
        return 'Irrigation';
      case 'humidity pattern':
        return 'Humidity Control';
      default:
        return 'General';
    }
  }

  String _getPriorityFromSeverity(double severity) {
    if (severity > 0.7) return 'High';
    if (severity > 0.4) return 'Medium';
    return 'Low';
  }

  DateTime _getStartDateForRange(String range, String year) {
    final yearInt = int.parse(year);
    switch (range) {
      case 'Week':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Month':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Season':
        return DateTime.now().subtract(const Duration(days: 90));
      case 'Year':
        return DateTime(yearInt, 1, 1);
      default:
        return DateTime.now().subtract(const Duration(days: 7));
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _historicalWeatherData.clear();
    _weatherPatterns.clear();
    _predictions.clear();
    _recommendations.clear();
    _climateStatistics.clear();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadDashboardData();
  }
}
