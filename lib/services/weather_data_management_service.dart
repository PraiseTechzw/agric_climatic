import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/dashboard_data.dart';
import 'logging_service.dart';

class WeatherDataManagementService {
  final Random _random = Random();

  // In-memory storage for demo purposes
  static final Map<String, List<Weather>> _weatherDataStorage = {};
  static final Map<String, List<WeatherPattern>> _patternStorage = {};
  static final Map<String, List<ClimateDashboardData>> _dashboardDataStorage =
      {};

  // Upload weather data from CSV/JSON files
  Future<bool> uploadWeatherData({
    required String location,
    required File file,
    required String fileType, // 'csv' or 'json'
  }) async {
    try {
      final content = await file.readAsString();
      List<Weather> weatherData = [];

      if (fileType.toLowerCase() == 'csv') {
        weatherData = _parseCSVWeatherData(content, location);
      } else if (fileType.toLowerCase() == 'json') {
        weatherData = _parseJSONWeatherData(content, location);
      } else {
        throw Exception('Unsupported file type: $fileType');
      }

      // Store the data
      _weatherDataStorage[location] = weatherData;

      // Generate dashboard data
      await _generateDashboardDataFromWeather(location, weatherData);

      LoggingService.info(
        'Uploaded ${weatherData.length} weather records for $location',
      );
      return true;
    } catch (e) {
      LoggingService.error('Failed to upload weather data', error: e);
      return false;
    }
  }

  // Upload weather patterns
  Future<bool> uploadWeatherPatterns({
    required String location,
    required File file,
    required String fileType,
  }) async {
    try {
      final content = await file.readAsString();
      List<WeatherPattern> patterns = [];

      if (fileType.toLowerCase() == 'json') {
        patterns = _parseJSONPatterns(content, location);
      } else {
        throw Exception('Only JSON format supported for patterns');
      }

      _patternStorage[location] = patterns;
      LoggingService.info(
        'Uploaded ${patterns.length} weather patterns for $location',
      );
      return true;
    } catch (e) {
      LoggingService.error('Failed to upload weather patterns', error: e);
      return false;
    }
  }

  // Delete weather data for a location
  Future<bool> deleteWeatherData(String location) async {
    try {
      _weatherDataStorage.remove(location);
      _patternStorage.remove(location);
      _dashboardDataStorage.remove(location);

      LoggingService.info('Deleted all weather data for $location');
      return true;
    } catch (e) {
      LoggingService.error('Failed to delete weather data', error: e);
      return false;
    }
  }

  // Update specific weather record
  Future<bool> updateWeatherRecord({
    required String location,
    required String recordId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final weatherData = _weatherDataStorage[location];
      if (weatherData == null) return false;

      final index = weatherData.indexWhere((w) => w.id == recordId);
      if (index == -1) return false;

      // Create updated weather object
      final original = weatherData[index];
      final updated = Weather(
        id: original.id,
        dateTime: updates['dateTime'] ?? original.dateTime,
        temperature: updates['temperature'] ?? original.temperature,
        humidity: updates['humidity'] ?? original.humidity,
        windSpeed: updates['windSpeed'] ?? original.windSpeed,
        condition: updates['condition'] ?? original.condition,
        description: updates['description'] ?? original.description,
        icon: updates['icon'] ?? original.icon,
        pressure: updates['pressure'] ?? original.pressure,
        precipitation: updates['precipitation'] ?? original.precipitation,
        visibility: updates['visibility'] ?? original.visibility,
        uvIndex: updates['uvIndex'] ?? original.uvIndex,
        feelsLike: updates['feelsLike'] ?? original.feelsLike,
        dewPoint: updates['dewPoint'] ?? original.dewPoint,
        windGust: updates['windGust'] ?? original.windGust,
        windDegree: updates['windDegree'] ?? original.windDegree,
        windDirection: updates['windDirection'] ?? original.windDirection,
        cloudCover: updates['cloudCover'] ?? original.cloudCover,
        airQuality: updates['airQuality'] ?? original.airQuality,
        pollenData: updates['pollenData'] ?? original.pollenData,
      );

      weatherData[index] = updated;

      // Regenerate dashboard data
      await _generateDashboardDataFromWeather(location, weatherData);

      LoggingService.info('Updated weather record $recordId for $location');
      return true;
    } catch (e) {
      LoggingService.error('Failed to update weather record', error: e);
      return false;
    }
  }

