import 'dart:math';
import '../models/agro_climatic_prediction.dart';
import '../models/weather_pattern.dart';
import '../models/agricultural_recommendation.dart';

class AgroClimaticService {
  static final AgroClimaticService _instance = AgroClimaticService._internal();
  factory AgroClimaticService() => _instance;
  AgroClimaticService._internal();

  // Generate long-term agro-climatic predictions
  Future<List<AgroClimaticPrediction>> generatePredictions({
    required String location,
    required String cropType,
    int days = 30,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    final predictions = <AgroClimaticPrediction>[];
    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      
      // Generate realistic predictions based on crop type and season
      final baseTemp = _getBaseTemperature(cropType, date);
      final baseRainfall = _getBaseRainfall(cropType, date);
      final baseHumidity = _getBaseHumidity(cropType, date);

      predictions.add(AgroClimaticPrediction(
        id: 'pred_${i}_${date.millisecondsSinceEpoch}',
        location: location,
        cropType: cropType,
        date: date,
        predictedRainfall: (baseRainfall + (random.nextDouble() - 0.5) * 10).clamp(0, 50),
        predictedTemperature: (baseTemp + (random.nextDouble() - 0.5) * 8).clamp(15, 35),
        predictedHumidity: (baseHumidity + (random.nextDouble() - 0.5) * 20).clamp(30, 90),
        soilMoisture: (random.nextDouble() * 100).clamp(0, 100),
        confidence: (0.7 + random.nextDouble() * 0.3).clamp(0, 1),
        status: _getPredictionStatus(random),
        validUntil: date.add(const Duration(days: 1)),
        recommendations: _generateRecommendations(cropType, baseTemp, baseRainfall),
      ));
    }

    return predictions;
  }

