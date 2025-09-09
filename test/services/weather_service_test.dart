import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:agric_climatic/services/weather_service.dart';
import 'package:agric_climatic/models/weather.dart';

import 'weather_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('WeatherService Tests', () {
    late WeatherService weatherService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      weatherService = WeatherService();
    });

    group('getCurrentWeather', () {
      test('should return weather data for valid city', () async {
        // Arrange
        const city = 'Harare';
        final mockResponse = {
          'current_weather': {
            'time': '2024-01-01T12:00:00Z',
            'temperature': 25.0,
            'wind_speed': 5.0,
            'weather_code': 0,
          },
          'hourly': {
            'relative_humidity_2m': [60.0],
            'precipitation': [0.0],
          },
        };

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(json.encode(mockResponse), 200),
        );

        // Act
        final result = await weatherService.getCurrentWeather(city: city);

        // Assert
        expect(result, isA<Weather>());
        expect(result.temperature, equals(25.0));
        expect(result.humidity, equals(60.0));
        expect(result.windSpeed, equals(5.0));
        expect(result.condition, equals('clear'));
      });

      test('should throw exception for invalid city', () async {
        // Arrange
        const city = 'InvalidCity';

        // Act & Assert
        expect(
          () => weatherService.getCurrentWeather(city: city),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle API errors', () async {
        // Arrange
        const city = 'Harare';
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Error', 500),
        );

        // Act & Assert
        expect(
          () => weatherService.getCurrentWeather(city: city),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getForecast', () {
      test('should return forecast data for valid city', () async {
        // Arrange
        const city = 'Harare';
        final mockResponse = {
          'hourly': {
            'time': ['2024-01-01T12:00:00Z', '2024-01-01T13:00:00Z'],
            'temperature_2m': [25.0, 26.0],
            'relative_humidity_2m': [60.0, 65.0],
            'wind_speed_10m': [5.0, 6.0],
            'precipitation': [0.0, 0.0],
            'weather_code': [0, 1],
          },
          'daily': {
            'time': ['2024-01-01'],
            'temperature_2m_max': [30.0],
            'temperature_2m_min': [20.0],
            'precipitation_sum': [0.0],
            'weather_code': [0],
          },
        };

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(json.encode(mockResponse), 200),
        );

        // Act
        final result = await weatherService.getForecast(city: city);

        // Assert
        expect(result, isA<WeatherForecast>());
        expect(result.hourly.length, equals(2));
        expect(result.daily.length, equals(1));
      });
    });

    group('getHistoricalWeather', () {
      test('should return historical weather data', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 7);

        // Act
        final result = await weatherService.getHistoricalWeather(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<Weather>>());
      });
    });

    group('getWeatherAlerts', () {
      test('should return weather alerts', () async {
        // Act
        final result = await weatherService.getWeatherAlerts();

        // Assert
        expect(result, isA<List<WeatherAlert>>());
      });
    });
  });
}
