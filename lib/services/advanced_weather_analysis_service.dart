import 'dart:math';
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/dashboard_data.dart';
import 'logging_service.dart';

class AdvancedWeatherAnalysisService {
  final Random _random = Random();

  // Comprehensive weather analysis
  Future<WeatherAnalysisReport> generateComprehensiveAnalysis({
    required String location,
    required List<Weather> weatherData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (weatherData.isEmpty) {
        return WeatherAnalysisReport.empty(location, startDate, endDate);
      }

      // Basic statistics
      final basicStats = _calculateBasicStatistics(weatherData);

      // Seasonal analysis
      final seasonalAnalysis = _analyzeSeasonalPatterns(weatherData);

      // Trend analysis
      final trendAnalysis = _analyzeTrends(weatherData);

      // Anomaly detection
      final anomalies = _detectAdvancedAnomalies(weatherData);

      // Climate indicators
      final climateIndicators = _calculateClimateIndicators(weatherData);

      // Agricultural impact analysis
      final agriculturalImpact = _analyzeAgriculturalImpact(
        weatherData,
        location,
      );

      // Risk assessment
      final riskAssessment = _assessClimateRisks(weatherData, location);

      // Recommendations
      final recommendations = _generateRecommendations(
        basicStats,
        seasonalAnalysis,
        trendAnalysis,
        agriculturalImpact,
        riskAssessment,
        location,
      );

      return WeatherAnalysisReport(
        location: location,
        startDate: startDate,
        endDate: endDate,
        dataPoints: weatherData.length,
        basicStatistics: basicStats,
        seasonalAnalysis: seasonalAnalysis,
        trendAnalysis: trendAnalysis,
        anomalies: anomalies,
        climateIndicators: climateIndicators,
        agriculturalImpact: agriculturalImpact,
        riskAssessment: riskAssessment,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error(
        'Failed to generate comprehensive analysis',
        error: e,
      );
      return WeatherAnalysisReport.empty(location, startDate, endDate);
    }
  }

  // Calculate basic weather statistics
  Map<String, dynamic> _calculateBasicStatistics(List<Weather> data) {
    if (data.isEmpty) return {};

    final temperatures = data.map((w) => w.temperature).toList();
    final humidities = data.map((w) => w.humidity).toList();
    final precipitations = data.map((w) => w.precipitation).toList();
    final windSpeeds = data.map((w) => w.windSpeed).toList();
    final pressures = data.map((w) => w.pressure).toList();

    return {
      'temperature': {
        'mean': _calculateMean(temperatures),
        'median': _calculateMedian(temperatures),
        'min': temperatures.reduce((a, b) => a < b ? a : b),
        'max': temperatures.reduce((a, b) => a > b ? a : b),
        'stdDev': _calculateStandardDeviation(temperatures),
        'range':
            temperatures.reduce((a, b) => a > b ? a : b) -
            temperatures.reduce((a, b) => a < b ? a : b),
      },
      'humidity': {
        'mean': _calculateMean(humidities),
        'median': _calculateMedian(humidities),
        'min': humidities.reduce((a, b) => a < b ? a : b),
        'max': humidities.reduce((a, b) => a > b ? a : b),
        'stdDev': _calculateStandardDeviation(humidities),
      },
      'precipitation': {
        'total': precipitations.reduce((a, b) => a + b),
        'mean': _calculateMean(precipitations),
        'max': precipitations.reduce((a, b) => a > b ? a : b),
        'rainyDays': data.where((w) => w.precipitation > 0).length,
        'dryDays': data.where((w) => w.precipitation == 0).length,
      },
      'wind': {
        'mean': _calculateMean(windSpeeds),
        'max': windSpeeds.reduce((a, b) => a > b ? a : b),
        'stdDev': _calculateStandardDeviation(windSpeeds),
      },
      'pressure': {
        'mean': _calculateMean(pressures),
        'min': pressures.reduce((a, b) => a < b ? a : b),
        'max': pressures.reduce((a, b) => a > b ? a : b),
        'stdDev': _calculateStandardDeviation(pressures),
      },
    };
  }

  // Analyze seasonal patterns
  Map<String, dynamic> _analyzeSeasonalPatterns(List<Weather> data) {
    final seasonalData = <String, List<Weather>>{};

    // Group by season
    for (final weather in data) {
      final season = _getSeason(weather.dateTime.month);
      seasonalData[season] ??= [];
      seasonalData[season]!.add(weather);
    }

    final analysis = <String, dynamic>{};

    for (final entry in seasonalData.entries) {
      final season = entry.key;
      final seasonData = entry.value;

      if (seasonData.isNotEmpty) {
        final temps = seasonData.map((w) => w.temperature).toList();
        final precipitations = seasonData.map((w) => w.precipitation).toList();
        final humidities = seasonData.map((w) => w.humidity).toList();

        analysis[season] = {
          'avgTemperature': _calculateMean(temps),
          'totalPrecipitation': precipitations.reduce((a, b) => a + b),
          'avgHumidity': _calculateMean(humidities),
          'rainyDays': seasonData.where((w) => w.precipitation > 0).length,
          'dataPoints': seasonData.length,
        };
      }
    }

    return analysis;
  }

  // Analyze trends over time
  Map<String, dynamic> _analyzeTrends(List<Weather> data) {
    if (data.length < 2) return {};

    // Sort by date
    final sortedData = List<Weather>.from(data)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final temperatures = sortedData.map((w) => w.temperature).toList();
    final precipitations = sortedData.map((w) => w.precipitation).toList();
    final humidities = sortedData.map((w) => w.humidity).toList();
    final windSpeeds = sortedData.map((w) => w.windSpeed).toList();

    return {
      'temperature': {
        'trend': _calculateLinearTrend(temperatures),
        'correlation': _calculateCorrelation(temperatures),
        'volatility': _calculateVolatility(temperatures),
      },
      'precipitation': {
        'trend': _calculateLinearTrend(precipitations),
        'correlation': _calculateCorrelation(precipitations),
        'volatility': _calculateVolatility(precipitations),
      },
      'humidity': {
        'trend': _calculateLinearTrend(humidities),
        'correlation': _calculateCorrelation(humidities),
        'volatility': _calculateVolatility(humidities),
      },
      'wind': {
        'trend': _calculateLinearTrend(windSpeeds),
        'correlation': _calculateCorrelation(windSpeeds),
        'volatility': _calculateVolatility(windSpeeds),
      },
    };
  }

  // Detect advanced anomalies
  List<WeatherAnomaly> _detectAdvancedAnomalies(List<Weather> data) {
    final anomalies = <WeatherAnomaly>[];
    if (data.isEmpty) return anomalies;

    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();
    final humidities = data.map((w) => w.humidity).toList();

    final tempMean = _calculateMean(temperatures);
    final tempStdDev = _calculateStandardDeviation(temperatures);
    final precipMean = _calculateMean(precipitations);
    final precipStdDev = _calculateStandardDeviation(precipitations);

    // Temperature anomalies
    for (int i = 0; i < data.length; i++) {
      final weather = data[i];
      final tempZScore = (weather.temperature - tempMean) / tempStdDev;

      if (tempZScore.abs() > 2.5) {
        anomalies.add(
          WeatherAnomaly(
            id: 'temp_${weather.id}',
            type: 'temperature',
            severity: tempZScore.abs() > 3.0 ? 'high' : 'medium',
            description: tempZScore > 0
                ? 'Unusually high temperature'
                : 'Unusually low temperature',
            value: weather.temperature,
            expectedValue: tempMean,
            deviation: tempZScore,
            date: weather.dateTime,
            impact: _assessAnomalyImpact('temperature', tempZScore),
          ),
        );
      }
    }

    // Precipitation anomalies
    for (int i = 0; i < data.length; i++) {
      final weather = data[i];
      if (weather.precipitation > precipMean + (2 * precipStdDev)) {
        anomalies.add(
          WeatherAnomaly(
            id: 'precip_${weather.id}',
            type: 'precipitation',
            severity: weather.precipitation > precipMean + (3 * precipStdDev)
                ? 'high'
                : 'medium',
            description: 'Extreme rainfall event',
            value: weather.precipitation,
            expectedValue: precipMean,
            deviation: (weather.precipitation - precipMean) / precipStdDev,
            date: weather.dateTime,
            impact: _assessAnomalyImpact(
              'precipitation',
              (weather.precipitation - precipMean) / precipStdDev,
            ),
          ),
        );
      }
    }

    return anomalies;
  }

  // Calculate climate indicators
  Map<String, dynamic> _calculateClimateIndicators(List<Weather> data) {
    if (data.isEmpty) return {};

    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();
    final humidities = data.map((w) => w.humidity).toList();

    // Climate classification
    final avgTemp = _calculateMean(temperatures);
    final totalPrecip = precipitations.reduce((a, b) => a + b);
    final avgHumidity = _calculateMean(humidities);

    String climateType = 'temperate';
    if (avgTemp > 25) {
      climateType = avgHumidity > 70 ? 'tropical' : 'arid';
    } else if (avgTemp < 10) {
      climateType = 'cold';
    }

    // Drought index
    final droughtIndex = _calculateDroughtIndex(data);

    // Heat stress index
    final heatStressIndex = _calculateHeatStressIndex(data);

    // Comfort index
    final comfortIndex = _calculateComfortIndex(data);

    return {
      'climateType': climateType,
      'droughtIndex': droughtIndex,
      'heatStressIndex': heatStressIndex,
      'comfortIndex': comfortIndex,
      'variabilityIndex': _calculateVariabilityIndex(temperatures),
      'extremesIndex': _calculateExtremesIndex(data),
    };
  }

  // Analyze agricultural impact
  Map<String, dynamic> _analyzeAgriculturalImpact(
    List<Weather> data,
    String location,
  ) {
    if (data.isEmpty) return {};

    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();
    final humidities = data.map((w) => w.humidity).toList();

    // Growing season analysis
    final growingSeason = _analyzeGrowingSeason(data);

    // Water stress analysis
    final waterStress = _analyzeWaterStress(data);

    // Pest and disease risk
    final pestDiseaseRisk = _analyzePestDiseaseRisk(data);

    // Crop suitability
    final cropSuitability = _analyzeCropSuitability(data, location);

    return {
      'growingSeason': growingSeason,
      'waterStress': waterStress,
      'pestDiseaseRisk': pestDiseaseRisk,
      'cropSuitability': cropSuitability,
      'yieldPotential': _calculateYieldPotential(data),
      'plantingWindows': _identifyPlantingWindows(data),
    };
  }

  // Assess climate risks
  Map<String, dynamic> _assessClimateRisks(
    List<Weather> data,
    String location,
  ) {
    final risks = <String, dynamic>{};

    // Drought risk
    risks['drought'] = _assessDroughtRisk(data);

    // Flood risk
    risks['flood'] = _assessFloodRisk(data);

    // Heat wave risk
    risks['heatWave'] = _assessHeatWaveRisk(data);

    // Frost risk
    risks['frost'] = _assessFrostRisk(data);

    // Wind damage risk
    risks['windDamage'] = _assessWindDamageRisk(data);

    return risks;
  }

  // Generate recommendations
  List<WeatherRecommendation> _generateRecommendations(
    Map<String, dynamic> basicStats,
    Map<String, dynamic> seasonalAnalysis,
    Map<String, dynamic> trendAnalysis,
    Map<String, dynamic> agriculturalImpact,
    Map<String, dynamic> riskAssessment,
    String location,
  ) {
    final recommendations = <WeatherRecommendation>[];

    // Temperature-based recommendations
    final tempStats = basicStats['temperature'] as Map<String, dynamic>?;
    if (tempStats != null) {
      final avgTemp = tempStats['mean'] as double;
      if (avgTemp > 28) {
        recommendations.add(
          WeatherRecommendation(
            id: 'temp_high_${DateTime.now().millisecondsSinceEpoch}',
            category: 'temperature',
            priority: 'high',
            title: 'High Temperature Management',
            description:
                'Average temperatures are above optimal for most crops. Consider heat-tolerant varieties and irrigation.',
            actions: [
              'Plant heat-tolerant crop varieties',
              'Increase irrigation frequency',
              'Use mulching to reduce soil temperature',
              'Consider shade structures for sensitive crops',
            ],
            impact: 'Prevents heat stress and maintains crop productivity',
          ),
        );
      }
    }

    // Precipitation-based recommendations
    final precipStats = basicStats['precipitation'] as Map<String, dynamic>?;
    if (precipStats != null) {
      final totalPrecip = precipStats['total'] as double;
      final rainyDays = precipStats['rainyDays'] as int;

      if (totalPrecip < 500) {
        recommendations.add(
          WeatherRecommendation(
            id: 'precip_low_${DateTime.now().millisecondsSinceEpoch}',
            category: 'water',
            priority: 'high',
            title: 'Water Conservation Required',
            description:
                'Low precipitation levels detected. Implement water conservation strategies.',
            actions: [
              'Implement drip irrigation systems',
              'Use drought-resistant crop varieties',
              'Practice water harvesting techniques',
              'Monitor soil moisture levels closely',
            ],
            impact: 'Ensures water availability for crops during dry periods',
          ),
        );
      }
    }

    // Risk-based recommendations
    for (final entry in riskAssessment.entries) {
      final riskType = entry.key;
      final riskLevel = entry.value as String;

      if (riskLevel == 'high') {
        recommendations.add(
          WeatherRecommendation(
            id: 'risk_${riskType}_${DateTime.now().millisecondsSinceEpoch}',
            category: 'risk_management',
            priority: 'high',
            title: '${riskType.toUpperCase()} Risk Mitigation',
            description:
                'High risk of $riskType detected. Implement protective measures.',
            actions: _getRiskMitigationActions(riskType),
            impact: 'Reduces potential damage from weather extremes',
          ),
        );
      }
    }

    return recommendations;
  }

  // Helper methods
  String _getSeason(int month) {
    if (month >= 12 || month <= 2) return 'summer';
    if (month >= 3 && month <= 5) return 'autumn';
    if (month >= 6 && month <= 8) return 'winter';
    return 'spring';
  }

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = _calculateMean(values);
    final variance =
        values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());

