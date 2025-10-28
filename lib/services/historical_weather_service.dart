import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/agro_climatic_prediction.dart';
import '../services/logging_service.dart';

class HistoricalWeatherService {
  static final HistoricalWeatherService _instance =
      HistoricalWeatherService._internal();
  factory HistoricalWeatherService() => _instance;
  HistoricalWeatherService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'historical_weather';
  static const String _patternsCollection = 'weather_patterns';
  static const String _predictionsCollection = 'agro_predictions';

  // Cache for offline access
  static const String _cacheKey = 'historical_weather_cache';

  /// Store weather data for historical analysis
  Future<void> storeWeatherData(Weather weather) async {
    try {
      // Store in Firestore
      await _firestore
          .collection(_collectionName)
          .doc(weather.id)
          .set(weather.toJson());

      // Update local cache
      await _updateLocalCache(weather);

      LoggingService.info('Weather data stored successfully: ${weather.id}');
    } catch (e) {
      LoggingService.error('Failed to store weather data', error: e);
      throw Exception('Failed to store weather data: $e');
    }
  }

  /// Store multiple weather records
  Future<void> storeMultipleWeatherData(List<Weather> weatherList) async {
    try {
      final batch = _firestore.batch();

      for (final weather in weatherList) {
        final docRef = _firestore.collection(_collectionName).doc(weather.id);
        batch.set(docRef, weather.toJson());
      }

      await batch.commit();

      // Update local cache
      await _updateLocalCacheMultiple(weatherList);

      LoggingService.info(
        'Multiple weather data stored successfully: ${weatherList.length} records',
      );
    } catch (e) {
      LoggingService.error('Failed to store multiple weather data', error: e);
      throw Exception('Failed to store multiple weather data: $e');
    }
  }

