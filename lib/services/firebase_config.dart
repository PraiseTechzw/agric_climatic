import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static bool _isInitialized = false;
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseMessaging? _messaging;
  static FirebaseAI? _firebaseAI;

  // Initialize Firebase
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _messaging = FirebaseMessaging.instance;
      _firebaseAI = FirebaseAI.googleAI();

      // Configure Firestore settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Note: enablePersistence is deprecated in newer versions
      // Offline persistence is enabled by default in newer Firestore versions

      _isInitialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Don't throw exception, just log the error
      // This allows the app to work in offline mode
    }
  }

  // Get Firestore instance
  static FirebaseFirestore get firestore {
    if (!_isInitialized || _firestore == null) {
      // Return a mock instance for offline mode
      throw Exception('Firebase not available - using offline mode');
    }
    return _firestore!;
  }

  // Get Auth instance
  static FirebaseAuth get auth {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase not available - using offline mode');
    }
    return _auth!;
  }

  // Get Messaging instance
  static FirebaseMessaging get messaging {
    if (!_isInitialized || _messaging == null) {
      throw Exception('Firebase not available - using offline mode');
    }
    return _messaging!;
  }

  // Get Firebase AI instance
  static FirebaseAI get firebaseAI {
    if (!_isInitialized || _firebaseAI == null) {
      throw Exception('Firebase AI not available - using offline mode');
    }
    return _firebaseAI!;
  }

  // Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  // Test Firestore connection
  static Future<bool> testConnection() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Try to write a test document
      await _firestore!.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });

      // Try to read it back
      final doc = await _firestore!.collection('test').doc('connection').get();

      if (doc.exists) {
        // Clean up test document
        await _firestore!.collection('test').doc('connection').delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Setup Firestore security rules (for development)
  static Future<void> setupSecurityRules() async {
    try {
      // Note: In production, these rules should be set in Firebase Console
      // This is just for development/testing
      print('Security rules should be configured in Firebase Console');
      print('For development, you can use these rules:');
      print('''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents for authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow public read access to weather data
    match /weather_data/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow public read access to soil data
    match /soil_data/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow public read access to predictions
    match /predictions/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
      ''');
    } catch (e) {
      print('Error setting up security rules: $e');
    }
  }

  // Initialize with error handling
  static Future<void> initializeWithFallback() async {
    try {
      await initialize();
    } catch (e) {
      print('Firebase initialization failed, using offline mode: $e');
      // Continue without Firebase - app will work in offline mode
    }
  }
}
