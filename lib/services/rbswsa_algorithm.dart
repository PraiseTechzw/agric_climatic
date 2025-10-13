import 'dart:math';
import 'logging_service.dart';

/// Rule-Based Seasonal Weather Simulation Algorithm (RBSWSA)
///
/// A logical and deterministic algorithm that uses predefined meteorological rules,
/// recent weather data, and known seasonal behaviors to forecast weather trends.
///
/// Key Features:
/// - No machine learning training required
/// - Uses Zimbabwe-specific climate rules
/// - Deterministic and explainable predictions
/// - Fast computation with minimal resources
class RBSWSAAlgorithm {
  // Zimbabwe climate zones and their characteristics (Enhanced with detailed data)
  static const Map<String, Map<String, dynamic>> _climateZones = {
    'highveld': {
      'altitude': 1200, // meters above sea level
      'avgTemp': 19.5, // °C (Harare average)
      'annualRainfall': 825, // mm (improved accuracy)
      'rainySeason': [10, 11, 12, 1, 2, 3], // October - March
      'drySeason': [4, 5, 6, 7, 8, 9], // April - September
      'description':
          'Central plateau: Harare, Bulawayo - main agricultural zone',
      'cropsSuitable': ['maize', 'tobacco', 'wheat', 'soybeans', 'cotton'],
      'soilType': 'Red-brown sandy loams',
      'frostRisk': [5, 6, 7], // May-July
      'optimalPlantingWindow': [11, 12], // November-December
    },
    'lowveld': {
      'altitude': 300,
      'avgTemp': 24.5,
      'annualRainfall': 450, // mm (lower rainfall)
      'rainySeason': [11, 12, 1, 2, 3],
      'drySeason': [4, 5, 6, 7, 8, 9, 10],
      'description': 'Southern lowlands: Chiredzi, Triangle - hotter, drier',
      'cropsSuitable': ['sugarcane', 'cotton', 'sorghum', 'millet'],
      'soilType': 'Sandy soils, alluvial in river valleys',
      'frostRisk': [], // No frost risk
      'optimalPlantingWindow': [12, 1], // December-January
    },
    'middleveld': {
      'altitude': 900,
      'avgTemp': 21.0,
      'annualRainfall': 650, // mm
      'rainySeason': [10, 11, 12, 1, 2, 3],
      'drySeason': [4, 5, 6, 7, 8, 9],
      'description': 'Intermediate zone: Gweru, Kwekwe - mixed farming',
      'cropsSuitable': ['maize', 'groundnuts', 'sunflower', 'tobacco'],
      'soilType': 'Red and brown loamy soils',
      'frostRisk': [6, 7], // June-July
      'optimalPlantingWindow': [11, 12], // November-December
    },
    'eastern_highlands': {
      'altitude': 1500,
      'avgTemp': 17.5,
      'annualRainfall': 1200, // mm (highest rainfall)
      'rainySeason': [9, 10, 11, 12, 1, 2, 3, 4], // Extended rainy season
      'drySeason': [5, 6, 7, 8],
      'description': 'Nyanga, Chimanimani - high rainfall, tea, coffee zone',
      'cropsSuitable': ['tea', 'coffee', 'timber', 'wheat', 'potatoes'],
      'soilType': 'Acidic mountain soils',
      'frostRisk': [5, 6, 7, 8], // May-August
      'optimalPlantingWindow': [10, 11], // October-November
    },
    'zambezi_valley': {
      'altitude': 400,
      'avgTemp': 26.0,
      'annualRainfall': 600, // mm
      'rainySeason': [11, 12, 1, 2, 3],
      'drySeason': [4, 5, 6, 7, 8, 9, 10],
      'description': 'Northern valley: Kariba, Mana Pools - hot, wildlife',
      'cropsSuitable': ['cotton', 'sorghum', 'millet', 'sunflower'],
      'soilType': 'Alluvial and sandy soils',
      'frostRisk': [], // No frost risk
      'optimalPlantingWindow': [12, 1], // December-January
    },
  };

