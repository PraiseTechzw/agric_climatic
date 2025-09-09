import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../models/soil_data.dart';

class ZimbabweApiService {
  // Open-Meteo API for weather data (free, no API key required)
  static const String _openMeteoBaseUrl =
      'https://archive-api.open-meteo.com/v1/archive';

  // OpenWeatherMap API (free tier available) - for future use
  // static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  // static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';

  // Zimbabwe-specific coordinates for major cities
  static const Map<String, Map<String, double>> _zimbabweCities = {
    'Harare': {'lat': -17.8252, 'lon': 31.0335},
    'Bulawayo': {'lat': -20.1569, 'lon': 28.5891},
    'Chitungwiza': {'lat': -18.0128, 'lon': 31.0756},
    'Mutare': {'lat': -18.9707, 'lon': 32.6722},
    'Gweru': {'lat': -19.4500, 'lon': 29.8167},
    'Kwekwe': {'lat': -18.9283, 'lon': 29.8149},
    'Kadoma': {'lat': -18.3333, 'lon': 29.9167},
    'Masvingo': {'lat': -20.0744, 'lon': 30.8328},
    'Chinhoyi': {'lat': -17.3667, 'lon': 30.2000},
    'Bindura': {'lat': -17.3019, 'lon': 31.3306},
    'Marondera': {'lat': -18.1853, 'lon': 31.5519},
    'Victoria Falls': {'lat': -17.9243, 'lon': 25.8572},
    'Hwange': {'lat': -18.3644, 'lon': 26.4981},
    'Gwanda': {'lat': -20.9333, 'lon': 29.0000},
  };

  // Get current weather for Zimbabwe cities
  static Future<Weather> getCurrentWeather(String city) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final response = await http.get(
        Uri.parse(
          '$_openMeteoBaseUrl/forecast?'
          'latitude=${coords['lat']}&'
          'longitude=${coords['lon']}&'
          'current_weather=true&'
          'hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&'
          'timezone=Africa/Harare',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCurrentWeather(data, city);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting current weather: $e');
    }
  }

  // Get weather forecast for Zimbabwe cities
  static Future<List<Weather>> getWeatherForecast(String city, int days) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final response = await http.get(
        Uri.parse(
          '$_openMeteoBaseUrl/forecast?'
          'latitude=${coords['lat']}&'
          'longitude=${coords['lon']}&'
          'hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&'
          'forecast_days=$days&'
          'timezone=Africa/Harare',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseForecastData(data, city);
      } else {
        throw Exception(
          'Failed to fetch forecast data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting weather forecast: $e');
    }
  }

