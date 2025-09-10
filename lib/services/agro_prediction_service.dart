import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weather.dart';
import '../models/agro_climatic_prediction.dart';
import '../models/weather_alert.dart';
import '../models/soil_data.dart';
import '../services/notification_service.dart';
import '../services/firebase_ai_service.dart';

class AgroPredictionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAIService _aiService = FirebaseAIService.instance;

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

  // 1. LONG-TERM AGRO-CLIMATIC DATA PREDICTION
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

      // Assess risks using AI
      final pestRisk = await _assessPestRisk(prediction, cropRecommendation);
      final diseaseRisk = await _assessDiseaseRisk(
        prediction,
        cropRecommendation,
      );

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
        soilMoisture: prediction['soil_moisture'] ?? 0.0,
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

  // 2. SEQUENTIAL WEATHER PATTERN ANALYSIS FROM HISTORICAL DATA
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
      final response = await _supabase
          .from('weather_data')
          .select()
          .eq('location', location)
          .gte('date_time', startDate.toIso8601String())
          .lte('date_time', (endDate ?? DateTime.now()).toIso8601String())
          .order('date_time', ascending: true);

      return response.map((json) => Weather.fromJson(json)).toList();
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

    // Analyze seasonal patterns
    final seasons = ['summer', 'autumn', 'winter', 'spring'];
    for (final season in seasons) {
      final seasonData = _filterBySeason(data, season);
      if (seasonData.isNotEmpty) {
        // Enhanced pattern analysis
        final tempData = seasonData.map((w) => w.temperature).toList();
        final humidityData = seasonData.map((w) => w.humidity).toList();
        final precipData = seasonData.map((w) => w.precipitation).toList();

        patterns.add(
          HistoricalWeatherPattern(
            id: '${season}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: seasonData.first.dateTime,
            endDate: seasonData.last.dateTime,
            location: seasonData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(tempData),
            totalPrecipitation: precipData.reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(humidityData),
            season: season,
            patternType: _determinePatternType(seasonData),
            anomalies: _detectAnomalies(seasonData),
            trends: _calculateEnhancedTrends(
              tempData,
              humidityData,
              precipData,
            ),
            summary: _generateEnhancedPatternSummary(seasonData, season),
          ),
        );
      }
    }

    // Add monthly patterns for more granular analysis
    patterns.addAll(_analyzeMonthlyPatterns(data));

    return patterns;
  }

  Future<Map<String, dynamic>> _generatePrediction(
    String location,
    DateTime startDate,
    int daysAhead,
    List<HistoricalWeatherPattern> patterns,
  ) async {
    final random = Random();

    // Enhanced prediction algorithm with historical pattern analysis
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
    } else {
      // Fallback to random values if no historical data
      baseTemp = 22.0 + (random.nextDouble() * 8.0);
      baseHumidity = 60.0 + (random.nextDouble() * 20.0);
      basePrecipitation = random.nextDouble() * 10.0;
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
      'soil_moisture': _calculateSoilMoisture(basePrecipitation, baseHumidity),
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
    try {
      // Try to use AI-powered recommendations first
      final currentWeather = Weather(
        id: '${location}_${DateTime.now().millisecondsSinceEpoch}',
        dateTime: DateTime.now(),
        temperature: prediction['temperature'] ?? 0.0,
        humidity: prediction['humidity'] ?? 0.0,
        precipitation: prediction['precipitation'] ?? 0.0,
        windSpeed: 10.0, // Default wind speed
        condition: 'Clear',
        description: 'AI Analysis',
        icon: '01d',
        pressure: 1013.25,
      );

      final soilData = SoilData(
        id: '${location}_soil_${DateTime.now().millisecondsSinceEpoch}',
        location: location,
        ph: 6.5, // Default pH
        organicMatter: 2.5,
        nitrogen: 15.0,
        phosphorus: 8.0,
        potassium: 120.0,
        soilMoisture: prediction['soil_moisture'] ?? 50.0,
        soilTemperature: prediction['temperature'] ?? 22.0,
        soilType: 'Loam',
        drainage: 'Good',
        texture: 'Medium',
        lastUpdated: DateTime.now(),
      );

      final season = _getCurrentSeason(DateTime.now());

      final aiRecommendations = await _aiService.generateCropRecommendations(
        currentWeather: currentWeather,
        soilData: soilData,
        location: location,
        season: season,
      );

      // Extract the best crop from AI recommendations
      final recommendedCrops =
          aiRecommendations['recommended_crops'] as List<String>?;
      if (recommendedCrops != null && recommendedCrops.isNotEmpty) {
        return recommendedCrops.first;
      }
    } catch (e) {
      print('AI crop recommendation failed, using fallback: $e');
    }

    // Fallback to traditional scoring method
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

  Future<String> _assessPestRisk(
    Map<String, dynamic> prediction,
    String crop,
  ) async {
    try {
      // Use AI-powered pest risk assessment
      final currentWeather = Weather(
        id: '${crop}_pest_${DateTime.now().millisecondsSinceEpoch}',
        dateTime: DateTime.now(),
        temperature: prediction['temperature'] ?? 0.0,
        humidity: prediction['humidity'] ?? 0.0,
        precipitation: prediction['precipitation'] ?? 0.0,
        windSpeed: 10.0,
        condition: 'Clear',
        description: 'Pest Risk Analysis',
        icon: '01d',
        pressure: 1013.25,
      );

      final aiAssessment = await _aiService.assessPestDiseaseRisk(
        currentWeather: currentWeather,
        crop: crop,
        growthStage: 'vegetative', // Default growth stage
        location: 'Zimbabwe',
      );

      final highRiskPests = aiAssessment['high_risk_pests'] as List<String>?;
      if (highRiskPests != null && highRiskPests.isNotEmpty) {
        return 'high';
      }

      final diseaseRisks = aiAssessment['disease_risks'] as List<String>?;
      if (diseaseRisks != null && diseaseRisks.isNotEmpty) {
        return 'medium';
      }

      return 'low';
    } catch (e) {
      print('AI pest risk assessment failed, using fallback: $e');

      // Fallback to traditional assessment
      final temp = prediction['temperature'] ?? 0.0;
      final humidity = prediction['humidity'] ?? 0.0;

      // High temperature and humidity increase pest risk
      if (temp > 28 && humidity > 75) return 'high';
      if (temp > 25 && humidity > 65) return 'medium';
      return 'low';
    }
  }

  Future<String> _assessDiseaseRisk(
    Map<String, dynamic> prediction,
    String crop,
  ) async {
    try {
      // Use AI-powered disease risk assessment
      final currentWeather = Weather(
        id: '${crop}_disease_${DateTime.now().millisecondsSinceEpoch}',
        dateTime: DateTime.now(),
        temperature: prediction['temperature'] ?? 0.0,
        humidity: prediction['humidity'] ?? 0.0,
        precipitation: prediction['precipitation'] ?? 0.0,
        windSpeed: 10.0,
        condition: 'Clear',
        description: 'Disease Risk Analysis',
        icon: '01d',
        pressure: 1013.25,
      );

      final aiAssessment = await _aiService.assessPestDiseaseRisk(
        currentWeather: currentWeather,
        crop: crop,
        growthStage: 'vegetative', // Default growth stage
        location: 'Zimbabwe',
      );

      final diseaseRisks = aiAssessment['disease_risks'] as List<String>?;
      if (diseaseRisks != null && diseaseRisks.isNotEmpty) {
        if (diseaseRisks.length > 2) return 'high';
        return 'medium';
      }

      return 'low';
    } catch (e) {
      print('AI disease risk assessment failed, using fallback: $e');

      // Fallback to traditional assessment
      final humidity = prediction['humidity'] ?? 0.0;
      final precipitation = prediction['precipitation'] ?? 0.0;

      // High humidity and precipitation increase disease risk
      if (humidity > 80 && precipitation > 5) return 'high';
      if (humidity > 70 && precipitation > 3) return 'medium';
      return 'low';
    }
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

  // 3. SMS AND PUSH NOTIFICATION ALERTS WITH RECOMMENDATIONS
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
    final soilMoisture = prediction['soil_moisture'] ?? 0.0;
    final precipitation = prediction['precipitation'] ?? 0.0;

    if (soilMoisture < 30) {
      return 'Immediate irrigation required - soil moisture critically low';
    } else if (soilMoisture < 50) {
      return 'Irrigation recommended within 24 hours';
    } else if (precipitation > 5) {
      return 'No irrigation needed - sufficient rainfall expected';
    } else {
      return 'Monitor soil moisture - irrigation may be needed soon';
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
    final soilMoisture = prediction['soil_moisture'] ?? 0.0;
    final temp = prediction['temperature'] ?? 0.0;

    return {
      'moisture_level': soilMoisture,
      'temperature': temp,
      'ph_level': 6.5, // Default pH
      'nutrient_status': soilMoisture > 50 ? 'good' : 'poor',
      'drainage': soilMoisture > 80 ? 'poor' : 'good',
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

  // Enhanced trend calculation with multiple data points
  Map<String, double> _calculateEnhancedTrends(
    List<double> tempData,
    List<double> humidityData,
    List<double> precipData,
  ) {
    if (tempData.length < 3) return {};

    // Calculate linear regression trends
    final tempTrend = _calculateLinearTrend(tempData);
    final humidityTrend = _calculateLinearTrend(humidityData);
    final precipTrend = _calculateLinearTrend(precipData);

    return {
      'temperature_trend': tempTrend,
      'humidity_trend': humidityTrend,
      'precipitation_trend': precipTrend,
      'volatility_temperature': _calculateVolatility(tempData),
      'volatility_humidity': _calculateVolatility(humidityData),
      'volatility_precipitation': _calculateVolatility(precipData),
    };
  }

  // Calculate linear trend using simple linear regression
  double _calculateLinearTrend(List<double> data) {
    if (data.length < 2) return 0.0;

    final n = data.length;
    final x = List.generate(n, (i) => i.toDouble());

    final sumX = x.reduce((a, b) => a + b);
    final sumY = data.reduce((a, b) => a + b);
    final sumXY = x
        .asMap()
        .entries
        .map((e) => e.key * data[e.key])
        .reduce((a, b) => a + b);
    final sumXX = x.map((x) => x * x).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  // Calculate volatility (standard deviation)
  double _calculateVolatility(List<double> data) {
    if (data.length < 2) return 0.0;

    final mean = _calculateAverage(data);
    final variance =
        data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        data.length;
    return variance;
  }

  // Analyze monthly patterns for more granular insights
  List<HistoricalWeatherPattern> _analyzeMonthlyPatterns(List<Weather> data) {
    final monthlyPatterns = <HistoricalWeatherPattern>[];
    final monthlyData = <int, List<Weather>>{};

    // Group data by month
    for (final weather in data) {
      final month = weather.dateTime.month;
      monthlyData[month] ??= [];
      monthlyData[month]!.add(weather);
    }

    // Analyze each month
    for (final entry in monthlyData.entries) {
      final monthData = entry.value;
      if (monthData.length >= 5) {
        // Need minimum data points
        final monthName = _getMonthName(entry.key);
        final tempData = monthData.map((w) => w.temperature).toList();
        final humidityData = monthData.map((w) => w.humidity).toList();
        final precipData = monthData.map((w) => w.precipitation).toList();

        monthlyPatterns.add(
          HistoricalWeatherPattern(
            id: 'monthly_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: monthData.first.dateTime,
            endDate: monthData.last.dateTime,
            location: monthData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(tempData),
            totalPrecipitation: precipData.reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(humidityData),
            season: monthName,
            patternType: _determinePatternType(monthData),
            anomalies: _detectAnomalies(monthData),
            trends: _calculateEnhancedTrends(
              tempData,
              humidityData,
              precipData,
            ),
            summary: _generateEnhancedPatternSummary(monthData, monthName),
          ),
        );
      }
    }

    return monthlyPatterns;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Enhanced pattern summary with more detailed analysis
  String _generateEnhancedPatternSummary(List<Weather> data, String period) {
    if (data.isEmpty) return 'No data available for $period';

    final avgTemp = _calculateAverage(data.map((w) => w.temperature).toList());
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);
    final avgHumidity = _calculateAverage(data.map((w) => w.humidity).toList());
    final maxTemp = data
        .map((w) => w.temperature)
        .reduce((a, b) => a > b ? a : b);
    final minTemp = data
        .map((w) => w.temperature)
        .reduce((a, b) => a < b ? a : b);

    return '$period: Avg ${avgTemp.toStringAsFixed(1)}°C (${minTemp.toStringAsFixed(1)}-${maxTemp.toStringAsFixed(1)}°C), '
        'Precip ${totalPrecip.toStringAsFixed(1)}mm, '
        'Humidity ${avgHumidity.toStringAsFixed(1)}%';
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

  double _calculateSoilMoisture(double precipitation, double humidity) {
    return (precipitation * 2 + humidity * 0.3).clamp(0.0, 100.0);
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

  // NEW: Get comprehensive AI insights for agricultural recommendations
  Future<Map<String, dynamic>> getAIInsights({
    required String location,
    required Weather currentWeather,
    required SoilData soilData,
    required String crop,
    required String growthStage,
  }) async {
    try {
      // Initialize AI service if not already done
      await _aiService.initialize();

      // Get comprehensive AI insights
      final cropRecommendations = await _aiService.generateCropRecommendations(
        currentWeather: currentWeather,
        soilData: soilData,
        location: location,
        season: _getCurrentSeason(DateTime.now()),
      );

      final pestDiseaseAssessment = await _aiService.assessPestDiseaseRisk(
        currentWeather: currentWeather,
        crop: crop,
        growthStage: growthStage,
        location: location,
      );

      final irrigationAdvice = await _aiService.generateIrrigationAdvice(
        currentWeather: currentWeather,
        soilData: soilData,
        crop: crop,
        growthStage: growthStage,
        location: location,
      );

      final farmingCalendar = await _aiService.generateFarmingCalendar(
        location: location,
        crop: crop,
        startDate: DateTime.now(),
      );

      final marketInsights = await _aiService.generateMarketInsights(
        crop: crop,
        location: location,
        harvestDate: DateTime.now().add(const Duration(days: 120)),
      );

      return {
        'crop_recommendations': cropRecommendations,
        'pest_disease_assessment': pestDiseaseAssessment,
        'irrigation_advice': irrigationAdvice,
        'farming_calendar': farmingCalendar,
        'market_insights': marketInsights,
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
        'crop': crop,
        'growth_stage': growthStage,
      };
    } catch (e) {
      print('Error getting AI insights: $e');
      return {
        'error': 'Failed to get AI insights: $e',
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
        'crop': crop,
        'growth_stage': growthStage,
      };
    }
  }

  // NEW: Get AI-enhanced weather pattern analysis
  Future<Map<String, dynamic>> getAIWeatherAnalysis({
    required String location,
    required List<Weather> historicalData,
    required int daysAhead,
  }) async {
    try {
      await _aiService.initialize();

      final weatherAnalysis = await _aiService.analyzeWeatherPatterns(
        historicalData: historicalData,
        location: location,
        daysAhead: daysAhead,
      );

      return {
        'weather_analysis': weatherAnalysis,
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
        'days_ahead': daysAhead,
        'data_points': historicalData.length,
      };
    } catch (e) {
      print('Error getting AI weather analysis: $e');
      return {
        'error': 'Failed to get AI weather analysis: $e',
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
        'days_ahead': daysAhead,
        'data_points': historicalData.length,
      };
    }
  }
}