    final sumX = x.reduce((a, b) => a + b);
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = x
        .asMap()
        .entries
        .map((e) => e.key * values[e.key])
        .reduce((a, b) => a + b);
    final sumXX = x.map((x) => x * x).reduce((a, b) => a + b);

    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  double _calculateCorrelation(List<double> values) {
    if (values.length < 2) return 0.0;

    final x = List.generate(values.length, (i) => i.toDouble());
    final y = values;

    final n = values.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x
        .asMap()
        .entries
        .map((e) => e.key * y[e.key])
        .reduce((a, b) => a + b);
    final sumXX = x.map((x) => x * x).reduce((a, b) => a + b);
    final sumYY = y.map((y) => y * y).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt(
      (n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY),
    );

    return denominator == 0 ? 0.0 : numerator / denominator;
  }

  double _calculateVolatility(List<double> values) {
    return _calculateStandardDeviation(values);
  }

  String _assessAnomalyImpact(String type, double deviation) {
    final absDeviation = deviation.abs();
    if (absDeviation > 3.0) return 'severe';
    if (absDeviation > 2.0) return 'moderate';
    return 'minor';
  }

  double _calculateDroughtIndex(List<Weather> data) {
    // Simplified drought index based on precipitation deficit
    final precipitations = data.map((w) => w.precipitation).toList();
    final avgPrecip = _calculateMean(precipitations);
    final expectedPrecip = 2.0; // mm per day average

    return max(0.0, (expectedPrecip - avgPrecip) / expectedPrecip);
  }