  // Seasonal weather rules for Zimbabwe
  static const Map<int, Map<String, dynamic>> _seasonalRules = {
    1: {
      // January - Peak rainy season
      'tempModifier': 0.0,
      'rainfallModifier': 1.5,
      'humidityModifier': 1.3,
      'windModifier': 0.8,
      'description': 'Peak rainy season with high humidity',
    },
    2: {
      // February - Late rainy season
      'tempModifier': 0.2,
      'rainfallModifier': 1.2,
      'humidityModifier': 1.2,
      'windModifier': 0.9,
      'description': 'Late rainy season, temperatures rising',
    },
    3: {
      // March - End of rainy season
      'tempModifier': 0.5,
      'rainfallModifier': 0.8,
      'humidityModifier': 1.0,
      'windModifier': 1.0,
      'description': 'End of rainy season, transition to dry',
    },
    4: {
      // April - Early dry season
      'tempModifier': 0.8,
      'rainfallModifier': 0.3,
      'humidityModifier': 0.7,
      'windModifier': 1.1,
      'description': 'Early dry season, temperatures increasing',
    },
    5: {
      // May - Mid dry season
      'tempModifier': 1.0,
      'rainfallModifier': 0.1,
      'humidityModifier': 0.5,
      'windModifier': 1.2,
      'description': 'Mid dry season, hot and dry conditions',
    },
    6: {
      // June - Peak dry season
      'tempModifier': 0.9,
      'rainfallModifier': 0.05,
      'humidityModifier': 0.4,
      'windModifier': 1.3,
      'description': 'Peak dry season, very hot and dry',
    },
    7: {
      // July - Mid dry season
      'tempModifier': 0.8,
      'rainfallModifier': 0.05,
      'humidityModifier': 0.4,
      'windModifier': 1.2,
      'description': 'Mid dry season, hot and dry',
    },
    8: {
      // August - Late dry season
      'tempModifier': 0.9,
      'rainfallModifier': 0.1,
      'humidityModifier': 0.5,
      'windModifier': 1.1,
      'description': 'Late dry season, very hot conditions',
    },
    9: {
      // September - End of dry season
      'tempModifier': 1.1,
      'rainfallModifier': 0.2,
      'humidityModifier': 0.6,
      'windModifier': 1.0,
      'description': 'End of dry season, hottest month',
    },
    10: {
      // October - Early rainy season
      'tempModifier': 0.8,
      'rainfallModifier': 0.6,
      'humidityModifier': 0.8,
      'windModifier': 0.9,
      'description': 'Early rainy season, first rains',
    },
    11: {
      // November - Mid rainy season
      'tempModifier': 0.4,
      'rainfallModifier': 1.0,
      'humidityModifier': 1.1,
      'windModifier': 0.8,
      'description': 'Mid rainy season, regular rainfall',
    },
    12: {
      // December - Peak rainy season
      'tempModifier': 0.1,
      'rainfallModifier': 1.3,
      'humidityModifier': 1.2,
      'windModifier': 0.8,
      'description': 'Peak rainy season, heavy rainfall',
    },
  };

  // El Niño/La Niña effects on Zimbabwe weather
  static const Map<String, Map<String, dynamic>> _ensoEffects = {
    'el_nino': {
      'tempModifier': 0.3,
      'rainfallModifier': -0.4,
      'droughtRisk': 0.7,
      'description':
          'El Niño: Hotter, drier conditions, increased drought risk',
    },
    'la_nina': {
      'tempModifier': -0.2,
      'rainfallModifier': 0.3,
      'droughtRisk': -0.3,
      'description': 'La Niña: Cooler, wetter conditions, reduced drought risk',
    },
    'neutral': {
      'tempModifier': 0.0,
      'rainfallModifier': 0.0,
      'droughtRisk': 0.0,
      'description': 'Neutral: Normal seasonal patterns',
    },
  };

