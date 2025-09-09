import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agric_climatic/services/offline_service.dart';

void main() {
  group('OfflineService Tests', () {
    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    group('Cache Management', () {
      test('should cache and retrieve weather data', () async {
        // Arrange
        final testData = {
          'temperature': 25.0,
          'humidity': 60.0,
          'condition': 'clear',
        };

        // Act
        await OfflineService.cacheWeatherData(testData);
        final retrievedData = await OfflineService.getCachedWeatherData();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['temperature'], equals(25.0));
        expect(retrievedData['humidity'], equals(60.0));
        expect(retrievedData['condition'], equals('clear'));
      });

      test('should cache and retrieve soil data', () async {
        // Arrange
        final testData = {
          'moisture': 50.0,
          'ph': 6.5,
          'nutrients': 'good',
        };

        // Act
        await OfflineService.cacheSoilData(testData);
        final retrievedData = await OfflineService.getCachedSoilData();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['moisture'], equals(50.0));
        expect(retrievedData['ph'], equals(6.5));
        expect(retrievedData['nutrients'], equals('good'));
      });

      test('should cache and retrieve predictions', () async {
        // Arrange
        final testData = {
          'crop_recommendation': 'maize',
          'yield_prediction': 80.0,
          'irrigation_advice': 'No irrigation needed',
        };

        // Act
        await OfflineService.cachePredictions(testData);
        final retrievedData = await OfflineService.getCachedPredictions();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['crop_recommendation'], equals('maize'));
        expect(retrievedData['yield_prediction'], equals(80.0));
        expect(retrievedData['irrigation_advice'], equals('No irrigation needed'));
      });

      test('should cache and retrieve alerts', () async {
        // Arrange
        final testData = {
          'alerts': ['High temperature warning', 'Drought conditions'],
          'severity': 'high',
        };

        // Act
        await OfflineService.cacheAlerts(testData);
        final retrievedData = await OfflineService.getCachedAlerts();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['alerts'], isA<List>());
        expect(retrievedData['severity'], equals('high'));
      });

      test('should cache and retrieve user data', () async {
        // Arrange
        final testData = {
          'preferences': {'notifications': true, 'location': 'Harare'},
          'settings': {'theme': 'light', 'language': 'en'},
        };

        // Act
        await OfflineService.cacheUserData(testData);
        final retrievedData = await OfflineService.getCachedUserData();

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['preferences'], isA<Map>());
        expect(retrievedData['settings'], isA<Map>());
      });
    });

    group('Sync Management', () {
      test('should set and get last sync time', () async {
        // Arrange
        final testTime = DateTime.now();

        // Act
        await OfflineService.setLastSync(testTime);
        final retrievedTime = await OfflineService.getLastSync();

        // Assert
        expect(retrievedTime, isNotNull);
        expect(retrievedTime!.millisecondsSinceEpoch, equals(testTime.millisecondsSinceEpoch));
      });

      test('should determine if sync is needed', () async {
        // Arrange
        final oldTime = DateTime.now().subtract(const Duration(hours: 2));
        await OfflineService.setLastSync(oldTime);

        // Act
        final needsSync = await OfflineService.needsSync();

        // Assert
        expect(needsSync, isTrue);
      });

      test('should not need sync if recent', () async {
        // Arrange
        final recentTime = DateTime.now().subtract(const Duration(minutes: 30));
        await OfflineService.setLastSync(recentTime);

        // Act
        final needsSync = await OfflineService.needsSync();

        // Assert
        expect(needsSync, isFalse);
      });
    });

    group('Offline Data Management', () {
      test('should save and retrieve offline data', () async {
        // Arrange
        const key = 'test_offline_data';
        final testData = {
          'action': 'weather_update',
          'data': {'temperature': 25.0, 'humidity': 60.0},
        };

        // Act
        await OfflineService.saveOfflineData(key, testData);
        final retrievedData = await OfflineService.getOfflineData(key);

        // Assert
        expect(retrievedData, isNotNull);
        expect(retrievedData!['action'], equals('weather_update'));
        expect(retrievedData['data'], isA<Map>());
      });

      test('should queue offline actions', () async {
        // Arrange
        const action = 'weather_update';
        final data = {'temperature': 25.0, 'humidity': 60.0};

        // Act
        await OfflineService.queueOfflineAction(action, data);
        final queue = await OfflineService.getOfflineQueue();

        // Assert
        expect(queue, isNotEmpty);
        expect(queue.first['action'], equals(action));
        expect(queue.first['data'], equals(data));
      });

      test('should clear offline queue', () async {
        // Arrange
        const action = 'weather_update';
        final data = {'temperature': 25.0, 'humidity': 60.0};
        await OfflineService.queueOfflineAction(action, data);

        // Act
        await OfflineService.clearOfflineQueue();
        final queue = await OfflineService.getOfflineQueue();

        // Assert
        expect(queue, isEmpty);
      });
    });

    group('Cache Clearing', () {
      test('should clear all cache', () async {
        // Arrange
        await OfflineService.cacheWeatherData({'test': 'data'});
        await OfflineService.cacheSoilData({'test': 'data'});
        await OfflineService.cachePredictions({'test': 'data'});

        // Act
        await OfflineService.clearCache();

        // Assert
        final weatherData = await OfflineService.getCachedWeatherData();
        final soilData = await OfflineService.getCachedSoilData();
        final predictions = await OfflineService.getCachedPredictions();

        expect(weatherData, isNull);
        expect(soilData, isNull);
        expect(predictions, isNull);
      });

      test('should clear offline data', () async {
        // Arrange
        await OfflineService.saveOfflineData('test_key', {'test': 'data'});

        // Act
        await OfflineService.clearOfflineData();

        // Assert
        final offlineData = await OfflineService.getOfflineData('test_key');
        expect(offlineData, isNull);
      });
    });
  });
}
