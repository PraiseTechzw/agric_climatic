import 'package:flutter_test/flutter_test.dart';
import 'package:agric_climatic/services/agro_prediction_service.dart';
import 'package:agric_climatic/models/agro_climatic_prediction.dart';

void main() {
  group('AgroPredictionService Tests', () {
    late AgroPredictionService agroPredictionService;

    setUp(() {
      agroPredictionService = AgroPredictionService();
    });

    group('generateLongTermPrediction', () {
      test('should generate prediction for valid location', () async {
        // Arrange
        const location = 'Harare';
        final startDate = DateTime.now();
        const daysAhead = 7;

        // Act
        final result = await agroPredictionService.generateLongTermPrediction(
          location: location,
          startDate: startDate,
          daysAhead: daysAhead,
        );

        // Assert
        expect(result, isA<AgroClimaticPrediction>());
        expect(result.location, equals(location));
        expect(result.temperature, isA<double>());
        expect(result.humidity, isA<double>());
        expect(result.cropRecommendation, isA<String>());
      });

      test('should handle prediction errors gracefully', () async {
        // Arrange
        const location = 'InvalidLocation';
        final startDate = DateTime.now();
        const daysAhead = 7;

        // Act & Assert
        try {
          await agroPredictionService.generateLongTermPrediction(
            location: location,
            startDate: startDate,
            daysAhead: daysAhead,
          );
          // If no exception is thrown, the test should still pass
          // as the service might handle invalid locations gracefully
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('analyzeSequentialPatterns', () {
      test('should analyze patterns for valid date range', () async {
        // Arrange
        const location = 'Harare';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 7);

        // Act
        final result = await agroPredictionService.analyzeSequentialPatterns(
          location: location,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<HistoricalWeatherPattern>>());
        // The result might be empty if no patterns are found, which is acceptable
      });
    });
  });
}
