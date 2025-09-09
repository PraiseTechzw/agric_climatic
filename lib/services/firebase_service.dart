import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weather.dart';
import '../models/soil_data.dart';
import '../models/agro_climatic_prediction.dart';
import 'firebase_config.dart';

class FirebaseService {
  static FirebaseFirestore get _firestore => FirebaseConfig.firestore;
  static FirebaseAuth get _auth => FirebaseConfig.auth;

  // Collections
  static const String _weatherCollection = 'weather_data';
  static const String _soilCollection = 'soil_data';
  static const String _predictionsCollection = 'predictions';
  static const String _patternsCollection = 'weather_patterns';
  static const String _alertsCollection = 'weather_alerts';
  static const String _usersCollection = 'users';

  // Weather Data Operations
  static Future<void> saveWeatherData(Weather weather) async {
    try {
      if (!FirebaseConfig.isInitialized) {
        print('Firebase not initialized, skipping save');
        return;
      }

      await _firestore
          .collection(_weatherCollection)
          .doc(weather.id)
          .set(weather.toJson());
    } catch (e) {
      print('Failed to save weather data: $e');
      // Don't throw exception, just log the error
    }
  }

  static Future<List<Weather>> getWeatherData({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      if (!FirebaseConfig.isInitialized) {
        print('Firebase not initialized, returning empty list');
        return [];
      }

      Query query = _firestore
          .collection(_weatherCollection)
          .where('location', isEqualTo: location)
          .orderBy('dateTime', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('dateTime', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('dateTime', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Weather.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to get weather data: $e');
      return [];
    }
  }

  // Soil Data Operations
  static Future<void> saveSoilData(SoilData soilData) async {
    try {
      await _firestore
          .collection(_soilCollection)
          .doc(soilData.id)
          .set(soilData.toJson());
    } catch (e) {
      throw Exception('Failed to save soil data: $e');
    }
  }

  static Future<SoilData?> getLatestSoilData(String location) async {
    try {
      final snapshot = await _firestore
          .collection(_soilCollection)
          .where('location', isEqualTo: location)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SoilData.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get soil data: $e');
    }
  }

  // Predictions Operations
  static Future<void> savePrediction(AgroClimaticPrediction prediction) async {
    try {
      await _firestore
          .collection(_predictionsCollection)
          .doc(prediction.id)
          .set(prediction.toJson());
    } catch (e) {
      throw Exception('Failed to save prediction: $e');
    }
  }

  static Future<List<AgroClimaticPrediction>> getPredictions({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      Query query = _firestore
          .collection(_predictionsCollection)
          .where('location', isEqualTo: location)
          .orderBy('date', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => AgroClimaticPrediction.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get predictions: $e');
    }
  }

  // Weather Patterns Operations
  static Future<void> saveWeatherPattern(
    HistoricalWeatherPattern pattern,
  ) async {
    try {
      await _firestore
          .collection(_patternsCollection)
          .doc(pattern.id)
          .set(pattern.toJson());
    } catch (e) {
      throw Exception('Failed to save weather pattern: $e');
    }
  }

  static Future<List<HistoricalWeatherPattern>> getWeatherPatterns({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_patternsCollection)
          .where('location', isEqualTo: location)
          .orderBy('startDate', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('startDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('endDate', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => HistoricalWeatherPattern.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get weather patterns: $e');
    }
  }

  // Weather Alerts Operations
  static Future<void> saveWeatherAlert(Map<String, dynamic> alert) async {
    try {
      await _firestore.collection(_alertsCollection).add(alert);
    } catch (e) {
      throw Exception('Failed to save weather alert: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWeatherAlerts({
    required String location,
    DateTime? startDate,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_alertsCollection)
          .where('location', isEqualTo: location)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get weather alerts: $e');
    }
  }

  // User Data Operations
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .get();
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Batch Operations for better performance
  static Future<void> batchSaveWeatherData(List<Weather> weatherList) async {
    try {
      final batch = _firestore.batch();

      for (final weather in weatherList) {
        final docRef = _firestore
            .collection(_weatherCollection)
            .doc(weather.id);
        batch.set(docRef, weather.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch save weather data: $e');
    }
  }

  // Real-time listeners
  static Stream<List<Weather>> getWeatherDataStream({
    required String location,
    int limit = 50,
  }) {
    return _firestore
        .collection(_weatherCollection)
        .where('location', isEqualTo: location)
        .orderBy('dateTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Weather.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> getWeatherAlertsStream({
    required String location,
    int limit = 10,
  }) {
    return _firestore
        .collection(_alertsCollection)
        .where('location', isEqualTo: location)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  // Data cleanup operations
  static Future<void> cleanupOldData({
    required String collection,
    required DateTime cutoffDate,
  }) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(collection)
          .where('dateTime', isLessThan: cutoffDate)
          .limit(500)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old data: $e');
    }
  }

  // Zimbabwe-specific data operations
  static Future<void> saveZimbabweWeatherData(Weather weather) async {
    try {
      // Add Zimbabwe-specific metadata
      final zimbabweData = {
        ...weather.toJson(),
        'country': 'Zimbabwe',
        'region': _getZimbabweRegion(
          weather.id,
        ), // Using id as location identifier
        'province': _getZimbabweProvince(weather.id),
      };

      await _firestore
          .collection(_weatherCollection)
          .doc(weather.id)
          .set(zimbabweData);
    } catch (e) {
      throw Exception('Failed to save Zimbabwe weather data: $e');
    }
  }

  static String _getZimbabweRegion(String location) {
    // Map locations to Zimbabwe regions
    final locationLower = location.toLowerCase();
    if (locationLower.contains('harare') ||
        locationLower.contains('mashonaland east')) {
      return 'Mashonaland East';
    } else if (locationLower.contains('bulawayo') ||
        locationLower.contains('matabeleland')) {
      return 'Matabeleland';
    } else if (locationLower.contains('masvingo')) {
      return 'Masvingo';
    } else if (locationLower.contains('manicaland')) {
      return 'Manicaland';
    } else if (locationLower.contains('mashonaland west')) {
      return 'Mashonaland West';
    } else if (locationLower.contains('mashonaland central')) {
      return 'Mashonaland Central';
    } else if (locationLower.contains('midlands')) {
      return 'Midlands';
    }
    return 'Unknown';
  }

  static String _getZimbabweProvince(String location) {
    // Map locations to Zimbabwe provinces
    final locationLower = location.toLowerCase();
    if (locationLower.contains('harare')) {
      return 'Harare';
    } else if (locationLower.contains('bulawayo')) {
      return 'Bulawayo';
    } else if (locationLower.contains('masvingo')) {
      return 'Masvingo';
    } else if (locationLower.contains('mutare') ||
        locationLower.contains('manicaland')) {
      return 'Manicaland';
    } else if (locationLower.contains('gweru') ||
        locationLower.contains('midlands')) {
      return 'Midlands';
    } else if (locationLower.contains('kwekwe')) {
      return 'Midlands';
    } else if (locationLower.contains('gokwe')) {
      return 'Midlands';
    } else if (locationLower.contains('kadoma') ||
        locationLower.contains('mashonaland west')) {
      return 'Mashonaland West';
    } else if (locationLower.contains('chinhoyi')) {
      return 'Mashonaland West';
    } else if (locationLower.contains('bindura') ||
        locationLower.contains('mashonaland central')) {
      return 'Mashonaland Central';
    } else if (locationLower.contains('marondera') ||
        locationLower.contains('mashonaland east')) {
      return 'Mashonaland East';
    } else if (locationLower.contains('chitungwiza')) {
      return 'Mashonaland East';
    } else if (locationLower.contains('victoria falls') ||
        locationLower.contains('hwange') ||
        locationLower.contains('matabeleland north')) {
      return 'Matabeleland North';
    } else if (locationLower.contains('gwanda') ||
        locationLower.contains('matabeleland south')) {
      return 'Matabeleland South';
    }
    return 'Unknown';
  }
}
