import 'package:agric_climatic/services/agro_climatic_service.dart';
import 'package:flutter/foundation.dart';
import '../models/agro_climatic_prediction.dart';
import '../models/weather_pattern.dart';
import '../models/agricultural_recommendation.dart';

class AgroClimaticProvider with ChangeNotifier {
  final AgroPredictionService _agroClimaticService = AgroPredictionService();

  List<AgroClimaticPrediction> _predictions = [];
  List<WeatherPattern> _weatherPatterns = [];
  List<AgriculturalRecommendation> _recommendations = [];

  bool _isLoading = false;
  String _selectedCrop = 'Maize';
  String _selectedLocation = 'Harare';
  String? _error;

  // Getters
  List<AgroClimaticPrediction> get predictions => _predictions;
  List<WeatherPattern> get weatherPatterns => _weatherPatterns;
  List<AgriculturalRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String get selectedCrop => _selectedCrop;
  String get selectedLocation => _selectedLocation;
  String? get error => _error;

  // Available crops and locations
  final List<String> availableCrops = [
    'Maize',
    'Wheat',
    'Cotton',
    'Tobacco',
    'Soybeans',
    'Groundnuts',
    'Sorghum',
    'Millet',
  ];

  final List<String> availableLocations = [
    'Harare',
    'Bulawayo',
    'Chitungwiza',
    'Mutare',
    'Gweru',
    'Kwekwe',
    'Kadoma',
    'Masvingo',
    'Chinhoyi',
    'Norton',
    'Marondera',
    'Bindura',
    'Beitbridge',
    'Victoria Falls',
    'Chipinge',
    'Kariba',
    'Gwanda',
    'Shurugwi',
    'Chegutu',
    'Redcliff',
  ];