  // Add new weather record
  Future<bool> addWeatherRecord({
    required String location,
    required Weather weather,
  }) async {
    try {
      if (_weatherDataStorage[location] == null) {
        _weatherDataStorage[location] = [];
      }

      _weatherDataStorage[location]!.add(weather);

      // Regenerate dashboard data
      await _generateDashboardDataFromWeather(
        location,
        _weatherDataStorage[location]!,
      );

      LoggingService.info('Added new weather record for $location');
      return true;
    } catch (e) {
      LoggingService.error('Failed to add weather record', error: e);
      return false;
    }
  }

  // Get weather data for analysis
  List<Weather> getWeatherData(String location) {
    return _weatherDataStorage[location] ?? [];
  }

  // Get weather patterns
  List<WeatherPattern> getWeatherPatterns(String location) {
    return _patternStorage[location] ?? [];
  }

  // Get dashboard data
  List<ClimateDashboardData> getDashboardData(String location) {
    return _dashboardDataStorage[location] ?? [];
  }

  // Export weather data to CSV
  Future<String> exportWeatherDataToCSV(String location) async {
    try {
      final weatherData = _weatherDataStorage[location] ?? [];
      if (weatherData.isEmpty) return '';

      final buffer = StringBuffer();

      // CSV Header
      buffer.writeln(
        'Date,Time,Temperature,Humidity,Wind Speed,Precipitation,Pressure,Condition,Description',
      );

      // CSV Data
      for (final weather in weatherData) {
        buffer.writeln(
          '${weather.dateTime.toIso8601String().split('T')[0]},'
          '${weather.dateTime.toIso8601String().split('T')[1].split('.')[0]},'
          '${weather.temperature},'
          '${weather.humidity},'
          '${weather.windSpeed},'
          '${weather.precipitation},'
          '${weather.pressure},'
          '${weather.condition},'
          '${weather.description}',
        );
      }

      return buffer.toString();
    } catch (e) {
      LoggingService.error('Failed to export weather data', error: e);
      return '';
    }
  }

  // Export weather data to JSON
  Future<String> exportWeatherDataToJSON(String location) async {
    try {
      final weatherData = _weatherDataStorage[location] ?? [];
      if (weatherData.isEmpty) return '';

      final jsonData = {
        'location': location,
        'exportDate': DateTime.now().toIso8601String(),
        'recordCount': weatherData.length,
        'data': weatherData.map((w) => w.toJson()).toList(),
      };

      return jsonEncode(jsonData);
    } catch (e) {
      LoggingService.error('Failed to export weather data to JSON', error: e);
      return '';
    }
  }

  // Parse CSV weather data
  List<Weather> _parseCSVWeatherData(String content, String location) {
    final lines = content.split('\n');
    final weatherData = <Weather>[];

    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = line.split(',');
      if (fields.length < 9) continue;

      try {
        final dateTime = DateTime.parse('${fields[0]}T${fields[1]}');
        final weather = Weather(
          id: '${location}_${dateTime.millisecondsSinceEpoch}',
          dateTime: dateTime,
          temperature: double.parse(fields[2]),
          humidity: double.parse(fields[3]),
          windSpeed: double.parse(fields[4]),
          condition: fields[7],
          description: fields[8],
          icon: '01d',
          pressure: double.parse(fields[6]),
          precipitation: double.parse(fields[5]),
        );
        weatherData.add(weather);
      } catch (e) {
        LoggingService.warning('Failed to parse CSV line $i', error: e);
      }
    }