  double _calculateHeatStressIndex(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final humidities = data.map((w) => w.humidity).toList();

    double heatStress = 0.0;
    for (int i = 0; i < temperatures.length; i++) {
      final temp = temperatures[i];
      final humidity = humidities[i];

      // Heat index calculation
      final heatIndex = temp + (humidity * 0.1);
      if (heatIndex > 30) {
        heatStress += (heatIndex - 30) / 10;
      }
    }

    return heatStress / temperatures.length;
  }

  double _calculateComfortIndex(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final humidities = data.map((w) => w.humidity).toList();

    double comfort = 0.0;
    for (int i = 0; i < temperatures.length; i++) {
      final temp = temperatures[i];
      final humidity = humidities[i];

      // Comfort zone: 18-25°C, 40-70% humidity
      final tempComfort = 1.0 - ((temp - 21.5).abs() / 10.0);
      final humidityComfort = 1.0 - ((humidity - 55.0).abs() / 30.0);

      comfort += (tempComfort + humidityComfort) / 2;
    }

    return comfort / temperatures.length;
  }

  double _calculateVariabilityIndex(List<double> values) {
    return _calculateStandardDeviation(values) / _calculateMean(values);
  }

  double _calculateExtremesIndex(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();

    final tempMean = _calculateMean(temperatures);
    final tempStdDev = _calculateStandardDeviation(temperatures);
    final precipMean = _calculateMean(precipitations);
    final precipStdDev = _calculateStandardDeviation(precipitations);

    int extremes = 0;
    for (final weather in data) {
      final tempZScore = (weather.temperature - tempMean) / tempStdDev;
      final precipZScore = (weather.precipitation - precipMean) / precipStdDev;

      if (tempZScore.abs() > 2.0 || precipZScore.abs() > 2.0) {
        extremes++;
      }
    }

    return extremes / data.length;
  }