  /// Get historical weather data for a specific time range with Zimbabwe-specific enhancements
  Future<List<Weather>> getHistoricalWeatherData({
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where(
            'date_time',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('date_time', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date_time');

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot = await query.get();
      final weatherData = snapshot.docs
          .map((doc) => Weather.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // If no real data, generate Zimbabwe-specific sample data
      if (weatherData.isEmpty) {
        LoggingService.info(
          'No real data found, generating Zimbabwe sample data',
        );
        return _generateZimbabweWeatherData(
          startDate,
          endDate,
          location ?? 'Harare, Zimbabwe',
        );
      }

      LoggingService.info(
        'Retrieved ${weatherData.length} historical weather records',
      );
      return weatherData;
    } catch (e) {
      LoggingService.error('Failed to get historical weather data', error: e);
      // Fallback to Zimbabwe sample data
      return _generateZimbabweWeatherData(
        startDate,
        endDate,
        location ?? 'Harare, Zimbabwe',
      );
    }
  }

  /// Get weather data for the last N years
  Future<List<Weather>> getWeatherDataForYears(int years) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year - years, 1, 1);

    return await getHistoricalWeatherData(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get weather data for a specific year
  Future<List<Weather>> getWeatherDataForYear(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return await getHistoricalWeatherData(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get weather data for a specific month
  Future<List<Weather>> getWeatherDataForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return await getHistoricalWeatherData(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get weather data for a specific season
  Future<List<Weather>> getWeatherDataForSeason(int year, String season) async {
    DateTime startDate, endDate;

    switch (season.toLowerCase()) {
      case 'spring':
        startDate = DateTime(year, 3, 1);
        endDate = DateTime(year, 5, 31, 23, 59, 59);
        break;
      case 'summer':
        startDate = DateTime(year, 6, 1);
        endDate = DateTime(year, 8, 31, 23, 59, 59);
        break;
      case 'autumn':
      case 'fall':
        startDate = DateTime(year, 9, 1);
        endDate = DateTime(year, 11, 30, 23, 59, 59);
        break;
      case 'winter':
        startDate = DateTime(year, 12, 1);
        endDate = DateTime(year + 1, 2, 28, 23, 59, 59);
        break;
      default:
        throw ArgumentError('Invalid season: $season');
    }

    return await getHistoricalWeatherData(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Analyze weather patterns from historical data
  Future<List<WeatherPattern>> analyzeWeatherPatterns({
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      final weatherData = await getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
        location: location,
      );

      if (weatherData.isEmpty) {
        return [];
      }

      final patterns = <WeatherPattern>[];

      // Analyze temperature trends
      final tempPattern = _analyzeTemperaturePattern(weatherData);
      if (tempPattern != null) {
        patterns.add(tempPattern);
      }

      // Analyze precipitation patterns
      final precipPattern = _analyzePrecipitationPattern(weatherData);
      if (precipPattern != null) {
        patterns.add(precipPattern);
      }

      // Analyze humidity patterns
      final humidityPattern = _analyzeHumidityPattern(weatherData);
      if (humidityPattern != null) {
        patterns.add(humidityPattern);
      }

      // Store patterns
      await _storeWeatherPatterns(patterns);

      return patterns;
    } catch (e) {
      LoggingService.error('Failed to analyze weather patterns', error: e);
      return [];
    }
  }

  /// Generate agricultural predictions based on historical data
  Future<List<AgroClimaticPrediction>> generatePredictions({
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      final weatherData = await getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
        location: location,
      );

      if (weatherData.isEmpty) {
        return [];
      }

      final predictions = <AgroClimaticPrediction>[];

      // Generate predictions for each month in the range
      final currentDate = DateTime.now();
      for (int i = 0; i < 12; i++) {
        final predictionDate = DateTime(
          currentDate.year,
          currentDate.month + i,
          1,
        );
        final prediction = _generatePredictionForDate(
          weatherData,
          predictionDate,
        );
        predictions.add(prediction);
      }

      // Store predictions
      await _storePredictions(predictions);

      return predictions;
    } catch (e) {
      LoggingService.error('Failed to generate predictions', error: e);
      return [];
    }
  }

  /// Get climate statistics for a time period
  Future<Map<String, dynamic>> getClimateStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      final weatherData = await getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
        location: location,
      );

      if (weatherData.isEmpty) {
        return {};
      }

      final temperatures = weatherData.map((w) => w.temperature).toList();
      final humidities = weatherData.map((w) => w.humidity).toList();
      final precipitations = weatherData.map((w) => w.precipitation).toList();

      return {
        'temperature': {
          'average': temperatures.reduce((a, b) => a + b) / temperatures.length,
          'min': temperatures.reduce((a, b) => a < b ? a : b),
          'max': temperatures.reduce((a, b) => a > b ? a : b),
          'trend': _calculateTrend(temperatures),
        },
        'humidity': {
          'average': humidities.reduce((a, b) => a + b) / humidities.length,
          'min': humidities.reduce((a, b) => a < b ? a : b),
          'max': humidities.reduce((a, b) => a > b ? a : b),
          'trend': _calculateTrend(humidities),
        },
        'precipitation': {
          'total': precipitations.reduce((a, b) => a + b),
          'average':
              precipitations.reduce((a, b) => a + b) / precipitations.length,
          'max': precipitations.reduce((a, b) => a > b ? a : b),
          'trend': _calculateTrend(precipitations),
        },
        'record_count': weatherData.length,
        'date_range': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      LoggingService.error('Failed to get climate statistics', error: e);
      return {};
    }
  }

  /// Delete weather data
  Future<void> deleteWeatherData(String weatherId) async {
    try {
      await _firestore.collection(_collectionName).doc(weatherId).delete();
      await _removeFromLocalCache(weatherId);

      LoggingService.info('Weather data deleted successfully: $weatherId');
    } catch (e) {
      LoggingService.error('Failed to delete weather data', error: e);
      throw Exception('Failed to delete weather data: $e');
    }
  }

  /// Update weather data
  Future<void> updateWeatherData(Weather weather) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(weather.id)
          .update(weather.toJson());

      await _updateLocalCache(weather);

      LoggingService.info('Weather data updated successfully: ${weather.id}');
    } catch (e) {
      LoggingService.error('Failed to update weather data', error: e);
      throw Exception('Failed to update weather data: $e');
    }
  }

  /// Upload weather data from CSV
  Future<void> uploadWeatherDataFromCSV(String csvData) async {
    try {
      final lines = csvData.split('\n');
      final weatherList = <Weather>[];

      for (int i = 1; i < lines.length; i++) {
        // Skip header
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = line.split(',');
        if (values.length >= 8) {
          final weather = Weather(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
            dateTime: DateTime.parse(values[0]),
            temperature: double.parse(values[1]),
            humidity: double.parse(values[2]),
            windSpeed: double.parse(values[3]),
            condition: values[4],
            description: values[5],
            icon: values[6],
            pressure: double.parse(values[7]),
            precipitation: values.length > 8 ? double.parse(values[8]) : 0.0,
          );
          weatherList.add(weather);
        }
      }

      await storeMultipleWeatherData(weatherList);

      LoggingService.info(
        'CSV weather data uploaded successfully: ${weatherList.length} records',
      );
    } catch (e) {
      LoggingService.error('Failed to upload CSV weather data', error: e);
      throw Exception('Failed to upload CSV weather data: $e');
    }
  }

  // Private helper methods

  Future<void> _updateLocalCache(Weather weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getStringList(_cacheKey) ?? [];

      // Remove existing entry with same ID
      cachedData.removeWhere((item) {
        final data = jsonDecode(item);
        return data['id'] == weather.id;
      });

      // Add new entry
      cachedData.add(jsonEncode(weather.toJson()));

      // Keep only last 1000 entries
      if (cachedData.length > 1000) {
        cachedData.removeRange(0, cachedData.length - 1000);
      }

      await prefs.setStringList(_cacheKey, cachedData);
    } catch (e) {
      LoggingService.warning('Failed to update local cache', error: e);
    }
  }

  Future<void> _updateLocalCacheMultiple(List<Weather> weatherList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getStringList(_cacheKey) ?? [];

      for (final weather in weatherList) {
        // Remove existing entry with same ID
        cachedData.removeWhere((item) {
          final data = jsonDecode(item);
          return data['id'] == weather.id;
        });

        // Add new entry
        cachedData.add(jsonEncode(weather.toJson()));
      }

      // Keep only last 1000 entries
      if (cachedData.length > 1000) {
        cachedData.removeRange(0, cachedData.length - 1000);
      }

      await prefs.setStringList(_cacheKey, cachedData);
    } catch (e) {
      LoggingService.warning('Failed to update local cache multiple', error: e);
    }
  }