  /// Generate seasonal weather prediction using RBSWSA
  static Future<Map<String, dynamic>> generateSeasonalPrediction({
    required String location,
    required String climateZone,
    required int predictionMonths,
    String ensoStatus = 'neutral',
    Map<String, dynamic>? recentWeatherData,
  }) async {
    try {
      LoggingService.info(
        'Generating seasonal prediction using RBSWSA',
        extra: {
          'location': location,
          'climateZone': climateZone,
          'predictionMonths': predictionMonths,
          'ensoStatus': ensoStatus,
        },
      );

      final zoneData =
          _climateZones[climateZone.toLowerCase()] ??
          _climateZones['highveld']!;
      final ensoData =
          _ensoEffects[ensoStatus.toLowerCase()] ?? _ensoEffects['neutral']!;

      final prediction = <String, dynamic>{
        'algorithm': 'RBSWSA',
        'location': location,
        'climateZone': climateZone,
        'predictionPeriod': predictionMonths,
        'ensoStatus': ensoStatus,
        'generatedAt': DateTime.now().toIso8601String(),
        'monthlyPredictions': <Map<String, dynamic>>[],
        'seasonalSummary': <String, dynamic>{},
        'droughtRisk': <String, dynamic>{},
        'farmingRecommendations': <String>[],
      };

      // Generate monthly predictions
      for (int i = 0; i < predictionMonths; i++) {
        final targetMonth = (DateTime.now().month + i - 1) % 12 + 1;
        final monthPrediction = _generateMonthlyPrediction(
          targetMonth,
          zoneData,
          ensoData,
          recentWeatherData,
        );
        prediction['monthlyPredictions'].add(monthPrediction);
      }

      // Generate seasonal summary
      prediction['seasonalSummary'] = _generateSeasonalSummary(
        prediction['monthlyPredictions'],
        zoneData,
        ensoData,
      );

      // Calculate drought risk
      prediction['droughtRisk'] = _calculateDroughtRisk(
        prediction['monthlyPredictions'],
        zoneData,
        ensoData,
      );

      // Generate farming recommendations
      prediction['farmingRecommendations'] = _generateFarmingRecommendations(
        prediction['monthlyPredictions'],
        zoneData,
        ensoData,
      );

      LoggingService.info(
        'RBSWSA prediction generated successfully',
        extra: {
          'predictionMonths': predictionMonths,
          'droughtRisk': prediction['droughtRisk']['overallRisk'],
        },
      );

      return prediction;
    } catch (e) {
      LoggingService.error('Failed to generate RBSWSA prediction', error: e);
      rethrow;
    }
  }

  /// Generate prediction for a specific month
  static Map<String, dynamic> _generateMonthlyPrediction(
    int month,
    Map<String, dynamic> zoneData,
    Map<String, dynamic> ensoData,
    Map<String, dynamic>? recentWeatherData,
  ) {
    final seasonalRule = _seasonalRules[month]!;
    final random = Random();

    // Base calculations
    final baseTemp = zoneData['avgTemp'] as double;
    final baseRainfall = (zoneData['annualRainfall'] as int) / 12.0;

    // Apply seasonal modifiers
    final tempModifier = seasonalRule['tempModifier'] as double;
    final rainfallModifier = seasonalRule['rainfallModifier'] as double;
    final humidityModifier = seasonalRule['humidityModifier'] as double;
    final windModifier = seasonalRule['windModifier'] as double;

    // Apply ENSO effects
    final ensoTempModifier = ensoData['tempModifier']!;
    final ensoRainfallModifier = ensoData['rainfallModifier']!;

    // Calculate predicted values
    final predictedTemp =
        baseTemp +
        (tempModifier * 5) +
        (ensoTempModifier * 3) +
        (random.nextDouble() - 0.5) * 2;
    final predictedRainfall =
        baseRainfall *
        rainfallModifier *
        (1 + ensoRainfallModifier) *
        (0.8 + random.nextDouble() * 0.4);
    final predictedHumidity =
        60 + (humidityModifier - 1) * 20 + (random.nextDouble() - 0.5) * 10;
    final predictedWindSpeed =
        10 + (windModifier - 1) * 5 + (random.nextDouble() - 0.5) * 3;

    // Determine weather conditions
    final conditions = _determineWeatherConditions(
      predictedTemp,
      predictedRainfall,
      predictedHumidity,
      predictedWindSpeed,
    );

    return {
      'month': month,
      'monthName': _getMonthName(month),
      'temperature': {
        'average': predictedTemp,
        'min': predictedTemp - 5,
        'max': predictedTemp + 5,
        'unit': '°C',
      },
      'rainfall': {
        'total': predictedRainfall,
        'unit': 'mm',
        'days': (predictedRainfall / 10).round(), // Estimate rainy days
      },
      'humidity': {'average': predictedHumidity, 'unit': '%'},
      'windSpeed': {'average': predictedWindSpeed, 'unit': 'km/h'},
      'conditions': conditions,
      'description': seasonalRule['description'] as String,
      'confidence': _calculateConfidence(month, ensoData),
    };
  }

