import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weather.dart';
import '../models/agro_climatic_prediction.dart';
import '../models/weather_alert.dart';
import '../services/notification_service.dart';

class AgroPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Zimbabwe crop data and climate zones
  final Map<String, Map<String, dynamic>> _cropData = {
    'maize': {
      'optimal_temp_min': 18.0,
      'optimal_temp_max': 24.0,
      'optimal_humidity_min': 60.0,
      'optimal_humidity_max': 80.0,
      'water_requirement': 500.0, // mm per season
      'growing_period': 120, // days
      'soil_ph_min': 5.5,
      'soil_ph_max': 7.0,
    },
    'wheat': {
      'optimal_temp_min': 15.0,
      'optimal_temp_max': 20.0,
      'optimal_humidity_min': 50.0,
      'optimal_humidity_max': 70.0,
      'water_requirement': 400.0,
      'growing_period': 150,
      'soil_ph_min': 6.0,
      'soil_ph_max': 7.5,
    },
    'sorghum': {
      'optimal_temp_min': 20.0,
      'optimal_temp_max': 30.0,
      'optimal_humidity_min': 40.0,
      'optimal_humidity_max': 60.0,
      'water_requirement': 300.0,
      'growing_period': 100,
      'soil_ph_min': 5.0,
      'soil_ph_max': 8.0,
    },
    'cotton': {
      'optimal_temp_min': 21.0,
      'optimal_temp_max': 30.0,
      'optimal_humidity_min': 50.0,
      'optimal_humidity_max': 70.0,
      'water_requirement': 600.0,
      'growing_period': 180,
      'soil_ph_min': 5.5,
      'soil_ph_max': 7.0,
    },
    'tobacco': {
      'optimal_temp_min': 20.0,
      'optimal_temp_max': 28.0,
      'optimal_humidity_min': 60.0,
      'optimal_humidity_max': 80.0,
      'water_requirement': 400.0,
      'growing_period': 120,
      'soil_ph_min': 5.5,
      'soil_ph_max': 6.5,
    },
  };

  // final Map<String, List<String>> _pestDiseaseData = {
  //   'maize': ['armyworm', 'stalk_borer', 'gray_leaf_spot', 'rust'],
  //   'wheat': ['rust', 'powdery_mildew', 'aphids', 'thrips'],
  //   'sorghum': ['aphids', 'head_bug', 'anthracnose', 'downy_mildew'],
  //   'cotton': ['bollworm', 'aphids', 'bacterial_blight', 'verticillium_wilt'],
  //   'tobacco': ['aphids', 'thrips', 'blue_mold', 'brown_spot'],
  // };

  Future<AgroClimaticPrediction> generateLongTermPrediction({
    required String location,
    required DateTime startDate,
    required int daysAhead,
  }) async {
    try {
      // Get historical data for pattern analysis
      final historicalData = await _getHistoricalData(
        location,
        startDate.subtract(const Duration(days: 365)),
      );

      // Analyze patterns and trends
      final patterns = await _analyzeWeatherPatterns(historicalData);

      // Generate predictions based on historical patterns and current conditions
      final prediction = await _generatePrediction(
        location,
        startDate,
        daysAhead,
        patterns,
      );

      // Get crop recommendations
      final cropRecommendation = await _getCropRecommendation(
        location,
        prediction,
      );

      // Assess risks
      final pestRisk = _assessPestRisk(prediction, cropRecommendation);
      final diseaseRisk = _assessDiseaseRisk(prediction, cropRecommendation);

      // Calculate yield prediction
      final yieldPrediction = _calculateYieldPrediction(
        prediction,
        cropRecommendation,
      );

      // Generate alerts
      final weatherAlerts = _generateWeatherAlerts(prediction);

      // Send notifications for critical alerts
      await _sendCriticalAlerts(weatherAlerts, location);

      return AgroClimaticPrediction(
        id: '${location}_${startDate.millisecondsSinceEpoch}',
        date: startDate,
        location: location,
        temperature: prediction['temperature'] ?? 0.0,
        humidity: prediction['humidity'] ?? 0.0,
        precipitation: prediction['precipitation'] ?? 0.0,
        evapotranspiration: prediction['evapotranspiration'] ?? 0.0,
        cropRecommendation: cropRecommendation,
        irrigationAdvice: _generateIrrigationAdvice(prediction),
        pestRisk: pestRisk,
        diseaseRisk: diseaseRisk,
        yieldPrediction: yieldPrediction,
        plantingAdvice: _generatePlantingAdvice(prediction, cropRecommendation),
        harvestingAdvice: _generateHarvestingAdvice(
          prediction,
          cropRecommendation,
        ),
        weatherAlerts: weatherAlerts,
        soilConditions: _assessSoilConditions(prediction),
        climateIndicators: _calculateClimateIndicators(prediction, patterns),
      );
    } catch (e) {
      throw Exception('Failed to generate prediction: $e');
    }
  }

  Future<List<HistoricalWeatherPattern>> analyzeSequentialPatterns({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final historicalData = await _getHistoricalData(
        location,
        startDate,
        endDate,
      );
      return await _analyzeWeatherPatterns(historicalData);
    } catch (e) {
      throw Exception('Failed to analyze patterns: $e');
    }
  }

  Future<List<Weather>> _getHistoricalData(
    String location,
    DateTime startDate, [
    DateTime? endDate,
  ]) async {
    try {
      final snapshot = await _firestore
          .collection('weather_data')
          .where('location_name', isEqualTo: location)
          .where(
            'date_time',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where(
            'date_time',
            isLessThanOrEqualTo: (endDate ?? DateTime.now()).toIso8601String(),
          )
          .orderBy('date_time', descending: false)
          .get();

      return snapshot.docs.map((doc) => Weather.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception(
        'Failed to fetch historical weather data for $location: $e',
      );
    }
  }

  Future<List<HistoricalWeatherPattern>> _analyzeWeatherPatterns(
    List<Weather> data,
  ) async {
    if (data.isEmpty) return [];

    final patterns = <HistoricalWeatherPattern>[];
    // final random = Random();

    // Analyze seasonal patterns
    final seasons = ['summer', 'autumn', 'winter', 'spring'];
    for (final season in seasons) {
      final seasonData = _filterBySeason(data, season);
      if (seasonData.isNotEmpty) {
        patterns.add(
          HistoricalWeatherPattern(
            id: '${season}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: seasonData.first.dateTime,
            endDate: seasonData.last.dateTime,
            location: seasonData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(
              seasonData.map((w) => w.temperature).toList(),
            ),
            totalPrecipitation: seasonData
                .map((w) => w.precipitation)
                .reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(
              seasonData.map((w) => w.humidity).toList(),
            ),
            season: season,
            patternType: _determinePatternType(seasonData),
            anomalies: _detectAnomalies(seasonData),
            trends: _calculateTrends(seasonData),
            summary: _generatePatternSummary(seasonData, season),
          ),
        );
      }
    }

    return patterns;
  }

  Future<Map<String, dynamic>> _generatePrediction(
    String location,
    DateTime startDate,
    int daysAhead,
    List<HistoricalWeatherPattern> patterns,
  ) async {
    // Use historical patterns for more accurate predictions
    double baseTemp = 22.0;
    double baseHumidity = 60.0;
    double basePrecipitation = 0.0;

    // Analyze historical patterns for more accurate predictions
    if (patterns.isNotEmpty) {
      final currentSeason = _getCurrentSeason(startDate);
      final seasonPattern = patterns.firstWhere(
        (pattern) => pattern.season == currentSeason,
        orElse: () => patterns.first,
      );

      // Use historical averages as base values
      baseTemp = seasonPattern.averageTemperature;
      baseHumidity = seasonPattern.averageHumidity;
      basePrecipitation =
          seasonPattern.totalPrecipitation / 30; // Daily average

      // Add some variation based on historical trends
      final tempTrend = seasonPattern.trends['temperature_trend'] ?? 0.0;
      final humidityTrend = seasonPattern.trends['humidity_trend'] ?? 0.0;

      baseTemp += tempTrend * (daysAhead / 30.0); // Trend over time
      baseHumidity += humidityTrend * (daysAhead / 30.0);
    }

    // Apply seasonal adjustments based on patterns
    final seasonalAdjustment = _getSeasonalAdjustment(startDate, patterns);

    // Add some realistic daily variation
    final dailyVariation = _getDailyVariation(startDate, daysAhead);

    return {
      'temperature':
          (baseTemp +
                  (seasonalAdjustment['temperature'] as double) +
                  dailyVariation['temperature']!)
              .clamp(5.0, 45.0),
      'humidity':
          (baseHumidity +
                  (seasonalAdjustment['humidity'] as double) +
                  dailyVariation['humidity']!)
              .clamp(10.0, 100.0),
      'precipitation':
          (basePrecipitation +
                  (seasonalAdjustment['precipitation'] as double) +
                  dailyVariation['precipitation']!)
              .clamp(0.0, 50.0),
      'evapotranspiration': _calculateEvapotranspiration(
        baseTemp,
        baseHumidity,
      ),
    };
  }

  Future<String> _getCropRecommendation(
    String location,
    Map<String, dynamic> prediction,
  ) async {
    final temp = prediction['temperature'] ?? 0.0;
    final humidity = prediction['humidity'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    // Score each crop based on current conditions
    final cropScores = <String, double>{};

    for (final crop in _cropData.keys) {
      final cropInfo = _cropData[crop]!;
      double score = 0.0;

      // Temperature suitability
      if (temp >= cropInfo['optimal_temp_min'] &&
          temp <= cropInfo['optimal_temp_max']) {
        score += 3.0;
      } else {
        score += 1.0;
      }

      // Humidity suitability
      if (humidity >= cropInfo['optimal_humidity_min'] &&
          humidity <= cropInfo['optimal_humidity_max']) {
        score += 2.0;
      } else {
        score += 0.5;
      }

      // Precipitation suitability
      if (precipitation >= cropInfo['water_requirement'] / 30) {
        // Daily requirement
        score += 2.0;
      } else {
        score += 0.5;
      }

      cropScores[crop] = score;
    }

    // Return the highest scoring crop
    final bestCrop = cropScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return bestCrop;
  }

  String _assessPestRisk(Map<String, dynamic> prediction, String crop) {
    final temp = prediction['temperature'] ?? 0.0;
    final humidity = prediction['humidity'] ?? 0.0;

    // High temperature and humidity increase pest risk
    if (temp > 28 && humidity > 75) return 'high';
    if (temp > 25 && humidity > 65) return 'medium';
    return 'low';
  }

  String _assessDiseaseRisk(Map<String, dynamic> prediction, String crop) {
    final humidity = prediction['humidity'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    // High humidity and precipitation increase disease risk
    if (humidity > 80 && precipitation > 5) return 'high';
    if (humidity > 70 && precipitation > 3) return 'medium';
    return 'low';
  }

  double _calculateYieldPrediction(
    Map<String, dynamic> prediction,
    String crop,
  ) {
    final temp = prediction['temperature'] ?? 0.0;
    final humidity = prediction['humidity'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    double baseYield = 70.0; // Base yield percentage

    // Temperature impact
    final cropInfo = _cropData[crop]!;
    if (temp >= cropInfo['optimal_temp_min'] &&
        temp <= cropInfo['optimal_temp_max']) {
      baseYield += 20.0;
    } else {
      baseYield -= 15.0;
    }

    // Humidity impact
    if (humidity >= cropInfo['optimal_humidity_min'] &&
        humidity <= cropInfo['optimal_humidity_max']) {
      baseYield += 10.0;
    } else {
      baseYield -= 10.0;
    }

    // Precipitation impact
    final dailyWaterNeed = cropInfo['water_requirement'] / 30;
    if (precipitation >= dailyWaterNeed * 0.8) {
      baseYield += 15.0;
    } else {
      baseYield -= 20.0;
    }

    return baseYield.clamp(0.0, 100.0);
  }

  List<String> _generateWeatherAlerts(Map<String, dynamic> prediction) {
    final alerts = <String>[];
    final temp = prediction['temperature'] ?? 0.0;
    final humidity = prediction['humidity'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    if (temp > 35) alerts.add('High temperature warning');
    if (temp < 5) alerts.add('Frost warning');
    if (humidity > 85) alerts.add('High humidity - disease risk');
    if (precipitation > 20) alerts.add('Heavy rainfall expected');
    if (precipitation < 1 && temp > 25) alerts.add('Drought conditions');

    return alerts;
  }

  Future<void> _sendCriticalAlerts(List<String> alerts, String location) async {
    for (final alert in alerts) {
      if (alert.contains('warning') ||
          alert.contains('drought') ||
          alert.contains('frost')) {
        final weatherAlert = WeatherAlert(
          id: '${location}_${DateTime.now().millisecondsSinceEpoch}',
          title: alert,
          description: 'Critical weather condition detected in $location',
          severity: 'high',
          duration: '24 hours',
          location: location,
          date: DateTime.now(),
          icon: 'warning',
          type: 'weather',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 24)),
          isActive: true,
          recommendations: [
            'Monitor conditions closely',
            'Take necessary precautions',
          ],
        );
        await NotificationService.sendWeatherAlert(
          title: weatherAlert.title,
          message: weatherAlert.description,
          severity: weatherAlert.severity,
          location: weatherAlert.location,
        );
      }
    }
  }

  String _generateIrrigationAdvice(Map<String, dynamic> prediction) {
    final precipitation = prediction['precipitation'] ?? 0.0;

    if (precipitation > 5) {
      return 'No irrigation needed - sufficient rainfall expected';
    } else {
      return 'Monitor soil conditions - irrigation may be needed soon';
    }
  }

  String _generatePlantingAdvice(Map<String, dynamic> prediction, String crop) {
    final temp = prediction['temperature'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;
    final cropInfo = _cropData[crop]!;

    if (temp >= cropInfo['optimal_temp_min'] &&
        temp <= cropInfo['optimal_temp_max'] &&
        precipitation > 2) {
      return 'Optimal conditions for planting $crop';
    } else if (temp < cropInfo['optimal_temp_min']) {
      return 'Wait for warmer temperatures before planting $crop';
    } else if (precipitation < 1) {
      return 'Ensure adequate irrigation before planting $crop';
    } else {
      return 'Conditions are suitable for planting $crop with proper preparation';
    }
  }

  String _generateHarvestingAdvice(
    Map<String, dynamic> prediction,
    String crop,
  ) {
    final temp = prediction['temperature'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    if (precipitation > 10) {
      return 'Delay harvesting due to expected heavy rainfall';
    } else if (temp > 30) {
      return 'Harvest early morning to avoid heat stress';
    } else {
      return 'Good conditions for harvesting';
    }
  }

  Map<String, dynamic> _assessSoilConditions(Map<String, dynamic> prediction) {
    final temp = prediction['temperature'] ?? 0.0;

    return {
      'temperature': temp,
      'ph_level': 6.5, // Default pH
      'nutrient_status': 'good',
      'drainage': 'good',
    };
  }

  Map<String, dynamic> _calculateClimateIndicators(
    Map<String, dynamic> prediction,
    List<HistoricalWeatherPattern> patterns,
  ) {
    return {
      'temperature_trend': 'stable',
      'precipitation_trend': 'increasing',
      'humidity_trend': 'stable',
      'seasonal_deviation': 0.5,
      'climate_risk_index': 0.3,
    };
  }

  // Helper methods
  List<Weather> _filterBySeason(List<Weather> data, String season) {
    return data.where((weather) {
      final month = weather.dateTime.month;
      switch (season) {
        case 'summer':
          return month >= 12 || month <= 2;
        case 'autumn':
          return month >= 3 && month <= 5;
        case 'winter':
          return month >= 6 && month <= 8;
        case 'spring':
          return month >= 9 && month <= 11;
        default:
          return false;
      }
    }).toList();
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _determinePatternType(List<Weather> data) {
    if (data.isEmpty) return 'unknown';

    final avgTemp = _calculateAverage(data.map((w) => w.temperature).toList());
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    if (avgTemp > 25 && totalPrecip > 100) return 'hot_wet';
    if (avgTemp > 25 && totalPrecip < 50) return 'hot_dry';
    if (avgTemp < 15 && totalPrecip > 100) return 'cool_wet';
    if (avgTemp < 15 && totalPrecip < 50) return 'cool_dry';
    return 'moderate';
  }

  List<String> _detectAnomalies(List<Weather> data) {
    final anomalies = <String>[];
    if (data.isEmpty) return anomalies;

    final temps = data.map((w) => w.temperature).toList();
    final avgTemp = _calculateAverage(temps);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);

    if (maxTemp > avgTemp + 10) anomalies.add('extreme_high_temperature');
    if (minTemp < avgTemp - 10) anomalies.add('extreme_low_temperature');

    return anomalies;
  }

  Map<String, double> _calculateTrends(List<Weather> data) {
    if (data.length < 2) return {};

    final temps = data.map((w) => w.temperature).toList();
    final firstHalf = temps.take(temps.length ~/ 2).toList();
    final secondHalf = temps.skip(temps.length ~/ 2).toList();

    final firstAvg = _calculateAverage(firstHalf);
    final secondAvg = _calculateAverage(secondHalf);

    return {
      'temperature_trend': secondAvg - firstAvg,
      'precipitation_trend': 0.0, // Simplified
      'humidity_trend': 0.0, // Simplified
    };
  }

  String _generatePatternSummary(List<Weather> data, String season) {
    if (data.isEmpty) return 'No data available for $season';

    final avgTemp = _calculateAverage(data.map((w) => w.temperature).toList());
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    return '$season: Average temperature ${avgTemp.toStringAsFixed(1)}°C, Total precipitation ${totalPrecip.toStringAsFixed(1)}mm';
  }

  Map<String, double> _getSeasonalAdjustment(
    DateTime date,
    List<HistoricalWeatherPattern> patterns,
  ) {
    // Simplified seasonal adjustments
    final month = date.month;
    if (month >= 12 || month <= 2) {
      return {
        'temperature': 3.0,
        'humidity': 10.0,
        'precipitation': 2.0,
      }; // Summer
    } else if (month >= 3 && month <= 5) {
      return {
        'temperature': -2.0,
        'humidity': -5.0,
        'precipitation': 1.0,
      }; // Autumn
    } else if (month >= 6 && month <= 8) {
      return {
        'temperature': -5.0,
        'humidity': -15.0,
        'precipitation': -1.0,
      }; // Winter
    } else {
      return {
        'temperature': 1.0,
        'humidity': 5.0,
        'precipitation': 0.5,
      }; // Spring
    }
  }

  double _calculateEvapotranspiration(double temperature, double humidity) {
    return (temperature * 0.5 - humidity * 0.2).clamp(0.0, 10.0);
  }

  // Get current season based on date
  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 12 || month <= 2) return 'summer';
    if (month >= 3 && month <= 5) return 'autumn';
    if (month >= 6 && month <= 8) return 'winter';
    return 'spring';
  }

  // Get daily variation for more realistic predictions
  Map<String, double> _getDailyVariation(DateTime date, int daysAhead) {
    final random = Random(date.millisecondsSinceEpoch + daysAhead);

    // Simulate weather fronts and daily patterns
    final tempVariation = (random.nextDouble() - 0.5) * 6.0; // ±3°C
    final humidityVariation = (random.nextDouble() - 0.5) * 20.0; // ±10%
    final precipVariation = random.nextDouble() * 5.0; // 0-5mm

    return {
      'temperature': tempVariation,
      'humidity': humidityVariation,
      'precipitation': precipVariation,
    };
  }
}