    return weatherData;
  }

  // Parse JSON weather data
  List<Weather> _parseJSONWeatherData(String content, String location) {
    try {
      final jsonData = jsonDecode(content);
      final weatherData = <Weather>[];

      if (jsonData is Map && jsonData['data'] is List) {
        for (final item in jsonData['data']) {
          try {
            final weather = Weather.fromJson(item);
            weatherData.add(weather);
          } catch (e) {
            LoggingService.warning(
              'Failed to parse JSON weather item',
              error: e,
            );
          }
        }
      }

      return weatherData;
    } catch (e) {
      LoggingService.error('Failed to parse JSON weather data', error: e);
      return [];
    }
  }

  // Parse JSON patterns
  List<WeatherPattern> _parseJSONPatterns(String content, String location) {
    try {
      final jsonData = jsonDecode(content);
      final patterns = <WeatherPattern>[];

      if (jsonData is List) {
        for (final item in jsonData) {
          try {
            final pattern = WeatherPattern.fromJson(item);
            patterns.add(pattern);
          } catch (e) {
            LoggingService.warning(
              'Failed to parse JSON pattern item',
              error: e,
            );
          }
        }
      }

      return patterns;
    } catch (e) {
      LoggingService.error('Failed to parse JSON patterns', error: e);
      return [];
    }
  }

  // Generate dashboard data from weather data
  Future<void> _generateDashboardDataFromWeather(
    String location,
    List<Weather> weatherData,
  ) async {
    try {
      if (weatherData.isEmpty) return;

      // Group by year
      final yearlyData = <int, List<Weather>>{};
      for (final weather in weatherData) {
        final year = weather.dateTime.year;
        yearlyData[year] ??= [];
        yearlyData[year]!.add(weather);
      }

      final dashboardData = <ClimateDashboardData>[];

      for (final entry in yearlyData.entries) {
        final year = entry.key;
        final yearData = entry.value;

        final temperatures = yearData.map((w) => w.temperature).toList();
        final precipitations = yearData.map((w) => w.precipitation).toList();
        final humidities = yearData.map((w) => w.humidity).toList();
        final windSpeeds = yearData.map((w) => w.windSpeed).toList();

        final averageTemperature =
            temperatures.reduce((a, b) => a + b) / temperatures.length;
        final totalPrecipitation = precipitations.reduce((a, b) => a + b);
        final averageHumidity =
            humidities.reduce((a, b) => a + b) / humidities.length;
        final averageWindSpeed =
            windSpeeds.reduce((a, b) => a + b) / windSpeeds.length;
        final rainyDays = yearData.where((w) => w.precipitation > 0).length;
        final maxTemperature = temperatures.reduce((a, b) => a > b ? a : b);
        final minTemperature = temperatures.reduce((a, b) => a < b ? a : b);

        final trends = <String, double>{
          'temperature_trend': _calculateTrend(temperatures),
          'precipitation_trend': _calculateTrend(precipitations),
          'humidity_trend': _calculateTrend(humidities),
        };

        final anomalies = _detectAnomalies(yearData);

        dashboardData.add(
          ClimateDashboardData(
            id: '${location}_$year',
            location: location,
            date: DateTime(year),
            averageTemperature: averageTemperature,
            totalPrecipitation: totalPrecipitation,
            averageHumidity: averageHumidity,
            averageWindSpeed: averageWindSpeed,
            rainyDays: rainyDays,
            maxTemperature: maxTemperature,
            minTemperature: minTemperature,
            trends: trends,
            anomalies: anomalies,
            period: 'yearly',
          ),
        );
      }

      _dashboardDataStorage[location] = dashboardData
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      LoggingService.error('Failed to generate dashboard data', error: e);
    }
  }

  // Calculate trend using linear regression
  double _calculateTrend(List<double> values) {
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

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  // Detect anomalies in weather data
  List<String> _detectAnomalies(List<Weather> data) {
    final anomalies = <String>[];
    if (data.isEmpty) return anomalies;

    final temps = data.map((w) => w.temperature).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);

    if (maxTemp > avgTemp + 8) anomalies.add('High temperature spike');
    if (minTemp < avgTemp - 8) anomalies.add('Low temperature drop');

    final precipitations = data.map((w) => w.precipitation).toList();
    final maxPrecip = precipitations.reduce((a, b) => a > b ? a : b);
    if (maxPrecip > 50) anomalies.add('Extreme rainfall event');

    return anomalies;
  }
}