  // Get historical weather data for Zimbabwe
  static Future<List<Weather>> getHistoricalWeather(
    String city,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final response = await http.get(
        Uri.parse(
          '$_openMeteoBaseUrl/forecast?'
          'latitude=${coords['lat']}&'
          'longitude=${coords['lon']}&'
          'hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&'
          'start_date=${_formatDate(startDate)}&'
          'end_date=${_formatDate(endDate)}&'
          'timezone=Africa/Harare',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseForecastData(data, city);
      } else {
        throw Exception(
          'Failed to fetch historical data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting historical weather: $e');
    }
  }

  // Get agricultural weather data (temperature, humidity, precipitation)
  static Future<Map<String, dynamic>> getAgriculturalWeatherData(
    String city,
  ) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      final response = await http.get(
        Uri.parse(
          '$_openMeteoBaseUrl/forecast?'
          'latitude=${coords['lat']}&'
          'longitude=${coords['lon']}&'
          'hourly=temperature_2m,relative_humidity_2m,precipitation,soil_temperature_0cm,soil_moisture_0_1cm&'
          'daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_hours&'
          'forecast_days=7&'
          'timezone=Africa/Harare',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseAgriculturalData(data, city);
      } else {
        throw Exception(
          'Failed to fetch agricultural data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting agricultural weather data: $e');
    }
  }

  // Get soil data for Zimbabwe regions
  static Future<SoilData> getZimbabweSoilData(String city) async {
    try {
      final coords = _zimbabweCities[city];
      if (coords == null) {
        throw Exception('City not found: $city');
      }

      // Use Open-Meteo soil data API for real soil information
      final response = await http.get(
        Uri.parse(
          '$_openMeteoBaseUrl/forecast?'
          'latitude=${coords['lat']}&'
          'longitude=${coords['lon']}&'
          'hourly=soil_temperature_0cm,soil_moisture_0_1cm&'
          'daily=soil_temperature_0cm_max,soil_temperature_0cm_min&'
          'timezone=Africa/Harare',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSoilDataFromOpenMeteo(
          data,
          city,
          coords['lat']!,
          coords['lon']!,
        );
      } else {
        throw Exception('Failed to fetch soil data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting soil data: $e');
    }
  }

  // Get crop recommendations for Zimbabwe
  static Future<List<String>> getZimbabweCropRecommendations(
    String city,
    String season,
    Map<String, dynamic> weatherData,
  ) async {
    try {
      final recommendations = <String>[];
      final temperature = weatherData['temperature'] as double? ?? 25.0;
      final precipitation = weatherData['precipitation'] as double? ?? 0.0;
      final humidity = weatherData['humidity'] as double? ?? 60.0;

      // Zimbabwe-specific crop recommendations based on season and weather
      if (season.toLowerCase() == 'summer' || season.toLowerCase() == 'rainy') {
        if (temperature > 25 && precipitation > 50) {
          recommendations.addAll([
            'Maize - Optimal planting time',
            'Sorghum - Drought-resistant alternative',
            'Groundnuts - Good for sandy soils',
            'Sunflower - High-value crop',
          ]);
        } else if (temperature > 30) {
          recommendations.addAll([
            'Cotton - Heat tolerant',
            'Sugarcane - Requires irrigation',
            'Tobacco - High-value export crop',
          ]);
        }
      } else if (season.toLowerCase() == 'winter' ||
          season.toLowerCase() == 'dry') {
        if (temperature < 20) {
          recommendations.addAll([
            'Wheat - Winter crop',
            'Barley - Cold tolerant',
            'Vegetables - Short season crops',
          ]);
        } else {
          recommendations.addAll([
            'Irrigated crops - Maize, vegetables',
            'Drought-resistant crops - Sorghum, millet',
          ]);
        }
      }

      // Add general recommendations based on weather
      if (precipitation < 20) {
        recommendations.add('Consider drought-resistant varieties');
        recommendations.add('Implement water conservation techniques');
      }
      if (humidity > 80) {
        recommendations.add('Watch for fungal diseases');
        recommendations.add('Ensure good air circulation');
      }

      return recommendations;
    } catch (e) {
      throw Exception('Error getting crop recommendations: $e');
    }
  }

  // Parse current weather data
  static Weather _parseCurrentWeather(Map<String, dynamic> data, String city) {
    final current = data['current_weather'] as Map<String, dynamic>;
    // final hourly = data['hourly'] as Map<String, dynamic>; // Not used in current implementation

    return Weather(
      id: '${city}_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.parse(current['time'] as String),
      temperature: (current['temperature'] as num).toDouble(),
      humidity: 60.0, // Default value, not available in current_weather
      precipitation: 0.0, // Default value
      windSpeed: (current['windspeed'] as num).toDouble(),
      condition: _getWeatherDescription(current['weathercode'] as int),
      description: _getWeatherDescription(current['weathercode'] as int),
      icon: _getWeatherIcon(current['weathercode'] as int),
      pressure: 1013.25, // Default value
      visibility: 10.0, // Default value
    );
  }

  // Parse forecast data
  static List<Weather> _parseForecastData(
    Map<String, dynamic> data,
    String city,
  ) {
    final hourly = data['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    final temperatures = hourly['temperature_2m'] as List<dynamic>;
    final humidities = hourly['relative_humidity_2m'] as List<dynamic>;
    final precipitations = hourly['precipitation'] as List<dynamic>;
    final windSpeeds = hourly['wind_speed_10m'] as List<dynamic>;

    final weatherList = <Weather>[];

    for (int i = 0; i < times.length; i++) {
      weatherList.add(
        Weather(
          id: '${city}_${DateTime.parse(times[i] as String).millisecondsSinceEpoch}',
          dateTime: DateTime.parse(times[i] as String),
          temperature: (temperatures[i] as num).toDouble(),
          humidity: (humidities[i] as num).toDouble(),
          precipitation: (precipitations[i] as num).toDouble(),
          windSpeed: (windSpeeds[i] as num).toDouble(),
          condition: _getWeatherDescriptionFromTemp(
            (temperatures[i] as num).toDouble(),
          ),
          description: _getWeatherDescriptionFromTemp(
            (temperatures[i] as num).toDouble(),
          ),
          icon: _getWeatherIconFromTemp((temperatures[i] as num).toDouble()),
          pressure: 1013.25,
          visibility: 10.0,
        ),
      );
    }

    return weatherList;
  }

  // Parse agricultural data
  static Map<String, dynamic> _parseAgriculturalData(
    Map<String, dynamic> data,
    String city,
  ) {
    final hourly = data['hourly'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;

    return {
      'city': city,
      'temperature': _calculateAverage(
        hourly['temperature_2m'] as List<dynamic>,
      ),
      'humidity': _calculateAverage(
        hourly['relative_humidity_2m'] as List<dynamic>,
      ),
      'precipitation': _calculateSum(hourly['precipitation'] as List<dynamic>),
      'soil_temperature': _calculateAverage(
        hourly['soil_temperature_0cm'] as List<dynamic>,
      ),
      'soil_moisture': _calculateAverage(
        hourly['soil_moisture_0_1cm'] as List<dynamic>,
      ),
      'max_temperature': _calculateMax(
        daily['temperature_2m_max'] as List<dynamic>,
      ),
      'min_temperature': _calculateMin(
        daily['temperature_2m_min'] as List<dynamic>,
      ),
      'total_precipitation': _calculateSum(
        daily['precipitation_sum'] as List<dynamic>,
      ),
      'precipitation_hours': _calculateSum(
        daily['precipitation_hours'] as List<dynamic>,
      ),
    };
  }

  // Parse soil data from Open-Meteo API
  static SoilData _parseSoilDataFromOpenMeteo(
    Map<String, dynamic> data,
    String city,
    double lat,
    double lon,
  ) {
    final hourly = data['hourly'] as Map<String, dynamic>;

    // Get current soil temperature and moisture
    final soilTemps = hourly['soil_temperature_0cm'] as List<dynamic>;
    final soilMoistures = hourly['soil_moisture_0_1cm'] as List<dynamic>;

    final currentSoilTemp = soilTemps.isNotEmpty
        ? soilTemps[0].toDouble()
        : 22.0;
    final currentSoilMoisture = soilMoistures.isNotEmpty
        ? soilMoistures[0].toDouble()
        : 50.0;

    // Get region-specific characteristics
    final region = _getZimbabweRegion(city);

    return SoilData(
      id: '${city}_soil_${DateTime.now().millisecondsSinceEpoch}',
      location: city,
      ph: _getZimbabweSoilPH(region),
      organicMatter: _getZimbabweOrganicMatter(region),
      nitrogen: _getZimbabweNitrogen(region),
      phosphorus: _getZimbabwePhosphorus(region),
      potassium: _getZimbabwePotassium(region),
      soilMoisture: currentSoilMoisture,
      soilTemperature: currentSoilTemp,
      soilType: _getZimbabweSoilType(region),
      drainage: _getZimbabweDrainage(region),
      texture: _getZimbabweTexture(region),
      lastUpdated: DateTime.now(),
    );
  }

  // Helper methods for Zimbabwe soil characteristics
  static String _getZimbabweRegion(String city) {
    if (['Harare', 'Chitungwiza', 'Marondera', 'Bindura'].contains(city)) {
      return 'Mashonaland';
    } else if ([
      'Bulawayo',
      'Victoria Falls',
      'Hwange',
      'Gwanda',
    ].contains(city)) {
      return 'Matabeleland';
    } else if (['Mutare'].contains(city)) {
      return 'Manicaland';
    } else if (['Gweru', 'Kwekwe', 'Kadoma'].contains(city)) {
      return 'Midlands';
    } else if (['Masvingo'].contains(city)) {
      return 'Masvingo';
    }
    return 'Unknown';
  }

  static String _getZimbabweSoilType(String region) {
    switch (region) {
      case 'Mashonaland':
        return 'Red clay loam';
      case 'Matabeleland':
        return 'Sandy loam';
      case 'Manicaland':
        return 'Clay loam';
      case 'Midlands':
        return 'Sandy clay loam';
      case 'Masvingo':
        return 'Red sandy loam';
      default:
        return 'Mixed soil';
    }
  }

  static double _getZimbabweSoilPH(String region) {
    switch (region) {
      case 'Mashonaland':
        return 6.2;
      case 'Matabeleland':
        return 7.1;
      case 'Manicaland':
        return 6.8;
      case 'Midlands':
        return 6.5;
      case 'Masvingo':
        return 6.9;
      default:
        return 6.5;
    }
  }

  static double _getZimbabweOrganicMatter(String region) {
    switch (region) {
      case 'Mashonaland':
        return 3.2;
      case 'Matabeleland':
        return 2.1;
      case 'Manicaland':
        return 2.8;
      case 'Midlands':
        return 2.5;
      case 'Masvingo':
        return 2.3;
      default:
        return 2.5;
    }
  }

  static double _getZimbabweNitrogen(String region) {
    switch (region) {
      case 'Mashonaland':
        return 45.0;
      case 'Matabeleland':
        return 35.0;
      case 'Manicaland':
        return 40.0;
      case 'Midlands':
        return 38.0;
      case 'Masvingo':
        return 36.0;
      default:
        return 40.0;
    }
  }

  static double _getZimbabwePhosphorus(String region) {
    switch (region) {
      case 'Mashonaland':
        return 28.0;
      case 'Matabeleland':
        return 22.0;
      case 'Manicaland':
        return 25.0;
      case 'Midlands':
        return 24.0;
      case 'Masvingo':
        return 23.0;
      default:
        return 25.0;
    }
  }

  static double _getZimbabwePotassium(String region) {
    switch (region) {
      case 'Mashonaland':
        return 180.0;
      case 'Matabeleland':
        return 160.0;
      case 'Manicaland':
        return 170.0;
      case 'Midlands':
        return 165.0;
      case 'Masvingo':
        return 162.0;
      default:
        return 170.0;
    }
  }

  static String _getZimbabweDrainage(String region) {
    switch (region) {
      case 'Mashonaland':
        return 'Good';
      case 'Matabeleland':
        return 'Moderate';
      case 'Manicaland':
        return 'Good';
      case 'Midlands':
        return 'Moderate';
      case 'Masvingo':
        return 'Moderate';
      default:
        return 'Moderate';
    }
  }

  static String _getZimbabweTexture(String region) {
    switch (region) {
      case 'Mashonaland':
        return 'Medium';
      case 'Matabeleland':
        return 'Coarse';
      case 'Manicaland':
        return 'Medium';
      case 'Midlands':
        return 'Medium';
      case 'Masvingo':
        return 'Medium';
      default:
        return 'Medium';
    }
  }

  // Utility methods
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  static String _getWeatherDescriptionFromTemp(double temp) {
    if (temp > 30) return 'Hot';
    if (temp > 25) return 'Warm';
    if (temp > 15) return 'Mild';
    if (temp > 5) return 'Cool';
    return 'Cold';
  }

  static String _getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return '01d'; // Clear sky
      case 1:
      case 2:
      case 3:
        return '02d'; // Partly cloudy
      case 45:
      case 48:
        return '50d'; // Fog
      case 51:
      case 53:
      case 55:
        return '09d'; // Drizzle
      case 61:
      case 63:
      case 65:
        return '10d'; // Rain
      case 71:
      case 73:
      case 75:
        return '13d'; // Snow
      case 80:
      case 81:
      case 82:
        return '09d'; // Rain showers
      case 85:
      case 86:
        return '13d'; // Snow showers
      case 95:
        return '11d'; // Thunderstorm
      case 96:
      case 99:
        return '11d'; // Thunderstorm with hail
      default:
        return '01d'; // Default clear sky
    }
  }

  static String _getWeatherIconFromTemp(double temp) {
    if (temp > 30) return '01d'; // Hot - clear sky
    if (temp > 25) return '02d'; // Warm - partly cloudy
    if (temp > 15) return '03d'; // Mild - scattered clouds
    if (temp > 5) return '04d'; // Cool - broken clouds
    return '13d'; // Cold - snow
  }

  static double _calculateAverage(List<dynamic> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold(
      0.0,
      (sum, value) => sum + (value as num).toDouble(),
    );
    return sum / values.length;
  }

  static double _calculateSum(List<dynamic> values) {
    if (values.isEmpty) return 0.0;
    return values.fold(0.0, (sum, value) => sum + (value as num).toDouble());
  }

  static double _calculateMax(List<dynamic> values) {
    if (values.isEmpty) return 0.0;
    return values.fold(
      0.0,
      (max, value) => value.toDouble() > max ? value.toDouble() : max,
    );
  }

  static double _calculateMin(List<dynamic> values) {
    if (values.isEmpty) return 0.0;
    return values.fold(
      double.infinity,
      (min, value) => value.toDouble() < min ? value.toDouble() : min,
    );
  }
}