  Map<String, dynamic> _analyzeGrowingSeason(List<Weather> data) {
    // Simplified growing season analysis
    final temperatures = data.map((w) => w.temperature).toList();
    final avgTemp = _calculateMean(temperatures);

    return {
      'length': avgTemp > 15 ? 'long' : 'short',
      'quality': avgTemp > 20
          ? 'excellent'
          : avgTemp > 15
          ? 'good'
          : 'poor',
      'startDate': 'March',
      'endDate': 'November',
    };
  }

  Map<String, dynamic> _analyzeWaterStress(List<Weather> data) {
    final precipitations = data.map((w) => w.precipitation).toList();
    final totalPrecip = precipitations.reduce((a, b) => a + b);

    return {
      'level': totalPrecip < 500
          ? 'high'
          : totalPrecip < 800
          ? 'moderate'
          : 'low',
      'risk': totalPrecip < 500
          ? 'severe'
          : totalPrecip < 800
          ? 'moderate'
          : 'minimal',
    };
  }

  Map<String, dynamic> _analyzePestDiseaseRisk(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final humidities = data.map((w) => w.humidity).toList();

    final avgTemp = _calculateMean(temperatures);
    final avgHumidity = _calculateMean(humidities);

    String risk = 'low';
    if (avgTemp > 25 && avgHumidity > 70) {
      risk = 'high';
    } else if (avgTemp > 22 && avgHumidity > 60) {
      risk = 'moderate';
    }

    return {
      'level': risk,
      'factors': ['temperature', 'humidity'],
    };
  }