  // Analyze sequential weather patterns from historical data
  Future<List<WeatherPattern>> analyzeWeatherPatterns({
    required String location,
    int days = 90,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    final patterns = <WeatherPattern>[];
    final random = Random();
    final now = DateTime.now();

    // Generate different types of weather patterns
    final patternTypes = [
      'Drought Period',
      'Heavy Rainfall',
      'Temperature Anomaly',
      'Humidity Spike',
      'Wind Pattern Change',
      'Seasonal Transition',
    ];

    for (int i = 0; i < 3; i++) {
      final startDate = now.subtract(Duration(days: random.nextInt(days)));
      final endDate = startDate.add(Duration(days: random.nextInt(14) + 3));
      final patternType = patternTypes[random.nextInt(patternTypes.length)];

      patterns.add(WeatherPattern(
        id: 'pattern_${i}_${startDate.millisecondsSinceEpoch}',
        location: location,
        startDate: startDate,
        endDate: endDate,
        patternType: patternType,
        description: _getPatternDescription(patternType),
        severity: random.nextDouble() * 10,
        indicators: _getPatternIndicators(patternType),
        statistics: _getPatternStatistics(patternType, random),
        impacts: _getPatternImpacts(patternType),
        recommendations: _getPatternRecommendations(patternType),
      ));
    }

    return patterns;
  }

  // Generate agricultural recommendations based on predictions and patterns
  Future<List<AgriculturalRecommendation>> generateRecommendations({
    required String location,
    required String cropType,
    List<AgroClimaticPrediction>? predictions,
    List<WeatherPattern>? patterns,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    final recommendations = <AgriculturalRecommendation>[];
    final random = Random();
    final now = DateTime.now();

    // Generate recommendations based on current conditions
    final recommendationTypes = [
      'Irrigation Management',
      'Pest Control',
      'Fertilizer Application',
      'Harvest Timing',
      'Crop Protection',
      'Soil Management',
    ];

    for (int i = 0; i < 5; i++) {
      final type = recommendationTypes[random.nextInt(recommendationTypes.length)];
      
      recommendations.add(AgriculturalRecommendation(
        id: 'rec_${i}_${now.millisecondsSinceEpoch}',
        title: _getRecommendationTitle(type),
        description: _getRecommendationDescription(type, cropType),
        category: type,
        priority: _getRecommendationPriority(type, random),
        date: now,
        location: location,
        cropType: cropType,
        actions: _getRecommendationActions(type),
        conditions: _getRecommendationConditions(type),
        createdAt: now,
      ));
    }

    return recommendations;
  }

  // Helper methods for generating realistic data
  double _getBaseTemperature(String cropType, DateTime date) {
    final month = date.month;
    switch (cropType.toLowerCase()) {
      case 'maize':
        return month >= 10 || month <= 3 ? 25.0 : 20.0; // Summer crop
      case 'wheat':
        return month >= 4 && month <= 9 ? 22.0 : 18.0; // Winter crop
      case 'cotton':
        return month >= 9 || month <= 4 ? 28.0 : 25.0; // Warm season
      default:
        return 23.0;
    }
  }

  double _getBaseRainfall(String cropType, DateTime date) {
    final month = date.month;
    // Zimbabwe has wet season from Nov-Apr
    if (month >= 11 || month <= 4) {
      return 15.0; // Wet season
    } else {
      return 2.0; // Dry season
    }
  }

  double _getBaseHumidity(String cropType, DateTime date) {
    final month = date.month;
    if (month >= 11 || month <= 4) {
      return 70.0; // Higher humidity in wet season
    } else {
      return 50.0; // Lower humidity in dry season
    }
  }

  String _getPredictionStatus(Random random) {
    final statuses = ['accurate', 'moderate', 'uncertain'];
    return statuses[random.nextInt(statuses.length)];
  }

  List<String> _generateRecommendations(String cropType, double temp, double rainfall) {
    final recommendations = <String>[];
    
    if (rainfall < 5) {
      recommendations.add('Consider irrigation scheduling');
    }
    if (temp > 30) {
      recommendations.add('Monitor for heat stress');
    }
    if (rainfall > 20) {
      recommendations.add('Check drainage systems');
    }
    
    recommendations.add('Regular soil moisture monitoring');
    recommendations.add('Pest and disease surveillance');
    
    return recommendations;
  }

  String _getPatternDescription(String patternType) {
    switch (patternType) {
      case 'Drought Period':
        return 'Extended period of below-average rainfall affecting crop growth';
      case 'Heavy Rainfall':
        return 'Intense rainfall events causing potential flooding and soil erosion';
      case 'Temperature Anomaly':
        return 'Unusual temperature patterns affecting crop development';
      case 'Humidity Spike':
        return 'High humidity levels increasing disease risk';
      case 'Wind Pattern Change':
        return 'Altered wind patterns affecting pollination and pest movement';
      case 'Seasonal Transition':
        return 'Transition between seasons affecting crop timing';
      default:
        return 'Weather pattern analysis';
    }
  }

  List<String> _getPatternIndicators(String patternType) {
    switch (patternType) {
      case 'Drought Period':
        return ['Low soil moisture', 'Reduced rainfall', 'High evapotranspiration'];
      case 'Heavy Rainfall':
        return ['High precipitation', 'Soil saturation', 'Runoff increase'];
      case 'Temperature Anomaly':
        return ['Temperature deviation', 'Heat stress', 'Cold stress'];
      case 'Humidity Spike':
        return ['High relative humidity', 'Dew formation', 'Disease pressure'];
      case 'Wind Pattern Change':
        return ['Wind speed variation', 'Direction change', 'Turbulence'];
      case 'Seasonal Transition':
        return ['Temperature shift', 'Daylight change', 'Precipitation pattern'];
      default:
        return ['Weather monitoring'];
    }
  }

  Map<String, dynamic> _getPatternStatistics(String patternType, Random random) {
    switch (patternType) {
      case 'Drought Period':
        return {
          'rainfall_deficit': (random.nextDouble() * 50).toStringAsFixed(1),
          'duration_days': random.nextInt(30) + 10,
          'severity_index': (random.nextDouble() * 10).toStringAsFixed(1),
        };
      case 'Heavy Rainfall':
        return {
          'total_rainfall': (random.nextDouble() * 100 + 50).toStringAsFixed(1),
          'max_daily': (random.nextDouble() * 50 + 20).toStringAsFixed(1),
          'flood_risk': (random.nextDouble() * 10).toStringAsFixed(1),
        };
      case 'Temperature Anomaly':
        return {
          'avg_deviation': (random.nextDouble() * 5 + 2).toStringAsFixed(1),
          'max_deviation': (random.nextDouble() * 8 + 3).toStringAsFixed(1),
          'duration_hours': random.nextInt(72) + 24,
        };
      default:
        return {
          'intensity': (random.nextDouble() * 10).toStringAsFixed(1),
          'duration': random.nextInt(30) + 1,
        };
    }
  }

  List<String> _getPatternImpacts(String patternType) {
    switch (patternType) {
      case 'Drought Period':
        return ['Reduced crop yield', 'Water stress', 'Delayed planting'];
      case 'Heavy Rainfall':
        return ['Soil erosion', 'Nutrient leaching', 'Disease spread'];
      case 'Temperature Anomaly':
        return ['Heat stress', 'Reduced pollination', 'Quality issues'];
      case 'Humidity Spike':
        return ['Fungal diseases', 'Pest outbreaks', 'Harvest delays'];
      case 'Wind Pattern Change':
        return ['Pollination issues', 'Physical damage', 'Pest migration'];
      case 'Seasonal Transition':
        return ['Timing adjustments', 'Crop rotation', 'Management changes'];
      default:
        return ['Agricultural impact'];
    }
  }

  List<String> _getPatternRecommendations(String patternType) {
    switch (patternType) {
      case 'Drought Period':
        return ['Implement water conservation', 'Use drought-resistant varieties', 'Adjust planting dates'];
      case 'Heavy Rainfall':
        return ['Improve drainage', 'Use cover crops', 'Monitor soil health'];
      case 'Temperature Anomaly':
        return ['Provide shade', 'Adjust irrigation', 'Monitor crop stress'];
      case 'Humidity Spike':
        return ['Increase air circulation', 'Apply fungicides', 'Monitor disease'];
      case 'Wind Pattern Change':
        return ['Install windbreaks', 'Adjust planting density', 'Monitor pollination'];
      case 'Seasonal Transition':
        return ['Plan crop rotation', 'Adjust management', 'Monitor timing'];
      default:
        return ['Adapt management practices'];
    }
  }

  String _getRecommendationTitle(String type) {
    switch (type) {
      case 'Irrigation Management':
        return 'Optimize Irrigation Schedule';
      case 'Pest Control':
        return 'Pest Monitoring Alert';
      case 'Fertilizer Application':
        return 'Fertilizer Timing Recommendation';
      case 'Harvest Timing':
        return 'Optimal Harvest Window';
      case 'Crop Protection':
        return 'Crop Protection Measures';
      case 'Soil Management':
        return 'Soil Health Improvement';
      default:
        return 'Agricultural Recommendation';
    }
  }

  String _getRecommendationDescription(String type, String cropType) {
    switch (type) {
      case 'Irrigation Management':
        return 'Based on current weather patterns, adjust your irrigation schedule to optimize water usage for $cropType.';
      case 'Pest Control':
        return 'Current conditions favor pest development. Implement monitoring and control measures for $cropType.';
      case 'Fertilizer Application':
        return 'Optimal timing for fertilizer application based on soil conditions and weather forecast for $cropType.';
      case 'Harvest Timing':
        return 'Weather conditions suggest optimal harvest window approaching for $cropType.';
      case 'Crop Protection':
        return 'Implement protective measures to safeguard $cropType from adverse weather conditions.';
      case 'Soil Management':
        return 'Improve soil health and structure to enhance $cropType productivity.';
      default:
        return 'General recommendation for $cropType management.';
    }
  }

  String _getRecommendationPriority(String type, Random random) {
    final priorities = ['high', 'medium', 'low'];
    return priorities[random.nextInt(priorities.length)];
  }

  List<String> _getRecommendationActions(String type) {
    switch (type) {
      case 'Irrigation Management':
        return ['Check soil moisture', 'Adjust irrigation schedule', 'Monitor water usage'];
      case 'Pest Control':
        return ['Scout for pests', 'Apply control measures', 'Monitor effectiveness'];
      case 'Fertilizer Application':
        return ['Test soil nutrients', 'Calculate application rates', 'Apply fertilizer'];
      case 'Harvest Timing':
        return ['Monitor crop maturity', 'Check weather forecast', 'Prepare harvest equipment'];
      case 'Crop Protection':
        return ['Install protective structures', 'Apply protective treatments', 'Monitor conditions'];
      case 'Soil Management':
        return ['Test soil health', 'Apply amendments', 'Improve drainage'];
      default:
        return ['Implement recommendation', 'Monitor results'];
    }
  }

  Map<String, dynamic> _getRecommendationConditions(String type) {
    switch (type) {
      case 'Irrigation Management':
        return {'soil_moisture': '< 50%', 'temperature': '> 25°C'};
      case 'Pest Control':
        return {'humidity': '> 70%', 'temperature': '20-30°C'};
      case 'Fertilizer Application':
        return {'soil_temperature': '> 10°C', 'moisture': 'adequate'};
      case 'Harvest Timing':
        return {'maturity': '> 80%', 'weather': 'dry conditions'};
      case 'Crop Protection':
        return {'weather_risk': 'high', 'crop_stage': 'vulnerable'};
      case 'Soil Management':
        return {'soil_health': 'declining', 'season': 'appropriate'};
      default:
        return {'condition': 'met'};
    }
  }
}