  Future<List<Weather>> _getCachedWeatherData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getStringList(_cacheKey) ?? [];

      final weatherList = <Weather>[];
      for (final item in cachedData) {
        try {
          final data = jsonDecode(item);
          final weather = Weather.fromJson(data);

          if (weather.dateTime.isAfter(startDate) &&
              weather.dateTime.isBefore(endDate)) {
            weatherList.add(weather);
          }
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      return weatherList;
    } catch (e) {
      LoggingService.warning('Failed to get cached weather data', error: e);
      return [];
    }
  }

  Future<void> _removeFromLocalCache(String weatherId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getStringList(_cacheKey) ?? [];

      cachedData.removeWhere((item) {
        final data = jsonDecode(item);
        return data['id'] == weatherId;
      });

      await prefs.setStringList(_cacheKey, cachedData);
    } catch (e) {
      LoggingService.warning('Failed to remove from local cache', error: e);
    }
  }

  Future<void> _storeWeatherPatterns(List<WeatherPattern> patterns) async {
    try {
      final batch = _firestore.batch();

      for (final pattern in patterns) {
        final docRef = _firestore
            .collection(_patternsCollection)
            .doc(pattern.id);
        batch.set(docRef, pattern.toJson());
      }

      await batch.commit();
    } catch (e) {
      LoggingService.warning('Failed to store weather patterns', error: e);
    }
  }

  Future<void> _storePredictions(
    List<AgroClimaticPrediction> predictions,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final prediction in predictions) {
        final docRef = _firestore
            .collection(_predictionsCollection)
            .doc(prediction.id);
        batch.set(docRef, prediction.toJson());
      }

      await batch.commit();
    } catch (e) {
      LoggingService.warning('Failed to store predictions', error: e);
    }
  }

  WeatherPattern? _analyzeTemperaturePattern(List<Weather> weatherData) {
    if (weatherData.length < 7) return null; // Need at least a week of data

    final temperatures = weatherData.map((w) => w.temperature).toList();
    final trend = _calculateTrend(temperatures);

    if (trend.abs() > 0.5) {
      // Significant trend
      return WeatherPattern(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        location: 'Current Location',
        startDate: weatherData.first.dateTime,
        endDate: weatherData.last.dateTime,
        patternType: 'Temperature Trend',
        description: trend > 0
            ? 'Rising temperature pattern detected'
            : 'Falling temperature pattern detected',
        severity: trend.abs() / 10.0, // Normalize to 0-1
        indicators: ['Temperature ${trend > 0 ? 'increase' : 'decrease'}'],
        statistics: {
          'avg_temp':
              temperatures.reduce((a, b) => a + b) / temperatures.length,
          'trend': trend,
          'min_temp': temperatures.reduce((a, b) => a < b ? a : b),
          'max_temp': temperatures.reduce((a, b) => a > b ? a : b),
        },
        impacts: trend > 0
            ? ['Increased irrigation needs', 'Heat stress risk']
            : ['Reduced irrigation needs', 'Cold stress risk'],
        recommendations: trend > 0
            ? ['Increase watering frequency', 'Provide shade']
            : ['Reduce watering frequency', 'Protect from cold'],
      );
    }

    return null;
  }

  WeatherPattern? _analyzePrecipitationPattern(List<Weather> weatherData) {
    if (weatherData.length < 7) return null;

    final precipitations = weatherData.map((w) => w.precipitation).toList();
    final totalPrecipitation = precipitations.reduce((a, b) => a + b);
    final avgPrecipitation = totalPrecipitation / precipitations.length;

    if (avgPrecipitation < 1.0) {
      // Low precipitation
      return WeatherPattern(
        id: 'precip_${DateTime.now().millisecondsSinceEpoch}',
        location: 'Current Location',
        startDate: weatherData.first.dateTime,
        endDate: weatherData.last.dateTime,
        patternType: 'Precipitation Pattern',
        description: 'Low precipitation pattern detected',
        severity: (5.0 - avgPrecipitation) / 5.0, // Normalize to 0-1
        indicators: ['Low rainfall', 'Dry conditions'],
        statistics: {
          'total_precipitation': totalPrecipitation,
          'avg_precipitation': avgPrecipitation,
          'days_without_rain': precipitations.where((p) => p == 0).length,
        },
        impacts: ['Drought risk', 'Increased irrigation needs'],
        recommendations: ['Increase irrigation', 'Monitor soil moisture'],
      );
    }

    return null;
  }

  WeatherPattern? _analyzeHumidityPattern(List<Weather> weatherData) {
    if (weatherData.length < 7) return null;

    final humidities = weatherData.map((w) => w.humidity).toList();
    final avgHumidity = humidities.reduce((a, b) => a + b) / humidities.length;
    final variance = _calculateVariance(humidities);

    if (variance > 100) {
      // High variability
      return WeatherPattern(
        id: 'humidity_${DateTime.now().millisecondsSinceEpoch}',
        location: 'Current Location',
        startDate: weatherData.first.dateTime,
        endDate: weatherData.last.dateTime,
        patternType: 'Humidity Pattern',
        description: 'Variable humidity pattern detected',
        severity: variance / 200.0, // Normalize to 0-1
        indicators: ['High humidity variability', 'Unstable conditions'],
        statistics: {
          'avg_humidity': avgHumidity,
          'variance': variance,
          'min_humidity': humidities.reduce((a, b) => a < b ? a : b),
          'max_humidity': humidities.reduce((a, b) => a > b ? a : b),
        },
        impacts: ['Plant stress', 'Disease risk'],
        recommendations: ['Monitor plant health', 'Adjust irrigation'],
      );
    }

    return null;
  }

  AgroClimaticPrediction _generatePredictionForDate(
    List<Weather> historicalData,
    DateTime date,
  ) {
    // Simple prediction based on historical averages
    final avgTemp =
        historicalData.map((w) => w.temperature).reduce((a, b) => a + b) /
        historicalData.length;
    final avgHumidity =
        historicalData.map((w) => w.humidity).reduce((a, b) => a + b) /
        historicalData.length;
    final avgPrecipitation =
        historicalData.map((w) => w.precipitation).reduce((a, b) => a + b) /
        historicalData.length;

    return AgroClimaticPrediction(
      id: 'pred_${date.millisecondsSinceEpoch}',
      date: date,
      location: 'Current Location',
      temperature: avgTemp,
      humidity: avgHumidity,
      precipitation: avgPrecipitation,
      evapotranspiration: avgTemp * 0.1, // Simple calculation
      cropRecommendation: _getCropRecommendation(avgTemp, avgHumidity),
      irrigationAdvice: _getIrrigationAdvice(avgPrecipitation, avgHumidity),
      pestRisk: _getPestRisk(avgTemp, avgHumidity),
      diseaseRisk: _getDiseaseRisk(avgHumidity),
      yieldPrediction: _getYieldPrediction(avgTemp, avgPrecipitation),
      plantingAdvice: _getPlantingAdvice(date, avgTemp),
      harvestingAdvice: _getHarvestingAdvice(date, avgTemp),
      weatherAlerts: _getWeatherAlerts(avgTemp, avgPrecipitation),
      soilConditions: {
        'moisture': avgPrecipitation > 5
            ? 'wet'
            : avgPrecipitation < 1
            ? 'dry'
            : 'normal',
        'temperature': avgTemp > 30
            ? 'hot'
            : avgTemp < 15
            ? 'cold'
            : 'normal',
      },
      climateIndicators: {
        'heat_index': avgTemp + (avgHumidity * 0.1),
        'drought_index': avgPrecipitation < 2
            ? 'high'
            : avgPrecipitation < 5
            ? 'medium'
            : 'low',
      },
    );
  }

  String _getCropRecommendation(double temp, double humidity) {
    if (temp > 30 && humidity < 40) {
      return 'Drought-resistant crops like millet or sorghum';
    } else if (temp < 20 && humidity > 70) {
      return 'Cool-season crops like lettuce or spinach';
    } else {
      return 'Standard crops like maize or wheat';
    }
  }

  String _getIrrigationAdvice(double precipitation, double humidity) {
    if (precipitation < 2 && humidity < 50) {
      return 'Increase irrigation frequency to twice daily';
    } else if (precipitation > 10) {
      return 'Reduce irrigation to prevent waterlogging';
    } else {
      return 'Maintain normal irrigation schedule';
    }
  }

  String _getPestRisk(double temp, double humidity) {
    if (temp > 25 && humidity > 60) {
      return 'High';
    } else if (temp > 20 && humidity > 50) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  String _getDiseaseRisk(double humidity) {
    if (humidity > 80) {
      return 'High';
    } else if (humidity > 60) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  double _getYieldPrediction(double temp, double precipitation) {
    double yield = 100.0; // Base yield

    // Temperature effects
    if (temp < 15 || temp > 35) {
      yield -= 20;
    } else if (temp < 20 || temp > 30) {
      yield -= 10;
    }

    // Precipitation effects
    if (precipitation < 2) {
      yield -= 30;
    } else if (precipitation < 5) {
      yield -= 15;
    } else if (precipitation > 20) {
      yield -= 10;
    }

    return yield.clamp(0, 100);
  }

  String _getPlantingAdvice(DateTime date, double temp) {
    final month = date.month;
    if (month >= 3 && month <= 5 && temp > 15) {
      return 'Optimal planting time for spring crops';
    } else if (month >= 9 && month <= 11 && temp > 10) {
      return 'Good time for fall planting';
    } else {
      return 'Wait for better conditions';
    }
  }

  String _getHarvestingAdvice(DateTime date, double temp) {
    final month = date.month;
    if (month >= 8 && month <= 10 && temp < 30) {
      return 'Optimal harvesting conditions';
    } else if (temp > 35) {
      return 'Harvest early to avoid heat damage';
    } else {
      return 'Normal harvesting schedule';
    }
  }

  List<String> _getWeatherAlerts(double temp, double precipitation) {
    final alerts = <String>[];

    if (temp > 35) {
      alerts.add('Heat wave warning');
    }
    if (temp < 5) {
      alerts.add('Frost warning');
    }
    if (precipitation > 20) {
      alerts.add('Heavy rainfall warning');
    }
    if (precipitation < 1) {
      alerts.add('Drought warning');
    }

    return alerts;
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < values.length; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumXX += i * i;
    }

    final n = values.length.toDouble();
    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Generate realistic Zimbabwe weather data
  List<Weather> _generateZimbabweWeatherData(
    DateTime startDate,
    DateTime endDate,
    String location,
  ) {
    final List<Weather> weatherData = [];
    final days = endDate.difference(startDate).inDays;

    for (int i = 0; i <= days; i++) {
      final date = startDate.add(Duration(days: i));
      final weather = _generateZimbabweDayWeather(date, location);
      weatherData.add(weather);
    }

    return weatherData;
  }

  /// Generate weather for a specific day based on Zimbabwe climate patterns
  Weather _generateZimbabweDayWeather(DateTime date, String location) {
    final month = date.month;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;

    // Zimbabwe has wet season (Nov-Apr) and dry season (May-Oct)
    final isWetSeason = month >= 11 || month <= 4;

    // Base temperatures for different Zimbabwe regions
    double baseTemp = _getZimbabweBaseTemp(location, month);

    // Add daily variation and seasonal patterns
    final tempVariation = (dayOfYear % 7) - 3; // Weekly pattern
    final seasonalVariation = isWetSeason ? 2.0 : -1.0;
    final temperature = baseTemp + tempVariation + seasonalVariation;

    // Humidity patterns based on season and location
    double humidity = _getZimbabweHumidity(location, month, isWetSeason);

    // Precipitation patterns - Zimbabwe gets most rain in wet season
    double precipitation = _getZimbabwePrecipitation(
      location,
      month,
      isWetSeason,
      dayOfYear,
    );

    // Wind patterns
    double windSpeed = _getZimbabweWindSpeed(location, month);
    String windDirection = _getZimbabweWindDirection(month);

    // Pressure patterns
    double pressure = _getZimbabwePressure(location, month, precipitation);

    // UV Index - Zimbabwe has high UV due to altitude and latitude
    double uvIndex = _getZimbabweUVIndex(month, precipitation);

    // Weather description based on conditions
    String description = _getZimbabweWeatherDescription(
      temperature,
      precipitation,
      humidity,
    );
    String icon = _getZimbabweWeatherIcon(description);

    return Weather(
      id: 'zimbabwe_${date.millisecondsSinceEpoch}',
      dateTime: date,
      temperature: temperature,
      humidity: humidity,
      precipitation: precipitation,
      windSpeed: windSpeed,
      windDirection: windDirection,
      pressure: pressure,
      visibility: precipitation > 5 ? 5.0 : 10.0,
      uvIndex: uvIndex,
      condition: description,
      description: description,
      icon: icon,
    );
  }

  /// Get base temperature for Zimbabwe regions
  double _getZimbabweBaseTemp(String location, int month) {
    // Zimbabwe temperature ranges by region
    if (location.toLowerCase().contains('harare')) {
      return month >= 10 && month <= 3 ? 26.0 : 20.0; // Harare - moderate
    } else if (location.toLowerCase().contains('bulawayo')) {
      return month >= 10 && month <= 3
          ? 28.0
          : 18.0; // Bulawayo - hotter, drier
    } else if (location.toLowerCase().contains('mutare')) {
      return month >= 10 && month <= 3 ? 24.0 : 19.0; // Mutare - cooler, wetter
    } else if (location.toLowerCase().contains('gweru')) {
      return month >= 10 && month <= 3 ? 27.0 : 19.0; // Gweru - moderate
    } else {
      return month >= 10 && month <= 3 ? 26.0 : 20.0; // Default
    }
  }

  /// Get humidity for Zimbabwe regions
  double _getZimbabweHumidity(String location, int month, bool isWetSeason) {
    double baseHumidity = isWetSeason ? 75.0 : 45.0;

    if (location.toLowerCase().contains('mutare')) {
      baseHumidity += 10; // Mutare is more humid
    } else if (location.toLowerCase().contains('bulawayo')) {
      baseHumidity -= 10; // Bulawayo is drier
    }

    // Add daily variation
    final variation = (month * 3 + DateTime.now().day) % 20 - 10;
    return (baseHumidity + variation).clamp(20.0, 95.0);
  }

  /// Get precipitation for Zimbabwe regions
  double _getZimbabwePrecipitation(
    String location,
    int month,
    bool isWetSeason,
    int dayOfYear,
  ) {
    if (!isWetSeason) {
      // Dry season - very little rain
      return (dayOfYear % 15 == 0) ? 0.5 + (dayOfYear % 3) : 0.0;
    }

    // Wet season - regular rainfall
    double baseRainfall = 0.0;

    // Peak rainfall months
    if (month == 12 || month == 1 || month == 2) {
      baseRainfall = 8.0; // Peak wet season
    } else if (month == 11 || month == 3) {
      baseRainfall = 5.0; // Early/late wet season
    } else if (month == 4 || month == 10) {
      baseRainfall = 3.0; // Transition months
    }

    // Regional variations
    if (location.toLowerCase().contains('mutare')) {
      baseRainfall *= 1.3; // Mutare gets more rain
    } else if (location.toLowerCase().contains('bulawayo')) {
      baseRainfall *= 0.7; // Bulawayo gets less rain
    }

    // Add daily variation
    if (dayOfYear % 3 == 0) {
      // Rain every 3rd day on average
      final variation = (dayOfYear % 10) + 1;
      return baseRainfall + variation;
    }

    return baseRainfall;
  }

  /// Get wind speed for Zimbabwe regions
  double _getZimbabweWindSpeed(String location, int month) {
    double baseWind = 5.0;

    // Seasonal variations
    if (month >= 5 && month <= 8) {
      baseWind += 2.0; // Windier in dry season
    }

    // Regional variations
    if (location.toLowerCase().contains('bulawayo')) {
      baseWind += 1.0; // Bulawayo is windier
    }

    return baseWind + (month % 5);
  }

  /// Get wind direction for Zimbabwe
  String _getZimbabweWindDirection(int month) {
    // Zimbabwe generally has easterly winds
    final directions = ['E', 'SE', 'NE', 'E', 'SE'];
    return directions[month % directions.length];
  }

  /// Get atmospheric pressure for Zimbabwe
  double _getZimbabwePressure(
    String location,
    int month,
    double precipitation,
  ) {
    double basePressure = 1013.0;

    // Zimbabwe is at high altitude, so lower pressure
    if (location.toLowerCase().contains('harare')) {
      basePressure = 1005.0; // Harare altitude ~1500m
    } else if (location.toLowerCase().contains('bulawayo')) {
      basePressure = 1008.0; // Bulawayo altitude ~1300m
    }

    // Pressure decreases with precipitation
    basePressure -= precipitation * 0.5;

    return basePressure + (month % 10) - 5;
  }

  /// Get UV Index for Zimbabwe
  double _getZimbabweUVIndex(int month, double precipitation) {
    double baseUV = 8.0; // Zimbabwe has high UV due to altitude and latitude

    // Seasonal variation
    if (month >= 10 && month <= 3) {
      baseUV += 1.0; // Higher UV in summer
    }

    // Reduce UV with cloud cover (precipitation)
    if (precipitation > 5) {
      baseUV -= 2.0;
    } else if (precipitation > 2) {
      baseUV -= 1.0;
    }

    return baseUV.clamp(1.0, 12.0);
  }

  /// Get weather description for Zimbabwe
  String _getZimbabweWeatherDescription(
    double temp,
    double precipitation,
    double humidity,
  ) {
    if (precipitation > 10) {
      return 'Heavy Rain';
    } else if (precipitation > 5) {
      return 'Moderate Rain';
    } else if (precipitation > 1) {
      return 'Light Rain';
    } else if (temp > 30) {
      return 'Hot and Sunny';
    } else if (temp > 25) {
      return 'Warm and Sunny';
    } else if (temp < 15) {
      return 'Cool and Clear';
    } else if (humidity > 80) {
      return 'Humid and Overcast';
    } else {
      return 'Partly Cloudy';
    }
  }

  /// Get weather icon for Zimbabwe
  String _getZimbabweWeatherIcon(String description) {
    if (description.contains('Heavy Rain')) return 'heavy_rain';
    if (description.contains('Moderate Rain')) return 'moderate_rain';
    if (description.contains('Light Rain')) return 'light_rain';
    if (description.contains('Hot') || description.contains('Warm'))
      return 'sunny';
    if (description.contains('Cool')) return 'clear';
    if (description.contains('Humid')) return 'cloudy';
    return 'partly_cloudy';
  }
}