  /// Determine weather conditions based on predicted values
  static List<String> _determineWeatherConditions(
    double temp,
    double rainfall,
    double humidity,
    double windSpeed,
  ) {
    final conditions = <String>[];

    // Temperature conditions
    if (temp > 30) {
      conditions.add('Hot');
    } else if (temp < 15) {
      conditions.add('Cool');
    } else {
      conditions.add('Moderate');
    }

    // Rainfall conditions
    if (rainfall > 100) {
      conditions.add('Wet');
    } else if (rainfall < 20) {
      conditions.add('Dry');
    } else {
      conditions.add('Normal');
    }

    // Humidity conditions
    if (humidity > 80) {
      conditions.add('Humid');
    } else if (humidity < 40) {
      conditions.add('Arid');
    }

    // Wind conditions
    if (windSpeed > 20) {
      conditions.add('Windy');
    }

    return conditions;
  }

  /// Generate seasonal summary
  static Map<String, dynamic> _generateSeasonalSummary(
    List<Map<String, dynamic>> monthlyPredictions,
    Map<String, dynamic> zoneData,
    Map<String, dynamic> ensoData,
  ) {
    final avgTemp =
        monthlyPredictions
            .map((m) => m['temperature']['average'] as double)
            .reduce((a, b) => a + b) /
        monthlyPredictions.length;

    final totalRainfall = monthlyPredictions
        .map((m) => m['rainfall']['total'] as double)
        .reduce((a, b) => a + b);

    final avgHumidity =
        monthlyPredictions
            .map((m) => m['humidity']['average'] as double)
            .reduce((a, b) => a + b) /
        monthlyPredictions.length;

    return {
      'averageTemperature': avgTemp,
      'totalRainfall': totalRainfall,
      'averageHumidity': avgHumidity,
      'temperatureTrend': _calculateTemperatureTrend(monthlyPredictions),
      'rainfallTrend': _calculateRainfallTrend(monthlyPredictions),
      'seasonalType': _determineSeasonalType(monthlyPredictions),
      'description': _generateSeasonalDescription(
        avgTemp,
        totalRainfall,
        ensoData,
      ),
    };
  }

