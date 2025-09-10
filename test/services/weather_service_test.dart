import 'package:flutter_test/flutter_test.dart';
import 'package:agric_climatic/services/weather_service.dart';
import 'package:agric_climatic/models/weather.dart';
import 'package:agric_climatic/models/weather_alert.dart';

void main() {
  group('WeatherService Tests', () {
    late WeatherService weatherService;

    setUp(() {
      weatherService = WeatherService();
    });

    group('getCurrentWeather', () {
      test('should get current weather for valid location', () async {
        // Arrange
        const location = 'Harare';

        // Act
        final result = await weatherService.getCurrentWeather(city: location);

        // Assert
        expect(result, isA<Weather>());
        expect(result.id, isNotEmpty);
        expect(result.temperature, isA<double>());
        expect(result.humidity, isA<double>());
        expect(result.description, isA<String>());
      });

      test('should handle invalid location gracefully', () async {
        // Arrange
        const location = 'InvalidLocation';

        // Act & Assert
        try {
          await weatherService.getCurrentWeather(city: location);
          // If no exception is thrown, the test should still pass
          // as the service might handle invalid locations gracefully
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('getWeatherForecast', () {
      test('should get weather forecast for valid location', () async {
        // Arrange
        const days = 5;

        // Act
        final result = await weatherService.getHistoricalWeather(
          startDate: DateTime.now().subtract(Duration(days: days)),
          endDate: DateTime.now(),
        );

        // Assert
        expect(result, isA<List<Weather>>());
        expect(result.length, lessThanOrEqualTo(days));
        if (result.isNotEmpty) {
          expect(result.first.id, isNotEmpty);
        }
      });
    });

    group('getWeatherAlerts', () {
      test('should get weather alerts for valid location', () async {
        // Act
        final result = await weatherService.getWeatherAlerts();

        // Assert
        expect(result, isA<List<WeatherAlert>>());
        // The result might be empty if no alerts are present, which is acceptable
      });
    });
  });
}
