import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';

class WeatherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Weather> getCurrentWeather() async {
    try {
      final response = await _supabase
          .from('weather_data')
          .select()
          .eq('type', 'current')
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return Weather.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch current weather: $e');
    }
  }

  Future<WeatherForecast> getForecast() async {
    try {
      final hourlyResponse = await _supabase
          .from('weather_data')
          .select()
          .eq('type', 'hourly')
          .order('date_time', ascending: true)
          .limit(24);

      final dailyResponse = await _supabase
          .from('weather_data')
          .select()
          .eq('type', 'daily')
          .order('date_time', ascending: true)
          .limit(7);

      return WeatherForecast(
        hourly: hourlyResponse.map((json) => Weather.fromJson(json)).toList(),
        daily: dailyResponse.map((json) => Weather.fromJson(json)).toList(),
      );
    } catch (e) {
      throw Exception('Failed to fetch forecast: $e');
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
          .order('created_at', ascending: false)
          .limit(10);

      return response.map((json) => WeatherAlert.fromJson(json)).toList();
    } catch (e) {
      // Return mock data for demo purposes
      return _getMockWeatherAlerts();
    }
  }

  List<WeatherAlert> _getMockWeatherAlerts() {
    return [
      WeatherAlert(
        id: '1',
        title: 'Severe Thunderstorm Warning',
        description:
            'Heavy rainfall and strong winds expected in your area. Potential for flooding in low-lying areas.',
        severity: 'HIGH',
        duration: '2h',
        location: 'Harare District',
        date: DateTime.now(),
        icon: 'thunderstorm',
        type: 'thunderstorm',
      ),
      WeatherAlert(
        id: '2',
        title: 'Extended Dry Period Forecast',
        description:
            'Below-average rainfall expected for the next 2 weeks. Consider water conservation measures.',
        severity: 'MEDIUM',
        duration: '1d',
        location: 'Mashonaland East',
        date: DateTime.now().add(const Duration(days: 1)),
        icon: 'drought',
        type: 'drought',
      ),
    ];
  }
}