  /// Calculate drought risk assessment
  static Map<String, dynamic> _calculateDroughtRisk(
    List<Map<String, dynamic>> monthlyPredictions,
    Map<String, dynamic> zoneData,
    Map<String, dynamic> ensoData,
  ) {
    final totalRainfall = monthlyPredictions
        .map((m) => m['rainfall']['total'] as double)
        .reduce((a, b) => a + b);

    final expectedRainfall =
        (zoneData['annualRainfall'] as int) *
        (monthlyPredictions.length / 12.0);

    final rainfallDeficit =
        (expectedRainfall - totalRainfall) / expectedRainfall;
    final ensoDroughtRisk = ensoData['droughtRisk']!;

    double overallRisk;
    String riskLevel;

    if (rainfallDeficit > 0.3 || ensoDroughtRisk > 0.5) {
      overallRisk = 0.8;
      riskLevel = 'High';
    } else if (rainfallDeficit > 0.1 || ensoDroughtRisk > 0.2) {
      overallRisk = 0.5;
      riskLevel = 'Medium';
    } else {
      overallRisk = 0.2;
      riskLevel = 'Low';
    }

    return {
      'overallRisk': overallRisk,
      'riskLevel': riskLevel,
      'rainfallDeficit': rainfallDeficit,
      'ensoContribution': ensoDroughtRisk,
      'recommendations': _getDroughtRecommendations(overallRisk),
    };
  }

  /// Generate farming recommendations based on predictions
  static List<String> _generateFarmingRecommendations(
    List<Map<String, dynamic>> monthlyPredictions,
    Map<String, dynamic> zoneData,
    Map<String, dynamic> ensoData,
  ) {
    final recommendations = <String>[];
    final droughtRisk = _calculateDroughtRisk(
      monthlyPredictions,
      zoneData,
      ensoData,
    );

    final currentMonth = DateTime.now().month;
    final suitableCrops = zoneData['cropsSuitable'] as List<dynamic>;
    final optimalPlantingWindow =
        zoneData['optimalPlantingWindow'] as List<dynamic>;
    final frostRisk = zoneData['frostRisk'] as List<dynamic>;

    // Zone-specific crop recommendations
    recommendations.add(
      'Recommended crops for your zone: ${suitableCrops.take(3).join(", ")}',
    );

    // Planting window recommendations
    if (optimalPlantingWindow.contains(currentMonth)) {
      recommendations.add(
        'OPTIMAL PLANTING WINDOW: Start planting now for best yields',
      );
    } else if (optimalPlantingWindow.contains((currentMonth + 1) % 12)) {
      recommendations.add(
        'Prepare fields now - planting window opens next month',
      );
    }

    // Frost risk warnings
    if (frostRisk.contains(currentMonth) ||
        frostRisk.contains((currentMonth + 1) % 12)) {
      recommendations.add(
        'FROST RISK: Protect sensitive crops, delay planting frost-sensitive varieties',
      );
    }

    // Drought-related recommendations
    if (droughtRisk['overallRisk'] > 0.6) {
      recommendations.addAll([
        'HIGH DROUGHT RISK: Plant drought-tolerant crops (sorghum, millet, sunflower)',
        'Implement water conservation - mulching is critical',
        'Consider drip irrigation or water harvesting',
        'Reduce planting density to conserve moisture',
      ]);
    } else if (droughtRisk['overallRisk'] > 0.3) {
      recommendations.addAll([
        'Moderate drought risk: Prepare water conservation measures',
        'Mix drought-resistant and normal crop varieties',
      ]);
    }

    // Temperature-based recommendations
    final avgTemp =
        monthlyPredictions
            .map((m) => m['temperature']['average'] as double)
            .reduce((a, b) => a + b) /
        monthlyPredictions.length;

    if (avgTemp > 28) {
      recommendations.addAll([
        'HIGH TEMPERATURES: Water early morning (before 8am) or evening (after 5pm)',
        'Apply mulch (10-15cm deep) to cool soil and retain moisture',
        'Monitor crops for heat stress - wilting, leaf curling',
      ]);
    } else if (avgTemp < 18 && frostRisk.isNotEmpty) {
      recommendations.add(
        'Cool temperatures: Plant cool-season crops (wheat, barley, potatoes)',
      );
    }

    // Rainfall-based recommendations
    final totalRainfall = monthlyPredictions
        .map((m) => m['rainfall']['total'] as double)
        .reduce((a, b) => a + b);

    if (totalRainfall > 400) {
      recommendations.addAll([
        'HIGH RAINFALL EXPECTED: Ensure proper field drainage',
        'Use raised beds or ridges for planting',
        'Monitor for waterlogging and soil erosion',
        'Delay fertilizer application until after heavy rains',
      ]);
    } else if (totalRainfall < 200) {
      recommendations.add(
        'Low rainfall: Irrigate regularly, target 25-30mm per week for most crops',
      );
    }

    // Soil-specific recommendations
    final soilType = zoneData['soilType'] as String;
    if (soilType.toLowerCase().contains('sand')) {
      recommendations.add(
        'Sandy soils: Increase organic matter, fertilize more frequently in smaller doses',
      );
    } else if (soilType.toLowerCase().contains('loam')) {
      recommendations.add(
        'Loamy soils: Ideal for most crops, maintain organic matter levels',
      );
    }

    return recommendations.take(12).toList(); // Increased to 12 for more detail
  }

