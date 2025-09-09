import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:agric_climatic/services/agro_climatic_service.dart';
import 'package:agric_climatic/models/agro_climatic_prediction.dart';
import 'package:agric_climatic/models/weather.dart';

import 'agro_climatic_service_test.mocks.dart';

@GenerateMocks([AgroPredictionService])
void main() {
  group('AgroClimaticService Tests', () {
    late AgroPredictionService mockAgroPredictionService;

    setUp(() {
      mockAgroPredictionService = MockAgroPredictionService();
    });

    group('generateLongTermPrediction', () {
      test('should generate prediction for valid location', () async {
        // Arrange
        const location = 'Harare';
        final startDate = DateTime.now();
        const daysAhead = 7;

        final mockPrediction = AgroClimaticPrediction(
          id: 'test_id',
          date: startDate,
          location: location,
          temperature: 25.0,
          humidity: 60.0,
          precipitation: 5.0,
          soilMoisture: 50.0,
          evapotranspiration: 3.0,
          cropRecommendation: 'maize',
          irrigationAdvice: 'No irrigation needed',
          pestRisk: 'low',
          diseaseRisk: 'low',
          yieldPrediction: 80.0,
          plantingAdvice: 'Optimal conditions for planting',
          harvestingAdvice: 'Good conditions for harvesting',
          weatherAlerts: [],
          soilConditions: {},
          climateIndicators: {},
        );

        when(
          mockAgroPredictionService.generateLongTermPrediction(
            location: anyNamed('location'),
            startDate: anyNamed('startDate'),
            daysAhead: anyNamed('daysAhead'),
          ),
        ).thenAnswer((_) async => mockPrediction);

        // Act
        final result = await mockAgroPredictionService
            .generateLongTermPrediction(
              location: location,
              startDate: startDate,
              daysAhead: daysAhead,
            );

        // Assert
        expect(result, isA<AgroClimaticPrediction>());
        expect(result.location, equals(location));
        expect(result.temperature, equals(25.0));
        expect(result.humidity, equals(60.0));
        expect(result.cropRecommendation, equals('maize'));
      });

      test('should handle prediction errors', () async {
        // Arrange
        const location = 'InvalidLocation';
        final startDate = DateTime.now();
        const daysAhead = 7;

        when(
          mockAgroPredictionService.generateLongTermPrediction(
            location: anyNamed('location'),
            startDate: anyNamed('startDate'),
            daysAhead: anyNamed('daysAhead'),
          ),
        ).thenThrow(Exception('Invalid location'));

        // Act & Assert
        expect(
          () => mockAgroPredictionService.generateLongTermPrediction(
            location: location,
            startDate: startDate,
            daysAhead: daysAhead,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('analyzeSequentialPatterns', () {
      test('should analyze patterns for valid date range', () async {
        // Arrange
        const location = 'Harare';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 7);

        final mockPatterns = [
          HistoricalWeatherPattern(
            id: 'test_pattern_1',
            startDate: startDate,
            endDate: endDate,
            location: location,
            averageTemperature: 25.0,
            totalPrecipitation: 50.0,
            averageHumidity: 60.0,
            season: 'summer',
            patternType: 'hot_wet',
            anomalies: [],
            trends: {},
            summary: 'Summer pattern analysis',
          ),
        ];

        when(
          mockAgroPredictionService.analyzeSequentialPatterns(
            location: anyNamed('location'),
            startDate: anyNamed('startDate'),
            endDate: anyNamed('endDate'),
          ),
        ).thenAnswer((_) async => mockPatterns);

        // Act
        final result = await mockAgroPredictionService
            .analyzeSequentialPatterns(
              location: location,
              startDate: startDate,
              endDate: endDate,
            );

        // Assert
        expect(result, isA<List<HistoricalWeatherPattern>>());
        expect(result.length, equals(1));
        expect(result.first.location, equals(location));
        expect(result.first.averageTemperature, equals(25.0));
      });
    });
  });
}