  Map<String, dynamic> _analyzeCropSuitability(
    List<Weather> data,
    String location,
  ) {
    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();

    final avgTemp = _calculateMean(temperatures);
    final totalPrecip = precipitations.reduce((a, b) => a + b);

    final suitableCrops = <String>[];

    if (avgTemp >= 18 && avgTemp <= 24 && totalPrecip >= 500) {
      suitableCrops.addAll(['maize', 'wheat', 'soybeans']);
    }
    if (avgTemp >= 20 && avgTemp <= 30 && totalPrecip >= 400) {
      suitableCrops.addAll(['sorghum', 'millet', 'groundnuts']);
    }
    if (avgTemp >= 22 && avgTemp <= 28 && totalPrecip >= 600) {
      suitableCrops.addAll(['cotton', 'tobacco']);
    }

    return {
      'suitableCrops': suitableCrops,
      'temperatureSuitability': avgTemp >= 18 && avgTemp <= 28
          ? 'good'
          : 'poor',
      'waterSuitability': totalPrecip >= 500 ? 'good' : 'poor',
    };
  }

  double _calculateYieldPotential(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final precipitations = data.map((w) => w.precipitation).toList();

    final avgTemp = _calculateMean(temperatures);
    final totalPrecip = precipitations.reduce((a, b) => a + b);

    double yieldPotential = 70.0; // Base yield percentage

    // Temperature impact
    if (avgTemp >= 18 && avgTemp <= 24) {
      yieldPotential += 20.0;
    } else if (avgTemp < 15 || avgTemp > 30) {
      yieldPotential -= 30.0;
    }

    // Precipitation impact
    if (totalPrecip >= 500 && totalPrecip <= 1000) {
      yieldPotential += 15.0;
    } else if (totalPrecip < 300) {
      yieldPotential -= 25.0;
    }

    return yieldPotential.clamp(0.0, 100.0);
  }

  List<String> _identifyPlantingWindows(List<Weather> data) {
    // Simplified planting window identification
    return ['March-April', 'September-October'];
  }

