import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather.dart';
import '../models/weather_alert.dart';

class WeatherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Open-Meteo API configuration for Zimbabwe
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  // Zimbabwe cities coordinates
  final Map<String, Map<String, double>> _zimbabweCities = {
    'Harare': {'lat': -17.8252, 'lon': 31.0335},
    'Bulawayo': {'lat': -20.1569, 'lon': 28.5891},
    'Chitungwiza': {'lat': -18.0128, 'lon': 31.0756},
    'Mutare': {'lat': -18.9707, 'lon': 32.6729},
    'Gweru': {'lat': -19.4500, 'lon': 29.8167},
    'Kwekwe': {'lat': -18.9289, 'lon': 29.8149},
    'Kadoma': {'lat': -18.3333, 'lon': 29.9167},
    'Masvingo': {'lat': -20.0737, 'lon': 30.8278},
    'Chinhoyi': {'lat': -17.3667, 'lon': 30.2000},
    'Marondera': {'lat': -18.1853, 'lon': 31.5519},
    'Bindura': {'lat': -17.3019, 'lon': 31.3306},
    'Beitbridge': {'lat': -22.2167, 'lon': 30.0000},
    'Hwange': {'lat': -18.3667, 'lon': 26.5000},
    'Victoria Falls': {'lat': -17.9243, 'lon': 25.8572},
    'Chipinge': {'lat': -20.2000, 'lon': 32.6167},
    'Rusape': {'lat': -18.5333, 'lon': 32.1167},
    'Chegutu': {'lat': -18.1333, 'lon': 30.1500},
    'Norton': {'lat': -17.8833, 'lon': 30.7000},
    'Redcliff': {'lat': -19.0167, 'lon': 29.7833},
    'Chiredzi': {'lat': -21.0500, 'lon': 31.6667},
  };

  Future<Weather> getCurrentWeather({String city = 'Harare'}) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final url =
          '$_baseUrl/forecast?latitude=${coords['lat']}&longitude=${coords['lon']}&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=Africa/Harare';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCurrentWeatherFromOpenMeteo(data, city);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockWeather(city);
    }
  }

  Future<WeatherForecast> getForecast({String city = 'Harare'}) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final url =
          '$_baseUrl/forecast?latitude=${coords['lat']}&longitude=${coords['lon']}&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=Africa/Harare&forecast_days=7';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseForecastFromOpenMeteo(data);
      } else {
        throw Exception(
            'Failed to fetch forecast data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockForecast();
    }
  }

  Future<List<Weather>> getHistoricalWeather({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('weather_data')
          .select()
          .gte('date_time', startDate.toIso8601String())
          .lte('date_time', endDate.toIso8601String())
          .order('date_time', ascending: true);

      return response.map((json) => Weather.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch historical weather: $e');
    }
  }

  Future<List<WeatherAlert>> getWeatherAlerts() async {
    try {
      final response = await _supabase
          .from('weather_alerts')
          .select()
          .order('date', ascending: false);

      return response.map((json) => WeatherAlert.fromJson(json)).toList();
    } catch (e) {
      // Return mock data if Supabase fails
      return _getMockWeatherAlerts();
    }
  }

  Weather _parseCurrentWeatherFromOpenMeteo(
      Map<String, dynamic> data, String city) {
    final current = data['current_weather'];
    final hourly = data['hourly'];

    return Weather(
      id: '${city}_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.parse(current['time']),
      temperature: current['temperature'].toDouble(),
      humidity: hourly['relative_humidity_2m'][0].toDouble(),
      windSpeed: current['wind_speed'].toDouble(),
      condition: _getWeatherCondition(current['weather_code']),
      description: _getWeatherDescription(current['weather_code']),
      icon: _getWeatherIcon(current['weather_code']),
      pressure: 1013.25, // Open-Meteo doesn't provide pressure in free tier
      visibility: 10.0, // Default visibility
      precipitation: hourly['precipitation'][0]?.toDouble() ?? 0.0,
    );
  }

  WeatherForecast _parseForecastFromOpenMeteo(Map<String, dynamic> data) {
    final hourly = data['hourly'];
    final daily = data['daily'];

    // Parse hourly forecast (next 24 hours)
    final hourlyWeather = <Weather>[];
    final times = hourly['time'] as List;
    final temperatures = hourly['temperature_2m'] as List;
    final humidities = hourly['relative_humidity_2m'] as List;
    final windSpeeds = hourly['wind_speed_10m'] as List;
    final precipitations = hourly['precipitation'] as List;
    final weatherCodes = hourly['weather_code'] as List;

    for (int i = 0; i < 24 && i < times.length; i++) {
      hourlyWeather.add(Weather(
        id: 'hourly_${i}',
        dateTime: DateTime.parse(times[i]),
        temperature: temperatures[i].toDouble(),
        humidity: humidities[i].toDouble(),
        windSpeed: windSpeeds[i].toDouble(),
        condition: _getWeatherCondition(weatherCodes[i]),
        description: _getWeatherDescription(weatherCodes[i]),
        icon: _getWeatherIcon(weatherCodes[i]),
        pressure: 1013.25,
        visibility: 10.0,
        precipitation: precipitations[i]?.toDouble() ?? 0.0,
      ));
    }

    // Parse daily forecast (next 7 days)
    final dailyWeather = <Weather>[];
    final dailyTimes = daily['time'] as List;
    final dailyMaxTemps = daily['temperature_2m_max'] as List;
    final dailyMinTemps = daily['temperature_2m_min'] as List;
    final dailyPrecipitations = daily['precipitation_sum'] as List;
    final dailyWeatherCodes = daily['weather_code'] as List;

    for (int i = 0; i < 7 && i < dailyTimes.length; i++) {
      dailyWeather.add(Weather(
        id: 'daily_${i}',
        dateTime: DateTime.parse(dailyTimes[i]),
        temperature:
            (dailyMaxTemps[i].toDouble() + dailyMinTemps[i].toDouble()) / 2,
        humidity: 60.0, // Default humidity for daily forecast
        windSpeed: 5.0, // Default wind speed
        condition: _getWeatherCondition(dailyWeatherCodes[i]),
        description: _getWeatherDescription(dailyWeatherCodes[i]),
        icon: _getWeatherIcon(dailyWeatherCodes[i]),
        pressure: 1013.25,
        visibility: 10.0,
        precipitation: dailyPrecipitations[i]?.toDouble() ?? 0.0,
      ));
    }

    return WeatherForecast(hourly: hourlyWeather, daily: dailyWeather);
  }

  String _getWeatherCondition(int weatherCode) {
    // Open-Meteo weather codes
    if (weatherCode == 0) return 'clear';
    if (weatherCode <= 3) return 'cloudy';
    if (weatherCode <= 48) return 'foggy';
    if (weatherCode <= 67) return 'rainy';
    if (weatherCode <= 77) return 'snowy';
    if (weatherCode <= 82) return 'rainy';
    if (weatherCode <= 86) return 'snowy';
    if (weatherCode <= 99) return 'stormy';
    return 'clear';
  }

  String _getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode == 1) return 'Mainly clear';
    if (weatherCode == 2) return 'Partly cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 82) return 'Rain showers';
    if (weatherCode <= 86) return 'Snow showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Clear sky';
  }

  String _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return '01d';
    if (weatherCode == 1) return '02d';
    if (weatherCode == 2) return '03d';
    if (weatherCode == 3) return '04d';
    if (weatherCode <= 48) return '50d';
    if (weatherCode <= 67) return '10d';
    if (weatherCode <= 77) return '13d';
    if (weatherCode <= 82) return '09d';
    if (weatherCode <= 86) return '13d';
    if (weatherCode <= 99) return '11d';
    return '01d';
  }

  Weather _getMockWeather(String city) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return Weather(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      temperature: 20 + (random % 15).toDouble(),
      humidity: 60 + (random % 30).toDouble(),
      windSpeed: 5 + (random % 10).toDouble(),
      condition: ['sunny', 'cloudy', 'rainy', 'clear'][random % 4],
      description: [
        'Clear sky',
        'Partly cloudy',
        'Light rain',
        'Sunny'
      ][random % 4],
      icon: ['01d', '02d', '10d', '01d'][random % 4],
      pressure: 1013 + (random % 20).toDouble(),
      visibility: 10 + (random % 5).toDouble(),
      precipitation: (random % 10).toDouble(),
    );
  }

  WeatherForecast _getMockForecast() {
    final hourly = <Weather>[];
    final daily = <Weather>[];

    for (int i = 0; i < 24; i++) {
      hourly.add(_getMockWeather('Harare'));
    }

    for (int i = 0; i < 7; i++) {
      daily.add(_getMockWeather('Harare'));
    }

    return WeatherForecast(hourly: hourly, daily: daily);
  }

  List<WeatherAlert> _getMockWeatherAlerts() {
    return [
      WeatherAlert(
        id: 'alert_1',
        title: 'Heavy Rain Warning',
        description:
            'Heavy rainfall expected in the next 24 hours. Take necessary precautions.',
        severity: 'high',
        duration: '24 hours',
        location: 'Harare District',
        date: DateTime.now(),
        icon: 'rain',
        type: 'rain',
      ),
      WeatherAlert(
        id: 'alert_2',
        title: 'Temperature Alert',
        description: 'High temperatures expected. Ensure proper irrigation.',
        severity: 'medium',
        duration: '48 hours',
        location: 'Mashonaland East',
        date: DateTime.now().add(const Duration(days: 1)),
        icon: 'drought',
        type: 'drought',
      ),
    ];
  }
}
