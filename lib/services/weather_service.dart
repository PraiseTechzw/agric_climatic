import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import 'network_service.dart';

class WeatherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // WeatherAPI configuration for Zimbabwe
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const String _apiKey = '4360f911bf30467c85c12953251009';

  Future<Weather> getCurrentWeather({String city = 'Harare'}) async {
    try {
      // Check internet connectivity first
      if (!await NetworkService.hasInternetConnection()) {
        throw Exception('No internet connection available');
      }

      final url =
          '$_baseUrl/current.json?key=$_apiKey&q=$city&aqi=yes&pollen=yes';
      final response = await NetworkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCurrentWeatherFromWeatherAPI(data, city);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get current weather for $city: $e');
    }
  }

  Future<WeatherForecast> getForecast({String city = 'Harare'}) async {
    try {
      // Check internet connectivity first
      if (!await NetworkService.hasInternetConnection()) {
        throw Exception('No internet connection available');
      }

      final url =
          '$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=7&aqi=yes&alerts=yes&pollen=yes';
      final response = await NetworkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseForecastFromWeatherAPI(data);
      } else {
        throw Exception(
          'Failed to fetch forecast data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get forecast for $city: $e');
    }
  }

  Future<List<Weather>> getHistoricalWeather({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('weather_data')
          .where(
            'date_time',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('date_time', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date_time', descending: false)
          .get();

      return snapshot.docs.map((doc) => Weather.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch historical weather: $e');
    }
  }

  Future<List<WeatherAlert>> getWeatherAlerts() async {
    try {
      final snapshot = await _firestore
          .collection('weather_alerts')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WeatherAlert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch weather alerts: $e');
    }
  }

  // New WeatherAPI.com specific methods

  /// Get weather alerts from WeatherAPI.com
  Future<List<WeatherAlert>> getWeatherAPIAlerts({
    String city = 'Harare',
  }) async {
    try {
      final url = '$_baseUrl/alerts.json?key=$_apiKey&q=$city';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherAPIAlerts(data);
      } else {
        throw Exception(
          'Failed to fetch weather alerts: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get weather alerts for $city: $e');
    }
  }

  /// Get astronomy data for agricultural timing
  Future<AstronomyData> getAstronomyData({String city = 'Harare'}) async {
    try {
      final url = '$_baseUrl/astronomy.json?key=$_apiKey&q=$city';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AstronomyData.fromJson(data['astronomy']['astro']);
      } else {
        throw Exception(
          'Failed to fetch astronomy data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get astronomy data for $city: $e');
    }
  }

  /// Get historical weather from WeatherAPI.com
  Future<List<Weather>> getWeatherAPIHistoricalWeather({
    required DateTime date,
    String city = 'Harare',
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final url =
          '$_baseUrl/history.json?key=$_apiKey&q=$city&dt=$dateStr&aqi=yes&pollen=yes';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseHistoricalWeatherFromWeatherAPI(data);
      } else {
        throw Exception(
          'Failed to fetch historical weather: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get historical weather for $city: $e');
    }
  }

  /// Get bulk weather data for multiple Zimbabwe locations
  Future<Map<String, Weather>> getBulkWeatherData({
    List<String>? cities,
  }) async {
    try {
      final citiesToQuery =
          cities ??
          [
            'Harare',
            'Bulawayo',
            'Chitungwiza',
            'Mutare',
            'Gweru',
            'Kwekwe',
            'Kadoma',
            'Masvingo',
            'Chinhoyi',
            'Marondera',
          ];

      final locations = citiesToQuery
          .map(
            (city) => {
              'q': city,
              'custom_id': city.toLowerCase().replaceAll(' ', '_'),
            },
          )
          .toList();

      final body = json.encode({'locations': locations});

      final url = '$_baseUrl/current.json?key=$_apiKey&q=bulk';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseBulkWeatherData(data);
      } else {
        throw Exception(
          'Failed to fetch bulk weather data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get bulk weather data: $e');
    }
  }

  Weather _parseCurrentWeatherFromWeatherAPI(
    Map<String, dynamic> data,
    String city,
  ) {
    final current = data['current'];

    return Weather(
      id: '${city}_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.parse(current['last_updated']),
      temperature: current['temp_c'].toDouble(),
      humidity: current['humidity'].toDouble(),
      windSpeed: current['wind_kph'].toDouble() / 3.6, // Convert km/h to m/s
      condition: _getWeatherConditionFromCode(current['condition']['code']),
      description: current['condition']['text'],
      icon: _getWeatherIconFromCode(current['condition']['code']),
      pressure: current['pressure_mb'].toDouble(),
      visibility: current['vis_km'].toDouble(),
      precipitation: current['precip_mm']?.toDouble() ?? 0.0,
      uvIndex: current['uv']?.toDouble(),
      feelsLike: current['feelslike_c']?.toDouble(),
      dewPoint: current['dewpoint_c']?.toDouble(),
      windGust: current['gust_kph']?.toDouble() / 3.6, // Convert km/h to m/s
      windDegree: current['wind_degree']?.toInt(),
      windDirection: current['wind_dir'],
      cloudCover: current['cloud']?.toDouble(),
      airQuality: current['air_quality'] != null
          ? AirQuality.fromJson(current['air_quality'])
          : null,
      pollenData: current['pollen'] != null
          ? PollenData.fromJson(current['pollen'])
          : null,
    );
  }

  WeatherForecast _parseForecastFromWeatherAPI(Map<String, dynamic> data) {
    final forecast = data['forecast'];
    final hourly = forecast['forecastday'][0]['hour'] as List;
    final daily = forecast['forecastday'] as List;

    // Parse hourly forecast (next 24 hours)
    final hourlyWeather = <Weather>[];
    for (int i = 0; i < 24 && i < hourly.length; i++) {
      final hour = hourly[i];
      hourlyWeather.add(
        Weather(
          id: 'hourly_$i',
          dateTime: DateTime.parse(hour['time']),
          temperature: hour['temp_c'].toDouble(),
          humidity: hour['humidity'].toDouble(),
          windSpeed: hour['wind_kph'].toDouble() / 3.6, // Convert km/h to m/s
          condition: _getWeatherConditionFromCode(hour['condition']['code']),
          description: hour['condition']['text'],
          icon: _getWeatherIconFromCode(hour['condition']['code']),
          pressure: hour['pressure_mb'].toDouble(),
          visibility: hour['vis_km'].toDouble(),
          precipitation: hour['precip_mm']?.toDouble() ?? 0.0,
        ),
      );
    }

    // Parse daily forecast (next 7 days)
    final dailyWeather = <Weather>[];
    for (int i = 0; i < daily.length; i++) {
      final day = daily[i]['day'];
      final date = daily[i]['date'];
      dailyWeather.add(
        Weather(
          id: 'daily_$i',
          dateTime: DateTime.parse(date),
          temperature:
              (day['maxtemp_c'].toDouble() + day['mintemp_c'].toDouble()) / 2,
          humidity: day['avghumidity'].toDouble(),
          windSpeed: day['maxwind_kph'].toDouble() / 3.6, // Convert km/h to m/s
          condition: _getWeatherConditionFromCode(day['condition']['code']),
          description: day['condition']['text'],
          icon: _getWeatherIconFromCode(day['condition']['code']),
          pressure: 1013.25, // WeatherAPI doesn't provide daily pressure
          visibility: 10.0, // WeatherAPI doesn't provide daily visibility
          precipitation: day['totalprecip_mm']?.toDouble() ?? 0.0,
        ),
      );
    }

    return WeatherForecast(hourly: hourlyWeather, daily: dailyWeather);
  }

  String _getWeatherConditionFromCode(int weatherCode) {
    // WeatherAPI condition codes
    if (weatherCode == 1000) return 'clear';
    if (weatherCode == 1003) return 'cloudy';
    if (weatherCode == 1006 || weatherCode == 1009) return 'cloudy';
    if (weatherCode == 1030 || weatherCode == 1135 || weatherCode == 1147) {
      return 'foggy';
    }
    if (weatherCode >= 1063 && weatherCode <= 1201) return 'rainy';
    if (weatherCode >= 1210 && weatherCode <= 1237) return 'snowy';
    if (weatherCode >= 1240 && weatherCode <= 1264) return 'snowy';
    if (weatherCode >= 1273 && weatherCode <= 1282) return 'stormy';
    return 'clear';
  }

  String _getWeatherIconFromCode(int weatherCode) {
    // WeatherAPI condition codes to OpenWeatherMap icons
    if (weatherCode == 1000) return '01d'; // Clear
    if (weatherCode == 1003) return '02d'; // Partly cloudy
    if (weatherCode == 1006) return '04d'; // Cloudy
    if (weatherCode == 1009) return '04d'; // Overcast
    if (weatherCode == 1030 || weatherCode == 1135 || weatherCode == 1147) {
      return '50d'; // Fog
    }
    if (weatherCode >= 1063 && weatherCode <= 1201) return '10d'; // Rain
    if (weatherCode >= 1210 && weatherCode <= 1237) return '13d'; // Snow
    if (weatherCode >= 1240 && weatherCode <= 1264) {
      return '13d'; // Snow showers
    }
    if (weatherCode >= 1273 && weatherCode <= 1282) {
      return '11d'; // Thunderstorm
    }
    return '01d';
  }

  // New parsing methods for additional WeatherAPI.com features

  List<WeatherAlert> _parseWeatherAPIAlerts(Map<String, dynamic> data) {
    final alerts = <WeatherAlert>[];

    if (data['alerts'] != null && data['alerts']['alert'] != null) {
      final alertList = data['alerts']['alert'] as List;

      for (final alertData in alertList) {
        alerts.add(
          WeatherAlert(
            id: '${alertData['headline']}_${DateTime.now().millisecondsSinceEpoch}',
            title: alertData['headline'] ?? '',
            description: alertData['desc'] ?? '',
            severity: alertData['severity']?.toLowerCase() ?? 'medium',
            duration: _calculateDuration(
              alertData['effective'],
              alertData['expires'],
            ),
            location: alertData['areas'] ?? '',
            date:
                DateTime.tryParse(alertData['effective'] ?? '') ??
                DateTime.now(),
            icon: _getAlertIcon(alertData['category']),
            type: alertData['event'] ?? 'weather',
            startTime:
                DateTime.tryParse(alertData['effective'] ?? '') ??
                DateTime.now(),
            endTime:
                DateTime.tryParse(alertData['expires'] ?? '') ??
                DateTime.now().add(const Duration(hours: 24)),
            isActive: true,
            recommendations: _generateAlertRecommendations(alertData),
          ),
        );
      }
    }

    return alerts;
  }

  List<Weather> _parseHistoricalWeatherFromWeatherAPI(
    Map<String, dynamic> data,
  ) {
    final weatherList = <Weather>[];

    if (data['forecast'] != null && data['forecast']['forecastday'] != null) {
      final forecastDay = data['forecast']['forecastday'][0];
      final hourly = forecastDay['hour'] as List;

      for (final hour in hourly) {
        weatherList.add(
          Weather(
            id: 'historical_${hour['time_epoch']}',
            dateTime: DateTime.parse(hour['time']),
            temperature: hour['temp_c'].toDouble(),
            humidity: hour['humidity'].toDouble(),
            windSpeed: hour['wind_kph'].toDouble() / 3.6,
            condition: _getWeatherConditionFromCode(hour['condition']['code']),
            description: hour['condition']['text'],
            icon: _getWeatherIconFromCode(hour['condition']['code']),
            pressure: hour['pressure_mb'].toDouble(),
            visibility: hour['vis_km'].toDouble(),
            precipitation: hour['precip_mm']?.toDouble() ?? 0.0,
            uvIndex: hour['uv']?.toDouble(),
            feelsLike: hour['feelslike_c']?.toDouble(),
            dewPoint: hour['dewpoint_c']?.toDouble(),
            windGust: hour['gust_kph']?.toDouble() / 3.6,
            windDegree: hour['wind_degree']?.toInt(),
            windDirection: hour['wind_dir'],
            cloudCover: hour['cloud']?.toDouble(),
            airQuality: hour['air_quality'] != null
                ? AirQuality.fromJson(hour['air_quality'])
                : null,
            pollenData: hour['pollen'] != null
                ? PollenData.fromJson(hour['pollen'])
                : null,
          ),
        );
      }
    }

    return weatherList;
  }

  Map<String, Weather> _parseBulkWeatherData(Map<String, dynamic> data) {
    final weatherMap = <String, Weather>{};

    if (data['bulk'] != null) {
      final bulkList = data['bulk'] as List;

      for (final item in bulkList) {
        final query = item['query'];
        final customId = query['custom_id'] as String;
        final current = query['current'];

        weatherMap[customId] = Weather(
          id: '${customId}_${DateTime.now().millisecondsSinceEpoch}',
          dateTime: DateTime.parse(current['last_updated']),
          temperature: current['temp_c'].toDouble(),
          humidity: current['humidity'].toDouble(),
          windSpeed: current['wind_kph'].toDouble() / 3.6,
          condition: _getWeatherConditionFromCode(current['condition']['code']),
          description: current['condition']['text'],
          icon: _getWeatherIconFromCode(current['condition']['code']),
          pressure: current['pressure_mb'].toDouble(),
          visibility: current['vis_km'].toDouble(),
          precipitation: current['precip_mm']?.toDouble() ?? 0.0,
          uvIndex: current['uv']?.toDouble(),
          feelsLike: current['feelslike_c']?.toDouble(),
          dewPoint: current['dewpoint_c']?.toDouble(),
          windGust: current['gust_kph']?.toDouble() / 3.6,
          windDegree: current['wind_degree']?.toInt(),
          windDirection: current['wind_dir'],
          cloudCover: current['cloud']?.toDouble(),
          airQuality: current['air_quality'] != null
              ? AirQuality.fromJson(current['air_quality'])
              : null,
          pollenData: current['pollen'] != null
              ? PollenData.fromJson(current['pollen'])
              : null,
        );
      }
    }

    return weatherMap;
  }

  // Helper methods for WeatherAlert parsing

  String _calculateDuration(String? effective, String? expires) {
    if (effective == null || expires == null) return 'Unknown';

    try {
      final effectiveDate = DateTime.parse(effective);
      final expiresDate = DateTime.parse(expires);
      final duration = expiresDate.difference(effectiveDate);

      if (duration.inDays > 0) {
        return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
      } else {
        return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAlertIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'met':
        return 'weather';
      case 'fire':
        return 'fire';
      case 'flood':
        return 'water';
      case 'wind':
        return 'wind';
      case 'heat':
        return 'thermometer';
      case 'cold':
        return 'snowflake';
      default:
        return 'warning';
    }
  }

  List<String> _generateAlertRecommendations(Map<String, dynamic> alertData) {
    final category = alertData['category']?.toLowerCase() ?? '';
    final severity = alertData['severity']?.toLowerCase() ?? 'medium';

    List<String> recommendations = [];

    switch (category) {
      case 'met':
        recommendations.addAll([
          'Monitor weather conditions closely',
          'Follow official weather updates',
          'Prepare for changing conditions',
        ]);
        break;
      case 'fire':
        recommendations.addAll([
          'Evacuate if ordered',
          'Avoid outdoor activities',
          'Close windows and doors',
        ]);
        break;
      case 'flood':
        recommendations.addAll([
          'Avoid flooded areas',
          'Move to higher ground if necessary',
          'Do not drive through floodwaters',
        ]);
        break;
      case 'wind':
        recommendations.addAll([
          'Secure loose objects',
          'Avoid outdoor activities if possible',
          'Check for structural damage after the event',
        ]);
        break;
      case 'heat':
        recommendations.addAll([
          'Stay hydrated',
          'Avoid outdoor activities during peak hours',
          'Use sun protection',
        ]);
        break;
      case 'cold':
        recommendations.addAll([
          'Dress warmly in layers',
          'Protect exposed skin',
          'Check heating systems',
        ]);
        break;
      default:
        recommendations.addAll([
          'Monitor local conditions',
          'Follow official guidance',
          'Stay informed about updates',
        ]);
    }

    if (severity == 'extreme' || severity == 'severe') {
      recommendations.insert(
        0,
        'Take immediate action - this is a severe weather event',
      );
    }

    return recommendations;
  }
}