  String _assessDroughtRisk(List<Weather> data) {
    final precipitations = data.map((w) => w.precipitation).toList();
    final totalPrecip = precipitations.reduce((a, b) => a + b);

    if (totalPrecip < 400) return 'high';
    if (totalPrecip < 600) return 'moderate';
    return 'low';
  }

  String _assessFloodRisk(List<Weather> data) {
    final precipitations = data.map((w) => w.precipitation).toList();
    final maxPrecip = precipitations.reduce((a, b) => a > b ? a : b);

    if (maxPrecip > 50) return 'high';
    if (maxPrecip > 25) return 'moderate';
    return 'low';
  }

  String _assessHeatWaveRisk(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);

    if (maxTemp > 35) return 'high';
    if (maxTemp > 30) return 'moderate';
    return 'low';
  }

  String _assessFrostRisk(List<Weather> data) {
    final temperatures = data.map((w) => w.temperature).toList();
    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);

    if (minTemp < 0) return 'high';
    if (minTemp < 5) return 'moderate';
    return 'low';
  }

  String _assessWindDamageRisk(List<Weather> data) {
    final windSpeeds = data.map((w) => w.windSpeed).toList();
    final maxWind = windSpeeds.reduce((a, b) => a > b ? a : b);

    if (maxWind > 20) return 'high';
    if (maxWind > 15) return 'moderate';
    return 'low';
  }

  List<String> _getRiskMitigationActions(String riskType) {
    switch (riskType) {
      case 'drought':
        return [
          'Implement water harvesting systems',
          'Use drought-resistant crop varieties',
          'Practice conservation tillage',
          'Install efficient irrigation systems',
        ];
      case 'flood':
        return [
          'Improve drainage systems',
          'Plant flood-tolerant crops',
          'Elevate storage facilities',
          'Create flood barriers',
        ];
      case 'heatWave':
        return [
          'Provide shade structures',
          'Increase irrigation frequency',
          'Use heat-tolerant varieties',
          'Implement mulching',
        ];
      case 'frost':
        return [
          'Use frost protection covers',
          'Plant frost-resistant varieties',
          'Implement wind machines',
          'Use heating systems',
        ];
      case 'windDamage':
        return [
          'Plant windbreaks',
          'Use staking systems',
          'Choose wind-resistant varieties',
          'Implement shelter belts',
        ];
      default:
        return ['Monitor conditions closely', 'Implement protective measures'];
    }
  }
}

// Data classes for analysis results
class WeatherAnalysisReport {
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int dataPoints;
  final Map<String, dynamic> basicStatistics;
  final Map<String, dynamic> seasonalAnalysis;
  final Map<String, dynamic> trendAnalysis;
  final List<WeatherAnomaly> anomalies;
  final Map<String, dynamic> climateIndicators;
  final Map<String, dynamic> agriculturalImpact;
  final Map<String, dynamic> riskAssessment;
  final List<WeatherRecommendation> recommendations;
  final DateTime generatedAt;

  WeatherAnalysisReport({
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.dataPoints,
    required this.basicStatistics,
    required this.seasonalAnalysis,
    required this.trendAnalysis,
    required this.anomalies,
    required this.climateIndicators,
    required this.agriculturalImpact,
    required this.riskAssessment,
    required this.recommendations,
    required this.generatedAt,
  });

  factory WeatherAnalysisReport.empty(
    String location,
    DateTime startDate,
    DateTime endDate,
  ) {
    return WeatherAnalysisReport(
      location: location,
      startDate: startDate,
      endDate: endDate,
      dataPoints: 0,
      basicStatistics: {},
      seasonalAnalysis: {},
      trendAnalysis: {},
      anomalies: [],
      climateIndicators: {},
      agriculturalImpact: {},
      riskAssessment: {},
      recommendations: [],
      generatedAt: DateTime.now(),
    );
  }
}

class WeatherAnomaly {
  final String id;
  final String type;
  final String severity;
  final String description;
  final double value;
  final double expectedValue;
  final double deviation;
  final DateTime date;
  final String impact;

  WeatherAnomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.value,
    required this.expectedValue,
    required this.deviation,
    required this.date,
    required this.impact,
  });
}

class WeatherRecommendation {
  final String id;
  final String category;
  final String priority;
  final String title;
  final String description;
  final List<String> actions;
  final String impact;

  WeatherRecommendation({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actions,
    required this.impact,
  });
}
