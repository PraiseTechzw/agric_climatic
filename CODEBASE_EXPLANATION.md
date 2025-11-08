# 🌾 AgriClimatic Codebase - Complete Explanation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Main Application Flow](#main-application-flow)
4. [Frontend (Flutter/Dart)](#frontend-flutterdart)
5. [Backend Integration](#backend-integration)
6. [Data Flow & State Management](#data-flow--state-management)
7. [Key Integrations](#key-integrations)
8. [How Everything Works Together](#how-everything-works-together)

---

## 📱 Project Overview

**AgriClimatic** is a comprehensive Flutter application designed for Zimbabwe's farming community. It provides:
- Real-time weather data and forecasts
- Agricultural climate predictions
- Crop recommendations based on weather patterns
- SMS and push notifications for critical alerts
- Historical weather pattern analysis
- Irrigation scheduling advice

---

## 🏗️ Architecture Overview

### Technology Stack
- **Frontend**: Flutter (Dart)
- **State Management**: Provider pattern
- **Backend Services**:
  - Firebase (Authentication, Firestore, Cloud Messaging)
  - WeatherAPI.com (Weather data)
  - Open-Meteo API (Alternative weather data)
  - Vonage/Infobip (SMS notifications)
  - Firebase AI (Agricultural insights)

### Architecture Pattern
```
┌─────────────────────────────────────────────────────────┐
│                     User Interface                      │
│  (Screens, Widgets)                                     │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              State Management (Providers)               │
│  (AuthProvider, WeatherProvider, AgroClimaticProvider)  │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                   Service Layer                         │
│  (WeatherService, AuthService, NotificationService)     │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Backend Services & APIs                    │
│  (Firebase, WeatherAPI, Open-Meteo, Vonage SMS)        │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Main Application Flow

### 1. Application Initialization (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize environment configuration
  EnvironmentService.initialize();
  
  // 2. Initialize error handling
  ErrorHandlerService.initialize();
  
  // 3. Initialize offline service (local storage)
  await OfflineService.initialize();
  
  // 4. Initialize performance monitoring
  await PerformanceService.initialize();
  
  // 5. Initialize notification service
  await NotificationService.initialize();
  
  // 6. Initialize Firebase AI
  await FirebaseAIService.instance.initialize();
  
  // 7. Initialize Firebase (with fallback)
  await FirebaseConfig.initializeWithFallback();
  
  // 8. Run the app
  runApp(const MyApp());
}
```

**Key Points:**
- Services are initialized in a specific order
- Firebase initialization has a fallback mechanism (works offline)
- All services handle errors gracefully

### 2. App Structure (`MyApp`)

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => AgroClimaticProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        home: const AuthWrapper(), // Entry point
        // ... theme configuration
      ),
    );
  }
}
```

**Key Points:**
- Uses Provider for state management
- Four main providers manage app state
- `AuthWrapper` handles authentication routing

### 3. Authentication Flow (`AuthWrapper`)

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth
        if (authProvider.isLoading) {
          return LoadingScreen();
        }
        
        // Show auth screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return AuthScreen();
        }
        
        // Show main app if authenticated
        return MainScreen();
      },
    );
  }
}
```

**Flow:**
1. Check if user is authenticated
2. Show login/signup if not authenticated
3. Show main app if authenticated
4. Handle anonymous authentication

---

## 🎨 Frontend (Flutter/Dart)

### Screen Structure

#### 1. **Main Screen** (`MainScreen`)
- Bottom navigation with 5 tabs:
  - Dashboard (Climate Dashboard)
  - Alerts (Weather Alerts)
  - Predictions (Enhanced Predictions)
  - Advice (Recommendations)
  - Water (Irrigation Schedule)
- Drawer navigation for additional screens
- Animated transitions between screens

#### 2. **Climate Dashboard Screen**
- Displays current weather
- Historical weather charts
- Weather patterns
- Climate statistics
- Tab-based navigation (Overview, Charts, Patterns, Statistics)

#### 3. **Weather Screens**
- `WeatherScreen`: Current weather display
- `WeatherForecastScreen`: 7-day forecast
- `WeatherAlertsScreen`: Critical weather alerts

#### 4. **Agricultural Screens**
- `EnhancedPredictionsScreen`: Long-term climate predictions
- `RecommendationsScreen`: Crop recommendations
- `IrrigationScheduleScreen`: Water scheduling advice
- `CropRecommendationsScreen`: Crop-specific advice

#### 5. **Analytics & Insights**
- `AnalyticsScreen`: Weather analytics
- `AIInsightsScreen`: AI-powered agricultural insights
- `SupervisorDashboardScreen`: Admin/supervisor view

### Widget Structure

#### Reusable Widgets
- `AgroPredictionCard`: Display predictions
- `AnimatedBackground`: Animated UI backgrounds
- `AuthGuard`: Protect authenticated routes
- `AuthStatusIndicator`: Show auth status
- `BackendStatusWidget`: Show backend connection status
- `CustomTextField`: Custom input fields
- `LoadingButton`: Button with loading state
- `LocationDropdown`: Location selector
- `ModernLoadingWidget`: Modern loading indicators
- `ModernUIComponents`: Reusable UI components

### UI Features
- Material Design 3
- Animated transitions
- Gradient backgrounds
- Modern card-based layouts
- Responsive design
- Dark/Light theme support (configurable)

---

## 🔧 Backend Integration

### 1. Firebase Integration

#### Firebase Services (`firebase_config.dart`)

```dart
class FirebaseConfig {
  static FirebaseFirestore firestore;
  static FirebaseAuth auth;
  static FirebaseMessaging messaging;
  static FirebaseAI firebaseAI;
  
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _messaging = FirebaseMessaging.instance;
    _firebaseAI = FirebaseAI.googleAI();
  }
}
```

**Firebase Collections:**
- `weather_data`: Weather records
- `soil_data`: Soil condition data
- `predictions`: Climate predictions
- `weather_patterns`: Historical patterns
- `weather_alerts`: Weather alerts
- `users`: User profiles

#### Authentication (`auth_service.dart`)

```dart
class AuthService {
  // Sign in with email/password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  // Create user account
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  // Anonymous authentication
  static Future<UserCredential?> signInAnonymously() async {
    return await FirebaseAuth.instance.signInAnonymously();
  }
}
```

**Features:**
- Email/password authentication
- Anonymous authentication
- Email verification
- Password reset
- User profile management

#### Firestore Operations (`firebase_service.dart`)

```dart
class FirebaseService {
  // Save weather data
  static Future<void> saveWeatherData(Weather weather) async {
    await firestore
        .collection('weather_data')
        .doc(weather.id)
        .set(weather.toJson());
  }
  
  // Get weather data
  static Future<List<Weather>> getWeatherData({
    required String location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = firestore
        .collection('weather_data')
        .where('location', isEqualTo: location)
        .orderBy('dateTime', descending: true);
    
    if (startDate != null) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: startDate);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Weather.fromJson(doc.data())).toList();
  }
}
```

**Features:**
- CRUD operations for weather data
- Query with filters (location, date range)
- Real-time listeners
- Batch operations
- Offline persistence

### 2. Weather API Integration

#### WeatherAPI.com Service (`weather_service.dart`)

```dart
class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const String _apiKey = '4360f911bf30467c85c12953251009';
  
  // Get current weather
  Future<Weather> getCurrentWeather({String city = 'Harare'}) async {
    final url = '$_baseUrl/current.json?key=$_apiKey&q=$city&aqi=yes&pollen=yes';
    final response = await NetworkService.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseCurrentWeatherFromWeatherAPI(data, city);
    }
    throw Exception('Failed to fetch weather data');
  }
  
  // Get forecast
  Future<WeatherForecast> getForecast({String city = 'Harare'}) async {
    final url = '$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=7&aqi=yes&alerts=yes&pollen=yes';
    final response = await NetworkService.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseForecastFromWeatherAPI(data);
    }
    throw Exception('Failed to fetch forecast');
  }
}
```

**Features:**
- Current weather data
- 7-day forecast
- Hourly forecast
- Air quality data
- Pollen data
- Weather alerts
- Historical weather

#### Open-Meteo API Service (`zimbabwe_api_service.dart`)

```dart
class ZimbabweApiService {
  static const String _openMeteoForecastUrl = 'https://api.open-meteo.com/v1/forecast';
  
  // Get current weather for Zimbabwe cities
  static Future<Weather> getCurrentWeather(String city) async {
    final coords = _zimbabweCities[city];
    final url = '$_openMeteoForecastUrl?'
        'latitude=${coords['lat']}&'
        'longitude=${coords['lon']}&'
        'current_weather=true&'
        'hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&'
        'timezone=Africa/Harare';
    
    final response = await NetworkService.get(url);
    final data = json.decode(response.body);
    return _parseCurrentWeather(data, city);
  }
}
```

**Zimbabwe Cities Supported:**
- Harare, Bulawayo, Chitungwiza, Mutare, Gweru
- Kwekwe, Kadoma, Masvingo, Chinhoyi, Marondera
- Victoria Falls, Hwange, Gwanda, Bindura

**Features:**
- Free API (no key required)
- Agricultural weather data
- Soil data integration
- Historical weather data
- Crop recommendations

### 3. Agricultural Prediction Service

#### Agro Climatic Service (`agro_climatic_service.dart`)

```dart
class AgroPredictionService {
  // Generate long-term prediction
  Future<AgroClimaticPrediction> generateLongTermPrediction({
    required String location,
    required DateTime startDate,
    required int daysAhead,
  }) async {
    // 1. Get historical data
    final historicalData = await _getHistoricalData(location, startDate);
    
    // 2. Analyze patterns
    final patterns = await _analyzeWeatherPatterns(historicalData);
    
    // 3. Generate prediction
    final prediction = await _generatePrediction(location, startDate, daysAhead, patterns);
    
    // 4. Get crop recommendations
    final cropRecommendation = await _getCropRecommendation(location, prediction);
    
    // 5. Assess risks
    final pestRisk = _assessPestRisk(prediction, cropRecommendation);
    final diseaseRisk = _assessDiseaseRisk(prediction, cropRecommendation);
    
    // 6. Calculate yield prediction
    final yieldPrediction = _calculateYieldPrediction(prediction, cropRecommendation);
    
    // 7. Generate alerts
    final weatherAlerts = _generateWeatherAlerts(prediction);
    
    return AgroClimaticPrediction(
      location: location,
      temperature: prediction['temperature'],
      humidity: prediction['humidity'],
      precipitation: prediction['precipitation'],
      cropRecommendation: cropRecommendation,
      pestRisk: pestRisk,
      diseaseRisk: diseaseRisk,
      yieldPrediction: yieldPrediction,
      weatherAlerts: weatherAlerts,
      // ... more fields
    );
  }
}
```

**Crop Data:**
- Maize, Wheat, Sorghum, Cotton, Tobacco
- Optimal temperature ranges
- Humidity requirements
- Water requirements
- Soil pH preferences
- Growing periods

**Prediction Algorithm:**
1. Analyze historical weather patterns
2. Apply seasonal adjustments
3. Calculate crop suitability scores
4. Assess pest and disease risks
5. Generate irrigation advice
6. Provide planting/harvesting recommendations

### 4. Notification Service

#### Notification Service (`notification_service.dart`)

```dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = ...;
  static final FirebaseMessaging _firebaseMessaging = ...;
  
  // Initialize
  static Future<void> initialize() async {
    // 1. Initialize local notifications
    await _initializeLocalNotifications();
    
    // 2. Initialize Firebase messaging
    await _initializeFirebaseMessaging();
    
    // 3. Request permissions
    await _requestPermissions();
    
    // 4. Initialize SMS service
    await _initializeVonageSMS();
  }
  
  // Send weather alert
  static Future<void> sendWeatherAlert({
    required String title,
    required String message,
    required String severity,
    required String location,
    bool sendSmsIfCritical = false,
  }) async {
    // 1. Send local notification
    await _showLocalNotification(title, message, severity);
    
    // 2. Send Firebase notification
    await _sendFirebaseNotification(title, message);
    
    // 3. Send SMS if critical
    if (sendSmsIfCritical && severity == 'high') {
      await VonageSMSService.sendSMS(message);
    }
  }
}
```

**Notification Types:**
- Weather alerts (temperature, rainfall, wind)
- Agricultural recommendations
- Crop advice
- Irrigation reminders
- Pest/disease warnings

**Channels:**
- Weather Alerts (high priority)
- Agricultural Recommendations (high priority)
- System Notifications (default priority)

### 5. SMS Integration

#### Vonage SMS Service (`vonage_sms_service.dart`)

```dart
class VonageSMSService {
  static String? _apiKey;
  static String? _apiSecret;
  static String? _fromNumber;
  
  static Future<void> initialize({
    required String apiKey,
    required String apiSecret,
    required String fromNumber,
  }) async {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    _fromNumber = fromNumber;
  }
  
  static Future<bool> sendSMS({
    required String to,
    required String message,
  }) async {
    final url = 'https://api.nexmo.com/v0/messages';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'from': _fromNumber,
        'to': to,
        'text': message,
      }),
    );
    
    return response.statusCode == 200;
  }
}
```

**Features:**
- Send SMS via Vonage API
- Critical weather alerts via SMS
- Agricultural recommendations
- User phone number management

---

## 📊 Data Flow & State Management

### State Management with Provider

#### 1. **AuthProvider** (`auth_provider.dart`)

```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Listen to auth state changes
  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  // Sign in
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
```

**State:**
- `_user`: Current authenticated user
- `_isLoading`: Loading state
- `_errorMessage`: Error message

**Methods:**
- `signInWithEmailAndPassword()`: Sign in
- `createUserWithEmailAndPassword()`: Sign up
- `signInAnonymously()`: Anonymous sign in
- `signOut()`: Sign out
- `sendPasswordResetEmail()`: Reset password

#### 2. **WeatherProvider** (`weather_provider.dart`)

```dart
class WeatherProvider extends ChangeNotifier {
  Weather? _currentWeather;
  List<Weather> _hourlyForecast = [];
  List<Weather> _dailyForecast = [];
  List<WeatherAlert> _weatherAlerts = [];
  String _currentLocation = 'Harare';
  bool _isLoading = false;
  
  // Load current weather
  Future<void> loadCurrentWeather() async {
    _setLoading(true);
    try {
      // Try Zimbabwe API first
      _currentWeather = await ZimbabweApiService.getCurrentWeather(_currentLocation);
      
      // Save to Firebase
      await FirebaseService.saveZimbabweWeatherData(_currentWeather!);
      
      // Save to offline storage
      await OfflineStorageService.saveWeatherData(_currentWeather!);
      
      // Trigger notifications
      await _triggerWeatherNotifications(_currentWeather!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Trigger automatic notifications
  Future<void> _triggerWeatherNotifications(Weather weather) async {
    // Temperature alerts
    if (weather.temperature > 35) {
      await NotificationService.sendWeatherAlert(
        title: 'Extreme Heat Warning',
        message: 'Temperature is ${weather.temperature}°C',
        severity: 'high',
        sendSmsIfCritical: true,
      );
    }
    
    // Humidity alerts
    if (weather.humidity > 85) {
      await NotificationService.sendAgroRecommendation(
        title: 'High Humidity Alert',
        message: 'Humidity is ${weather.humidity}%',
        cropType: 'General',
      );
    }
    
    // Rainfall alerts
    if (weather.precipitation > 20) {
      await NotificationService.sendWeatherAlert(
        title: 'Heavy Rainfall Warning',
        message: 'Heavy rainfall expected',
        severity: 'high',
        sendSmsIfCritical: true,
      );
    }
  }
}
```

**State:**
- `_currentWeather`: Current weather data
- `_hourlyForecast`: Hourly forecast
- `_dailyForecast`: Daily forecast
- `_weatherAlerts`: Weather alerts
- `_currentLocation`: Selected location
- `_isLoading`: Loading state

**Methods:**
- `loadCurrentWeather()`: Load current weather
- `loadForecast()`: Load forecast
- `loadWeatherAlerts()`: Load alerts
- `detectLocation()`: Auto-detect location
- `changeLocation()`: Change location
- `refreshAll()`: Refresh all data

#### 3. **AgroClimaticProvider** (`agro_climatic_provider.dart`)

```dart
class AgroClimaticProvider extends ChangeNotifier {
  AgroClimaticPrediction? _currentPrediction;
  List<AgriculturalRecommendation> _recommendations = [];
  bool _isLoading = false;
  
  // Load prediction
  Future<void> loadPrediction() async {
    _setLoading(true);
    try {
      _currentPrediction = await AgroPredictionService.generateLongTermPrediction(
        location: _currentLocation,
        startDate: DateTime.now(),
        daysAhead: 30,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
```

**State:**
- `_currentPrediction`: Current prediction
- `_recommendations`: Crop recommendations
- `_isLoading`: Loading state

**Methods:**
- `loadPrediction()`: Load prediction
- `loadRecommendations()`: Load recommendations
- `refreshAll()`: Refresh all data

### Data Flow Diagram

```
User Action (UI)
    │
    ▼
Provider (State Management)
    │
    ▼
Service Layer (Business Logic)
    │
    ├──► Firebase (Auth, Firestore)
    ├──► WeatherAPI.com (Weather Data)
    ├──► Open-Meteo (Alternative Weather)
    ├──► Vonage SMS (Notifications)
    └──► Offline Storage (Local Cache)
    │
    ▼
Response/Data
    │
    ▼
Provider Updates State
    │
    ▼
UI Updates (Auto-refresh)
```

---

## 🔗 Key Integrations

### 1. Firebase Integration

**Services Used:**
- **Firebase Auth**: User authentication
- **Firestore**: Database for weather data, predictions, user data
- **Firebase Messaging**: Push notifications
- **Firebase AI**: Agricultural insights

**Configuration:**
- `firebase_options.dart`: Platform-specific Firebase config
- `firebase_config.dart`: Firebase service initialization
- `google-services.json`: Android Firebase config

### 2. Weather API Integration

**Primary API: WeatherAPI.com**
- Current weather
- 7-day forecast
- Historical weather
- Air quality
- Pollen data
- Weather alerts

**Fallback API: Open-Meteo**
- Free alternative
- Zimbabwe-specific coordinates
- Agricultural weather data
- Soil data

### 3. SMS Integration

**Vonage SMS Service**
- Send critical weather alerts via SMS
- Agricultural recommendations
- User phone number management

**Configuration:**
- API Key: `5ed1470d`
- API Secret: `XoqTr3O2cuL0vk0l`
- From Number: `Vonage APIs`

### 4. Offline Support

**Offline Storage Service**
- Local caching of weather data
- Offline access to predictions
- Sync when online

**Features:**
- SharedPreferences for simple data
- Local database for complex data
- Automatic sync on connectivity

---

## 🔄 How Everything Works Together

### Complete User Flow Example

#### 1. **User Opens App**

```
User opens app
    │
    ▼
main() initializes services
    │
    ▼
AuthWrapper checks authentication
    │
    ├──► Not authenticated → Show AuthScreen
    └──► Authenticated → Show MainScreen
```

#### 2. **User Authenticates**

```
User enters email/password
    │
    ▼
AuthScreen calls AuthProvider.signInWithEmailAndPassword()
    │
    ▼
AuthProvider calls AuthService.signInWithEmailAndPassword()
    │
    ▼
AuthService calls FirebaseAuth.signInWithEmailAndPassword()
    │
    ▼
Firebase authenticates user
    │
    ▼
AuthProvider updates state (_user = authenticated user)
    │
    ▼
AuthWrapper detects authentication change
    │
    ▼
MainScreen is displayed
```

#### 3. **User Views Weather**

```
MainScreen loads
    │
    ▼
WeatherProvider.refreshAll() is called
    │
    ▼
WeatherProvider.loadCurrentWeather()
    │
    ▼
ZimbabweApiService.getCurrentWeather('Harare')
    │
    ▼
API returns weather data
    │
    ▼
Weather data is parsed into Weather object
    │
    ▼
FirebaseService.saveZimbabweWeatherData() saves to Firestore
    │
    ▼
OfflineStorageService.saveWeatherData() saves locally
    │
    ▼
WeatherProvider._triggerWeatherNotifications() checks conditions
    │
    ├──► Temperature > 35°C → Send heat warning
    ├──► Humidity > 85% → Send humidity alert
    └──► Precipitation > 20mm → Send rainfall warning
    │
    ▼
WeatherProvider updates state (_currentWeather = weather data)
    │
    ▼
UI displays weather data (auto-refresh via Provider)
```

#### 4. **User Requests Prediction**

```
User taps "Predictions" tab
    │
    ▼
EnhancedPredictionsScreen loads
    │
    ▼
AgroClimaticProvider.loadPrediction() is called
    │
    ▼
AgroPredictionService.generateLongTermPrediction()
    │
    ├──► Get historical data from Firestore
    ├──► Analyze weather patterns
    ├──► Generate prediction based on patterns
    ├──► Get crop recommendations
    ├──► Assess pest/disease risks
    ├──► Calculate yield prediction
    └──► Generate weather alerts
    │
    ▼
AgroClimaticPrediction object is created
    │
    ▼
AgroClimaticProvider updates state (_currentPrediction = prediction)
    │
    ▼
UI displays prediction data
```

#### 5. **Critical Weather Alert**

```
Weather condition detected (e.g., temperature > 35°C)
    │
    ▼
WeatherProvider._triggerWeatherNotifications() is called
    │
    ▼
NotificationService.sendWeatherAlert()
    │
    ├──► Send local notification (FlutterLocalNotifications)
    ├──► Send Firebase notification (FirebaseMessaging)
    └──► Send SMS if critical (VonageSMSService)
    │
    ▼
User receives notification
    │
    ├──► Push notification on device
    ├──► SMS message (if critical)
    └──► In-app notification
```

### Integration Points

#### 1. **Authentication → Weather Data**
- User must be authenticated to save personalized data
- User ID is used to associate data with user
- Anonymous users can view public data

#### 2. **Weather Data → Predictions**
- Historical weather data from Firestore is used for predictions
- Current weather data influences predictions
- Weather patterns are analyzed for long-term forecasts

#### 3. **Predictions → Notifications**
- Predictions trigger notifications for critical conditions
- Crop recommendations trigger agricultural alerts
- Irrigation advice triggers water scheduling notifications

#### 4. **Notifications → SMS**
- Critical alerts (temperature, rainfall, wind) trigger SMS
- User phone number is stored in user profile
- SMS is sent via Vonage API

#### 5. **Offline → Online Sync**
- Data is cached locally for offline access
- When online, data is synced with Firebase
- Conflicts are resolved (server data takes precedence)

---

## 📝 Key Files & Their Purposes

### Main Application
- `lib/main.dart`: App entry point, service initialization
- `lib/firebase_options.dart`: Firebase platform configuration

### Services
- `lib/services/auth_service.dart`: Authentication logic
- `lib/services/weather_service.dart`: WeatherAPI.com integration
- `lib/services/zimbabwe_api_service.dart`: Open-Meteo API integration
- `lib/services/firebase_service.dart`: Firestore operations
- `lib/services/agro_climatic_service.dart`: Agricultural predictions
- `lib/services/notification_service.dart`: Notifications (push + SMS)
- `lib/services/vonage_sms_service.dart`: SMS integration
- `lib/services/firebase_config.dart`: Firebase initialization
- `lib/services/environment_service.dart`: Environment configuration

### Providers (State Management)
- `lib/providers/auth_provider.dart`: Authentication state
- `lib/providers/weather_provider.dart`: Weather data state
- `lib/providers/agro_climatic_provider.dart`: Predictions state
- `lib/providers/notification_provider.dart`: Notifications state

### Models
- `lib/models/weather.dart`: Weather data model
- `lib/models/agro_climatic_prediction.dart`: Prediction model
- `lib/models/weather_alert.dart`: Alert model
- `lib/models/soil_data.dart`: Soil data model
- `lib/models/agricultural_recommendation.dart`: Recommendation model

### Screens
- `lib/screens/auth_screen.dart`: Login/signup screen
- `lib/screens/climate_dashboard_screen.dart`: Main dashboard
- `lib/screens/weather_screen.dart`: Current weather
- `lib/screens/enhanced_predictions_screen.dart`: Predictions
- `lib/screens/recommendations_screen.dart`: Crop recommendations
- `lib/screens/irrigation_schedule_screen.dart`: Water scheduling

### Widgets
- `lib/widgets/auth_wrapper.dart`: Authentication routing
- `lib/widgets/auth_guard.dart`: Route protection
- `lib/widgets/agro_prediction_card.dart`: Prediction display
- `lib/widgets/location_dropdown.dart`: Location selector

---

## 🎯 Summary

### Architecture
- **Frontend**: Flutter with Material Design 3
- **State Management**: Provider pattern
- **Backend**: Firebase (Auth, Firestore, Messaging)
- **APIs**: WeatherAPI.com, Open-Meteo, Vonage SMS
- **Offline Support**: Local caching with sync

### Key Features
1. **Real-time Weather Data**: Current weather, forecasts, historical data
2. **Agricultural Predictions**: Long-term climate predictions, crop recommendations
3. **Notifications**: Push notifications and SMS alerts
4. **Offline Support**: Local caching for offline access
5. **User Authentication**: Firebase Auth with anonymous option
6. **Data Persistence**: Firestore for cloud storage

### Data Flow
1. User interacts with UI
2. Provider manages state
3. Service handles business logic
4. API/Backend provides data
5. Data is cached locally
6. UI updates automatically

### Integration Points
- Authentication ↔ Weather Data
- Weather Data ↔ Predictions
- Predictions ↔ Notifications
- Notifications ↔ SMS
- Offline ↔ Online Sync

This architecture provides a robust, scalable, and maintainable solution for agricultural climate prediction and analysis.