  // Load predictions
  Future<void> loadPredictions({String? crop, String? location}) async {
    _setLoading(true);
    _error = null;

    try {
      final cropType = crop ?? _selectedCrop;
      final loc = location ?? _selectedLocation;

      // Generate predictions for the next 30 days
      final List<AgroClimaticPrediction> predictions = [];
      final now = DateTime.now();

      for (int i = 0; i < 30; i++) {
        final prediction =
            await _agroClimaticService.generateLongTermPrediction(
          location: loc,
          startDate: now.add(Duration(days: i)),
          daysAhead: 1,
        );
        // Add crop-specific information to the prediction
        final adjustedPrediction = AgroClimaticPrediction(
          id: prediction.id,
          date: prediction.date,
          location: prediction.location,
          temperature: prediction.temperature,
          humidity: prediction.humidity,
          precipitation: prediction.precipitation,
          soilMoisture: prediction.soilMoisture,
          evapotranspiration: prediction.evapotranspiration,
          cropRecommendation: '$cropType: ${prediction.cropRecommendation}',
          irrigationAdvice: prediction.irrigationAdvice,
          pestRisk: prediction.pestRisk,
          diseaseRisk: prediction.diseaseRisk,
          yieldPrediction: prediction.yieldPrediction,
          plantingAdvice: prediction.plantingAdvice,
          harvestingAdvice: prediction.harvestingAdvice,
          weatherAlerts: prediction.weatherAlerts,
          soilConditions: prediction.soilConditions,
          climateIndicators: prediction.climateIndicators,
        );
        predictions.add(adjustedPrediction);
      }

      _predictions = predictions;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load predictions: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load weather patterns
  Future<void> loadWeatherPatterns({String? location}) async {
    _setLoading(true);
    _error = null;

    try {
      final loc = location ?? _selectedLocation;

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 90));

      final historicalPatterns =
          await _agroClimaticService.analyzeSequentialPatterns(
        location: loc,
        startDate: startDate,
        endDate: endDate,
      );

      // Convert HistoricalWeatherPattern to WeatherPattern
      _weatherPatterns = historicalPatterns
          .map((pattern) => WeatherPattern(
                id: pattern.id,
                location: pattern.location,
                startDate: pattern.startDate,
                endDate: pattern.endDate,
                patternType: pattern.patternType,
                description: pattern.summary,
                severity: 5.0, // Default severity
                indicators: pattern.anomalies,
                statistics: pattern.trends,
                impacts: [],
                recommendations: [],
              ))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load weather patterns: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load recommendations
  Future<void> loadRecommendations({String? crop, String? location}) async {
    _setLoading(true);
    _error = null;

    try {
      final cropType = crop ?? _selectedCrop;
      final loc = location ?? _selectedLocation;

      // Generate mock recommendations based on predictions and patterns
      _recommendations = _generateMockRecommendations(loc, cropType);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recommendations: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load all data
  Future<void> loadAllData({String? crop, String? location}) async {
    _setLoading(true);
    _error = null;

    try {
      final cropType = crop ?? _selectedCrop;
      final loc = location ?? _selectedLocation;

      // Load all data in parallel
      await Future.wait([
        loadPredictions(crop: cropType, location: loc),
        loadWeatherPatterns(location: loc),
        loadRecommendations(crop: cropType, location: loc),
      ]);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load data: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Change crop
  void changeCrop(String crop) {
    if (_selectedCrop != crop) {
      _selectedCrop = crop;
      notifyListeners();
      // Reload data with new crop
      loadAllData();
    }
  }

  // Change location
  void changeLocation(String location) {
    if (_selectedLocation != location) {
      _selectedLocation = location;
      notifyListeners();
      // Reload data with new location
      loadAllData();
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await loadAllData();
  }

  // Get predictions for specific date range
  List<AgroClimaticPrediction> getPredictionsForDateRange(
      DateTime start, DateTime end) {
    return _predictions.where((prediction) {
      return prediction.date.isAfter(start.subtract(const Duration(days: 1))) &&
          prediction.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get high confidence predictions
  List<AgroClimaticPrediction> getHighConfidencePredictions() {
    return _predictions
        .where((prediction) => prediction.yieldPrediction > 75.0)
        .toList();
  }

  // Get critical weather patterns
  List<WeatherPattern> getCriticalWeatherPatterns() {
    return _weatherPatterns.where((pattern) => pattern.severity > 7.0).toList();
  }

  // Get high priority recommendations
  List<AgriculturalRecommendation> getHighPriorityRecommendations() {
    return _recommendations.where((rec) => rec.priority == 'high').toList();
  }

  // Get unread recommendations
  List<AgriculturalRecommendation> getUnreadRecommendations() {
    return _recommendations.where((rec) => !rec.isRead).toList();
  }

  // Mark recommendation as read
  void markRecommendationAsRead(String recommendationId) {
    final index =
        _recommendations.indexWhere((rec) => rec.id == recommendationId);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Get average prediction values
  Map<String, double> getAveragePredictionValues() {
    if (_predictions.isEmpty) return {};

    double totalRainfall = 0;
    double totalTemperature = 0;
    double totalHumidity = 0;
    double totalSoilMoisture = 0;

    for (final prediction in _predictions) {
      totalRainfall += prediction.precipitation;
      totalTemperature += prediction.temperature;
      totalHumidity += prediction.humidity;
      totalSoilMoisture += prediction.soilMoisture;
    }

    final count = _predictions.length.toDouble();

    return {
      'rainfall': totalRainfall / count,
      'temperature': totalTemperature / count,
      'humidity': totalHumidity / count,
      'soilMoisture': totalSoilMoisture / count,
    };
  }

  // Get prediction trends
  Map<String, String> getPredictionTrends() {
    if (_predictions.length < 2) return {};

    final firstHalf = _predictions.take(_predictions.length ~/ 2).toList();
    final secondHalf = _predictions.skip(_predictions.length ~/ 2).toList();

    final firstAvg = _getAverageValues(firstHalf);
    final secondAvg = _getAverageValues(secondHalf);

    return {
      'rainfall': _getTrend(firstAvg['rainfall']!, secondAvg['rainfall']!),
      'temperature':
          _getTrend(firstAvg['temperature']!, secondAvg['temperature']!),
      'humidity': _getTrend(firstAvg['humidity']!, secondAvg['humidity']!),
      'soilMoisture':
          _getTrend(firstAvg['soilMoisture']!, secondAvg['soilMoisture']!),
    };
  }

  Map<String, double> _getAverageValues(
      List<AgroClimaticPrediction> predictions) {
    if (predictions.isEmpty) return {};

    double totalRainfall = 0;
    double totalTemperature = 0;
    double totalHumidity = 0;
    double totalSoilMoisture = 0;

    for (final prediction in predictions) {
      totalRainfall += prediction.precipitation;
      totalTemperature += prediction.temperature;
      totalHumidity += prediction.humidity;
      totalSoilMoisture += prediction.soilMoisture;
    }

    final count = predictions.length.toDouble();

    return {
      'rainfall': totalRainfall / count,
      'temperature': totalTemperature / count,
      'humidity': totalHumidity / count,
      'soilMoisture': totalSoilMoisture / count,
    };
  }

  String _getTrend(double first, double second) {
    if (second > first * 1.05) return 'increasing';
    if (second < first * 0.95) return 'decreasing';
    return 'stable';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Generate mock recommendations
  List<AgriculturalRecommendation> _generateMockRecommendations(
      String location, String cropType) {
    final now = DateTime.now();
    return [
      AgriculturalRecommendation(
        id: 'rec_1',
        title: 'Optimal Planting Window',
        description:
            'Plant $cropType between ${now.add(const Duration(days: 7)).day}/${now.add(const Duration(days: 7)).month} and ${now.add(const Duration(days: 14)).day}/${now.add(const Duration(days: 14)).month} for best results.',
        category: 'Planting',
        priority: 'high',
        date: now,
        location: location,
        cropType: cropType,
        actions: ['Prepare soil', 'Check weather forecast', 'Gather seeds'],
        conditions: {'temperature': '18-24°C', 'humidity': '60-80%'},
        createdAt: now,
      ),
      AgriculturalRecommendation(
        id: 'rec_2',
        title: 'Irrigation Schedule',
        description:
            'Water every 3-4 days during the growing season. Increase frequency during dry spells.',
        category: 'Irrigation',
        priority: 'medium',
        date: now,
        location: location,
        cropType: cropType,
        actions: [
          'Set up irrigation system',
          'Monitor soil moisture',
          'Adjust schedule based on weather'
        ],
        conditions: {'soil_moisture': '40-60%'},
        createdAt: now,
      ),
      AgriculturalRecommendation(
        id: 'rec_3',
        title: 'Pest Control Alert',
        description:
            'High risk of pest infestation due to current weather conditions. Apply preventive measures.',
        category: 'Pest Control',
        priority: 'high',
        date: now,
        location: location,
        cropType: cropType,
        actions: [
          'Apply organic pesticides',
          'Monitor crop health',
          'Remove affected plants'
        ],
        conditions: {'humidity': '>70%', 'temperature': '>25°C'},
        createdAt: now,
      ),
    ];
  }
}
