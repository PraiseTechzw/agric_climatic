import 'package:flutter/material.dart';

class AgroClimaticPrediction {
  final String id;
  final DateTime date;
  final String location;
  final double temperature;
  final double humidity;
  final double precipitation;
  final double evapotranspiration;
  final String cropRecommendation;
  final String irrigationAdvice;
  final String pestRisk;
  final String diseaseRisk;
  final double yieldPrediction;
  final String plantingAdvice;
  final String harvestingAdvice;
  final List<String> weatherAlerts;
  final Map<String, dynamic> soilConditions;
  final Map<String, dynamic> climateIndicators;

  AgroClimaticPrediction({
    required this.id,
    required this.date,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.evapotranspiration,
    required this.cropRecommendation,
    required this.irrigationAdvice,
    required this.pestRisk,
    required this.diseaseRisk,
    required this.yieldPrediction,
    required this.plantingAdvice,
    required this.harvestingAdvice,
    required this.weatherAlerts,
    required this.soilConditions,
    required this.climateIndicators,
  });

  factory AgroClimaticPrediction.fromJson(Map<String, dynamic> json) {
    return AgroClimaticPrediction(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      precipitation: json['precipitation']?.toDouble() ?? 0.0,
      evapotranspiration: json['evapotranspiration']?.toDouble() ?? 0.0,
      cropRecommendation: json['crop_recommendation'] ?? '',
      irrigationAdvice: json['irrigation_advice'] ?? '',
      pestRisk: json['pest_risk'] ?? '',
      diseaseRisk: json['disease_risk'] ?? '',
      yieldPrediction: json['yield_prediction']?.toDouble() ?? 0.0,
      plantingAdvice: json['planting_advice'] ?? '',
      harvestingAdvice: json['harvesting_advice'] ?? '',
      weatherAlerts: List<String>.from(json['weather_alerts'] ?? []),
      soilConditions: Map<String, dynamic>.from(json['soil_conditions'] ?? {}),
      climateIndicators: Map<String, dynamic>.from(
        json['climate_indicators'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'temperature': temperature,
      'humidity': humidity,
      'precipitation': precipitation,
      'evapotranspiration': evapotranspiration,
      'crop_recommendation': cropRecommendation,
      'irrigation_advice': irrigationAdvice,
      'pest_risk': pestRisk,
      'disease_risk': diseaseRisk,
      'yield_prediction': yieldPrediction,
      'planting_advice': plantingAdvice,
      'harvesting_advice': harvestingAdvice,
      'weather_alerts': weatherAlerts,
      'soil_conditions': soilConditions,
      'climate_indicators': climateIndicators,
    };
  }

  // Risk level colors
  Color get pestRiskColor {
    switch (pestRisk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get diseaseRiskColor {
    switch (diseaseRisk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  // Yield prediction color
  Color get yieldColor {
    if (yieldPrediction < 50) return Colors.red;
    if (yieldPrediction < 75) return Colors.orange;
    return Colors.green;
  }
}

class HistoricalWeatherPattern {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final double averageTemperature;
  final double totalPrecipitation;
  final double averageHumidity;
  final String season;
  final String patternType;
  final List<String> anomalies;
  final Map<String, double> trends;
  final String summary;

  HistoricalWeatherPattern({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.averageTemperature,
    required this.totalPrecipitation,
    required this.averageHumidity,
    required this.season,
    required this.patternType,
    required this.anomalies,
    required this.trends,
    required this.summary,
  });

  factory HistoricalWeatherPattern.fromJson(Map<String, dynamic> json) {
    return HistoricalWeatherPattern(
      id: json['id'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      location: json['location'] ?? '',
      averageTemperature: json['average_temperature']?.toDouble() ?? 0.0,
      totalPrecipitation: json['total_precipitation']?.toDouble() ?? 0.0,
      averageHumidity: json['average_humidity']?.toDouble() ?? 0.0,
      season: json['season'] ?? '',
      patternType: json['pattern_type'] ?? '',
      anomalies: List<String>.from(json['anomalies'] ?? []),
      trends: Map<String, double>.from(json['trends'] ?? {}),
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'average_temperature': averageTemperature,
      'total_precipitation': totalPrecipitation,
      'average_humidity': averageHumidity,
      'season': season,
      'pattern_type': patternType,
      'anomalies': anomalies,
      'trends': trends,
      'summary': summary,
    };
  }
}

class CropRecommendation {
  final String cropName;
  final String variety;
  final DateTime optimalPlantingDate;
  final DateTime expectedHarvestDate;
  final double expectedYield;
  final String soilType;
  final double waterRequirement;
  final List<String> growingConditions;
  final List<String> pestControl;
  final List<String> diseasePrevention;
  final String marketPrice;
  final String profitability;

  CropRecommendation({
    required this.cropName,
    required this.variety,
    required this.optimalPlantingDate,
    required this.expectedHarvestDate,
    required this.expectedYield,
    required this.soilType,
    required this.waterRequirement,
    required this.growingConditions,
    required this.pestControl,
    required this.diseasePrevention,
    required this.marketPrice,
    required this.profitability,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      cropName: json['crop_name'] ?? '',
      variety: json['variety'] ?? '',
      optimalPlantingDate: DateTime.parse(json['optimal_planting_date']),
      expectedHarvestDate: DateTime.parse(json['expected_harvest_date']),
      expectedYield: json['expected_yield']?.toDouble() ?? 0.0,
      soilType: json['soil_type'] ?? '',
      waterRequirement: json['water_requirement']?.toDouble() ?? 0.0,
      growingConditions: List<String>.from(json['growing_conditions'] ?? []),
      pestControl: List<String>.from(json['pest_control'] ?? []),
      diseasePrevention: List<String>.from(json['disease_prevention'] ?? []),
      marketPrice: json['market_price'] ?? '',
      profitability: json['profitability'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_name': cropName,
      'variety': variety,
      'optimal_planting_date': optimalPlantingDate.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate.toIso8601String(),
      'expected_yield': expectedYield,
      'soil_type': soilType,
      'water_requirement': waterRequirement,
      'growing_conditions': growingConditions,
      'pest_control': pestControl,
      'disease_prevention': diseasePrevention,
      'market_price': marketPrice,
      'profitability': profitability,
    };
  }
}
