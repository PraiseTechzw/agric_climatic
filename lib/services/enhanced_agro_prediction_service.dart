import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weather.dart';
import '../models/agro_climatic_prediction.dart';
import 'notification_service.dart';
import 'logging_service.dart';

class EnhancedAgroPredictionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Zimbabwe crop data and climate zones - removed unused field

  // Enhanced pest and disease data for Zimbabwe - removed unused field

  // Long-term prediction (3-12 months ahead)
  Future<AgroClimaticPrediction> generateLongTermPrediction({
    required String location,
    required DateTime startDate,
    required int monthsAhead,
  }) async {
    try {
      LoggingService.info(
        'Generating long-term prediction',
        extra: {
          'location': location,
          'start_date': startDate.toIso8601String(),
          'months_ahead': monthsAhead,
        },
      );

      // Get historical data for pattern analysis
      final historicalData = await _getHistoricalData(
        location,
        startDate.subtract(Duration(days: 365 * 2)), // 2 years of data
      );

      // Analyze long-term patterns
      final patterns = await _analyzeLongTermPatterns(
        historicalData,
        monthsAhead,
      );

      // Generate predictions based on patterns and climate models
      final prediction = await _generateLongTermPredictionData(
        location,
        startDate,
        monthsAhead,
        patterns,
      );

      // Get enhanced crop recommendations
      final cropRecommendation = await _getEnhancedCropRecommendation(
        location,
        prediction,
        startDate,
      );

      // Assess long-term risks
      final pestRisk = _assessLongTermPestRisk(
        prediction,
        cropRecommendation,
        monthsAhead,
      );
      final diseaseRisk = _assessLongTermDiseaseRisk(
        prediction,
        cropRecommendation,
        monthsAhead,
      );
      // Climate risk assessment would be used here in a full implementation
      // final climateRisk = _assessClimateRisk(prediction, patterns);

      // Calculate yield prediction with confidence intervals
      final yieldPrediction = _calculateLongTermYieldPrediction(
        prediction,
        cropRecommendation,
        patterns,
      );

      // Generate comprehensive alerts
      final weatherAlerts = _generateLongTermWeatherAlerts(
        prediction,
        patterns,
      );

      // Send notifications for critical long-term alerts
      await _sendLongTermAlerts(weatherAlerts, location, monthsAhead);

      return AgroClimaticPrediction(
        id: '${location}_longterm_${startDate.millisecondsSinceEpoch}',
        date: startDate,
        location: location,
        temperature: prediction['temperature'] ?? 0.0,
        humidity: prediction['humidity'] ?? 0.0,
        precipitation: prediction['precipitation'] ?? 0.0,
        evapotranspiration: prediction['evapotranspiration'] ?? 0.0,
        cropRecommendation: cropRecommendation,
        irrigationAdvice: _generateLongTermIrrigationAdvice(
          prediction,
          monthsAhead,
        ),
        pestRisk: pestRisk,
        diseaseRisk: diseaseRisk,
        yieldPrediction: yieldPrediction,
        plantingAdvice: _generateLongTermPlantingAdvice(
          prediction,
          cropRecommendation,
          startDate,
        ),
        harvestingAdvice: _generateLongTermHarvestingAdvice(
          prediction,
          cropRecommendation,
          startDate,
        ),
        weatherAlerts: weatherAlerts,
        soilConditions: _assessLongTermSoilConditions(prediction, patterns),
        climateIndicators: _calculateLongTermClimateIndicators(
          prediction,
          patterns,
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to generate long-term prediction', error: e);
      throw Exception('Failed to generate long-term prediction: $e');
    }
  }

  // Sequential weather pattern analysis
  Future<List<HistoricalWeatherPattern>> analyzeSequentialPatterns({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String patternType, // 'seasonal', 'monthly', 'weekly', 'daily'
  }) async {
    try {
      LoggingService.info(
        'Analyzing sequential patterns',
        extra: {
          'location': location,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'pattern_type': patternType,
        },
      );

      final historicalData = await _getHistoricalData(
        location,
        startDate,
        endDate,
      );
      final patterns = await _analyzeSequentialWeatherPatterns(
        historicalData,
        patternType,
      );

      // Send pattern analysis notifications
      await _sendPatternAnalysisNotifications(patterns, location, patternType);

      return patterns;
    } catch (e) {
      LoggingService.error('Failed to analyze sequential patterns', error: e);
      throw Exception('Failed to analyze sequential patterns: $e');
    }
  }

  // Enhanced historical data retrieval
  Future<List<Weather>> _getHistoricalData(
    String location,
    DateTime startDate, [
    DateTime? endDate,
  ]) async {
    try {
      final response = await _supabase
          .from('weather_data')
          .select()
          .eq('location_name', location)
          .gte('date_time', startDate.toIso8601String())
          .lte('date_time', (endDate ?? DateTime.now()).toIso8601String())
          .order('date_time', ascending: true);

      return response.map((json) => Weather.fromJson(json)).toList();
    } catch (e) {
      LoggingService.error('Failed to fetch historical weather data', error: e);
      return [];
    }
  }

  // Long-term pattern analysis
  Future<List<HistoricalWeatherPattern>> _analyzeLongTermPatterns(
    List<Weather> data,
    int monthsAhead,
  ) async {
    if (data.isEmpty) return [];

    final patterns = <HistoricalWeatherPattern>[];

    // Analyze seasonal patterns over multiple years
    final years = <int>{};
    for (final weather in data) {
      years.add(weather.dateTime.year);
    }

    for (final year in years) {
      final yearData = data.where((w) => w.dateTime.year == year).toList();

      // Analyze each season
      final seasons = ['summer', 'autumn', 'winter', 'spring'];
      for (final season in seasons) {
        final seasonData = _filterBySeason(yearData, season);
        if (seasonData.isNotEmpty) {
          patterns.add(
            HistoricalWeatherPattern(
              id: '${season}_${year}_${DateTime.now().millisecondsSinceEpoch}',
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
              patternType: _determineLongTermPatternType(
                seasonData,
                monthsAhead,
              ),
              anomalies: _detectLongTermAnomalies(seasonData),
              trends: _calculateLongTermTrends(seasonData, monthsAhead),
              summary: _generateLongTermPatternSummary(
                seasonData,
                season,
                year,
              ),
            ),
          );
        }
      }
    }

    return patterns;
  }

  // Sequential pattern analysis
  Future<List<HistoricalWeatherPattern>> _analyzeSequentialWeatherPatterns(
    List<Weather> data,
    String patternType,
  ) async {
    if (data.isEmpty) return [];

    final patterns = <HistoricalWeatherPattern>[];

    switch (patternType.toLowerCase()) {
      case 'daily':
        patterns.addAll(_analyzeDailyPatterns(data));
        break;
      case 'weekly':
        patterns.addAll(_analyzeWeeklyPatterns(data));
        break;
      case 'monthly':
        patterns.addAll(_analyzeMonthlyPatterns(data));
        break;
      case 'seasonal':
        patterns.addAll(_analyzeSeasonalPatterns(data));
        break;
    }

    return patterns;
  }

  // Daily pattern analysis
  List<HistoricalWeatherPattern> _analyzeDailyPatterns(List<Weather> data) {
    final patterns = <HistoricalWeatherPattern>[];
    final dailyGroups = <int, List<Weather>>{};

    // Group by day of year
    for (final weather in data) {
      final dayOfYear = weather.dateTime
          .difference(DateTime(weather.dateTime.year, 1, 1))
          .inDays;
      dailyGroups.putIfAbsent(dayOfYear, () => []).add(weather);
    }

    // Analyze patterns for each day of year
    for (final entry in dailyGroups.entries) {
      final dayData = entry.value;
      if (dayData.length >= 3) {
        // At least 3 years of data
        patterns.add(
          HistoricalWeatherPattern(
            id: 'daily_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: dayData.first.dateTime,
            endDate: dayData.last.dateTime,
            location: dayData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(
              dayData.map((w) => w.temperature).toList(),
            ),
            totalPrecipitation: dayData
                .map((w) => w.precipitation)
                .reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(
              dayData.map((w) => w.humidity).toList(),
            ),
            season: _getSeasonFromDayOfYear(entry.key),
            patternType: 'daily',
            anomalies: _detectDailyAnomalies(dayData),
            trends: _calculateDailyTrends(dayData),
            summary: _generateDailyPatternSummary(dayData, entry.key),
          ),
        );
      }
    }

    return patterns;
  }

  // Weekly pattern analysis
  List<HistoricalWeatherPattern> _analyzeWeeklyPatterns(List<Weather> data) {
    final patterns = <HistoricalWeatherPattern>[];
    final weeklyGroups = <int, List<Weather>>{};

    // Group by week of year
    for (final weather in data) {
      final weekOfYear =
          (weather.dateTime
                      .difference(DateTime(weather.dateTime.year, 1, 1))
                      .inDays /
                  7)
              .floor();
      weeklyGroups.putIfAbsent(weekOfYear, () => []).add(weather);
    }

    // Analyze patterns for each week of year
    for (final entry in weeklyGroups.entries) {
      final weekData = entry.value;
      if (weekData.length >= 2) {
        // At least 2 years of data
        patterns.add(
          HistoricalWeatherPattern(
            id: 'weekly_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: weekData.first.dateTime,
            endDate: weekData.last.dateTime,
            location: weekData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(
              weekData.map((w) => w.temperature).toList(),
            ),
            totalPrecipitation: weekData
                .map((w) => w.precipitation)
                .reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(
              weekData.map((w) => w.humidity).toList(),
            ),
            season: _getSeasonFromWeekOfYear(entry.key),
            patternType: 'weekly',
            anomalies: _detectWeeklyAnomalies(weekData),
            trends: _calculateWeeklyTrends(weekData),
            summary: _generateWeeklyPatternSummary(weekData, entry.key),
          ),
        );
      }
    }

    return patterns;
  }

  // Monthly pattern analysis
  List<HistoricalWeatherPattern> _analyzeMonthlyPatterns(List<Weather> data) {
    final patterns = <HistoricalWeatherPattern>[];
    final monthlyGroups = <int, List<Weather>>{};

    // Group by month
    for (final weather in data) {
      monthlyGroups.putIfAbsent(weather.dateTime.month, () => []).add(weather);
    }

    // Analyze patterns for each month
    for (final entry in monthlyGroups.entries) {
      final monthData = entry.value;
      if (monthData.length >= 2) {
        // At least 2 years of data
        patterns.add(
          HistoricalWeatherPattern(
            id: 'monthly_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            startDate: monthData.first.dateTime,
            endDate: monthData.last.dateTime,
            location: monthData.first.id.split('_')[0],
            averageTemperature: _calculateAverage(
              monthData.map((w) => w.temperature).toList(),
            ),
            totalPrecipitation: monthData
                .map((w) => w.precipitation)
                .reduce((a, b) => a + b),
            averageHumidity: _calculateAverage(
              monthData.map((w) => w.humidity).toList(),
            ),
            season: _getSeasonFromMonth(entry.key),
            patternType: 'monthly',
            anomalies: _detectMonthlyAnomalies(monthData),
            trends: _calculateMonthlyTrends(monthData),
            summary: _generateMonthlyPatternSummary(monthData, entry.key),
          ),
        );
      }
    }

    return patterns;
  }

  // Seasonal pattern analysis
  List<HistoricalWeatherPattern> _analyzeSeasonalPatterns(List<Weather> data) {
    final patterns = <HistoricalWeatherPattern>[];
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
            patternType: 'seasonal',
            anomalies: _detectAnomalies(seasonData),
            trends: _calculateTrends(seasonData),
            summary: _generatePatternSummary(seasonData, season),
          ),
        );
      }
    }

    return patterns;
  }

  // Send pattern analysis notifications
  Future<void> _sendPatternAnalysisNotifications(
    List<HistoricalWeatherPattern> patterns,
    String location,
    String patternType,
  ) async {
    try {
      if (patterns.isEmpty) return;

      final significantPatterns = patterns
          .where(
            (p) =>
                p.anomalies.isNotEmpty ||
                (p.trends['temperature_trend'] ?? 0).abs() > 2.0 ||
                (p.trends['precipitation_trend'] ?? 0).abs() > 10.0,
          )
          .toList();

      if (significantPatterns.isNotEmpty) {
        await NotificationService.sendPatternAnalysis(
          title: 'Weather Pattern Analysis Complete',
          message:
              'Found ${significantPatterns.length} significant ${patternType} patterns in $location',
          patternType: patternType,
          location: location,
        );
      }
    } catch (e) {
      LoggingService.error(
        'Failed to send pattern analysis notifications',
        error: e,
      );
    }
  }

  // Send long-term alerts
  Future<void> _sendLongTermAlerts(
    List<String> alerts,
    String location,
    int monthsAhead,
  ) async {
    try {
      for (final alert in alerts) {
        if (alert.contains('warning') ||
            alert.contains('drought') ||
            alert.contains('flood')) {
          await NotificationService.sendWeatherAlert(
            title: 'Long-term Weather Alert',
            message: '$alert (${monthsAhead} months ahead)',
            severity: 'high',
            location: location,
          );
        }
      }
    } catch (e) {
      LoggingService.error('Failed to send long-term alerts', error: e);
    }
  }

  // Helper methods (implementations would be similar to existing service but enhanced)
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

  String _determineLongTermPatternType(List<Weather> data, int monthsAhead) {
    // Enhanced pattern type determination for long-term analysis
    if (data.isEmpty) return 'unknown';

    final avgTemp = _calculateAverage(data.map((w) => w.temperature).toList());
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    // Consider long-term trends
    if (avgTemp > 25 && totalPrecip > 100) return 'hot_wet_trending';
    if (avgTemp > 25 && totalPrecip < 50) return 'hot_dry_trending';
    if (avgTemp < 15 && totalPrecip > 100) return 'cool_wet_trending';
    if (avgTemp < 15 && totalPrecip < 50) return 'cool_dry_trending';
    return 'moderate_trending';
  }

  List<String> _detectLongTermAnomalies(List<Weather> data) {
    // Enhanced anomaly detection for long-term patterns
    final anomalies = <String>[];
    if (data.isEmpty) return anomalies;

    final temps = data.map((w) => w.temperature).toList();
    final avgTemp = _calculateAverage(temps);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);

    if (maxTemp > avgTemp + 15)
      anomalies.add('extreme_high_temperature_longterm');
    if (minTemp < avgTemp - 15)
      anomalies.add('extreme_low_temperature_longterm');

    return anomalies;
  }

  Map<String, double> _calculateLongTermTrends(
    List<Weather> data,
    int monthsAhead,
  ) {
    // Enhanced trend calculation for long-term analysis
    if (data.length < 2) return {};

    final temps = data.map((w) => w.temperature).toList();
    final firstHalf = temps.take(temps.length ~/ 2).toList();
    final secondHalf = temps.skip(temps.length ~/ 2).toList();

    final firstAvg = _calculateAverage(firstHalf);
    final secondAvg = _calculateAverage(secondHalf);

    return {
      'temperature_trend': (secondAvg - firstAvg) * (monthsAhead / 12.0),
      'precipitation_trend': 0.0, // Enhanced calculation would go here
      'humidity_trend': 0.0, // Enhanced calculation would go here
    };
  }

  String _generateLongTermPatternSummary(
    List<Weather> data,
    String season,
    int year,
  ) {
    if (data.isEmpty) return 'No data available for $season $year';

    final avgTemp = _calculateAverage(data.map((w) => w.temperature).toList());
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    return '$season $year: Average temperature ${avgTemp.toStringAsFixed(1)}°C, Total precipitation ${totalPrecip.toStringAsFixed(1)}mm (Long-term analysis)';
  }

  // Additional helper methods would be implemented here...
  // (The remaining methods would follow similar patterns but with enhanced logic for long-term analysis)

  String _getSeasonFromDayOfYear(int dayOfYear) {
    if (dayOfYear < 80) return 'summer';
    if (dayOfYear < 172) return 'autumn';
    if (dayOfYear < 264) return 'winter';
    if (dayOfYear < 356) return 'spring';
    return 'summer';
  }

  String _getSeasonFromWeekOfYear(int weekOfYear) {
    if (weekOfYear < 12) return 'summer';
    if (weekOfYear < 24) return 'autumn';
    if (weekOfYear < 36) return 'winter';
    if (weekOfYear < 48) return 'spring';
    return 'summer';
  }

  String _getSeasonFromMonth(int month) {
    if (month >= 12 || month <= 2) return 'summer';
    if (month >= 3 && month <= 5) return 'autumn';
    if (month >= 6 && month <= 8) return 'winter';
    return 'spring';
  }

  // Placeholder methods for enhanced analysis (would be fully implemented)
  Future<Map<String, dynamic>> _generateLongTermPredictionData(
    String location,
    DateTime startDate,
    int monthsAhead,
    List<HistoricalWeatherPattern> patterns,
  ) async {
    // Implementation for long-term prediction data generation
    return {};
  }

  Future<String> _getEnhancedCropRecommendation(
    String location,
    Map<String, dynamic> prediction,
    DateTime startDate,
  ) async {
    // Implementation for enhanced crop recommendations
    return 'maize';
  }

  String _assessLongTermPestRisk(
    Map<String, dynamic> prediction,
    String crop,
    int monthsAhead,
  ) {
    // Implementation for long-term pest risk assessment
    return 'low';
  }

  String _assessLongTermDiseaseRisk(
    Map<String, dynamic> prediction,
    String crop,
    int monthsAhead,
  ) {
    // Implementation for long-term disease risk assessment
    return 'low';
  }

  double _calculateLongTermYieldPrediction(
    Map<String, dynamic> prediction,
    String crop,
    List<HistoricalWeatherPattern> patterns,
  ) {
    // Implementation for long-term yield prediction
    return 80.0;
  }

  List<String> _generateLongTermWeatherAlerts(
    Map<String, dynamic> prediction,
    List<HistoricalWeatherPattern> patterns,
  ) {
    // Implementation for long-term weather alerts
    return [];
  }

  String _generateLongTermIrrigationAdvice(
    Map<String, dynamic> prediction,
    int monthsAhead,
  ) {
    // Implementation for long-term irrigation advice
    return 'Monitor soil moisture levels';
  }

  String _generateLongTermPlantingAdvice(
    Map<String, dynamic> prediction,
    String crop,
    DateTime startDate,
  ) {
    // Implementation for long-term planting advice
    return 'Optimal planting conditions expected';
  }

  String _generateLongTermHarvestingAdvice(
    Map<String, dynamic> prediction,
    String crop,
    DateTime startDate,
  ) {
    // Implementation for long-term harvesting advice
    return 'Good harvesting conditions expected';
  }

  Map<String, dynamic> _assessLongTermSoilConditions(
    Map<String, dynamic> prediction,
    List<HistoricalWeatherPattern> patterns,
  ) {
    // Implementation for long-term soil conditions
    return {};
  }

  Map<String, dynamic> _calculateLongTermClimateIndicators(
    Map<String, dynamic> prediction,
    List<HistoricalWeatherPattern> patterns,
  ) {
    // Implementation for long-term climate indicators
    return {};
  }

  // Additional helper methods for pattern analysis
  List<String> _detectDailyAnomalies(List<Weather> data) => [];
  List<String> _detectWeeklyAnomalies(List<Weather> data) => [];
  List<String> _detectMonthlyAnomalies(List<Weather> data) => [];
  List<String> _detectAnomalies(List<Weather> data) => [];

  Map<String, double> _calculateDailyTrends(List<Weather> data) => {};
  Map<String, double> _calculateWeeklyTrends(List<Weather> data) => {};
  Map<String, double> _calculateMonthlyTrends(List<Weather> data) => {};
  Map<String, double> _calculateTrends(List<Weather> data) => {};

  String _generateDailyPatternSummary(List<Weather> data, int dayOfYear) => '';
  String _generateWeeklyPatternSummary(List<Weather> data, int weekOfYear) =>
      '';
  String _generateMonthlyPatternSummary(List<Weather> data, int month) => '';
  String _generatePatternSummary(List<Weather> data, String season) => '';
}