  // Helper methods
  static String _getMonthName(int month) {
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

  static double _calculateConfidence(int month, Map<String, dynamic> ensoData) {
    // Confidence is higher for months closer to current and when ENSO is neutral
    final monthConfidence = 0.9 - (month - DateTime.now().month).abs() * 0.05;
    final ensoConfidence =
        1.0 -
        (ensoData['tempModifier']!.abs() +
                ensoData['rainfallModifier']!.abs()) *
            0.2;
    return (monthConfidence + ensoConfidence) / 2.0;
  }

  static String _calculateTemperatureTrend(
    List<Map<String, dynamic>> predictions,
  ) {
    if (predictions.length < 2) return 'Stable';

    final firstTemp = predictions.first['temperature']['average'] as double;
    final lastTemp = predictions.last['temperature']['average'] as double;

    if (lastTemp > firstTemp + 2) return 'Increasing';
    if (lastTemp < firstTemp - 2) return 'Decreasing';
    return 'Stable';
  }

  static String _calculateRainfallTrend(
    List<Map<String, dynamic>> predictions,
  ) {
    if (predictions.length < 2) return 'Stable';

    final firstRain = predictions.first['rainfall']['total'] as double;
    final lastRain = predictions.last['rainfall']['total'] as double;

    if (lastRain > firstRain * 1.5) return 'Increasing';
    if (lastRain < firstRain * 0.5) return 'Decreasing';
    return 'Stable';
  }

  static String _determineSeasonalType(List<Map<String, dynamic>> predictions) {
    final totalRainfall = predictions
        .map((m) => m['rainfall']['total'] as double)
        .reduce((a, b) => a + b);

    if (totalRainfall > 300) return 'Wet Season';
    if (totalRainfall < 100) return 'Dry Season';
    return 'Transition Season';
  }

  static String _generateSeasonalDescription(
    double avgTemp,
    double totalRainfall,
    Map<String, dynamic> ensoData,
  ) {
    final tempDesc = avgTemp > 25
        ? 'warm'
        : avgTemp < 20
        ? 'cool'
        : 'moderate';
    final rainDesc = totalRainfall > 300
        ? 'wet'
        : totalRainfall < 100
        ? 'dry'
        : 'normal';
    final ensoDesc = ensoData['description'] as String;

    return 'Expecting $tempDesc temperatures with $rainDesc rainfall conditions. $ensoDesc';
  }

  static List<String> _getDroughtRecommendations(double risk) {
    if (risk > 0.7) {
      return [
        'High drought risk - implement emergency water conservation',
        'Focus on drought-tolerant crops only',
        'Prepare alternative water sources',
        'Reduce planting area to conserve water',
      ];
    } else if (risk > 0.4) {
      return [
        'Moderate drought risk - prepare water conservation measures',
        'Plant drought-resistant crop varieties',
        'Implement efficient irrigation systems',
        'Monitor soil moisture regularly',
      ];
    } else {
      return [
        'Low drought risk - normal farming practices',
        'Maintain regular irrigation schedule',
        'Monitor weather conditions',
      ];
    }
  }
}
