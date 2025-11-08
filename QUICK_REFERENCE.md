# 🚀 AgriClimatic - Quick Reference Guide

## 📱 Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
│   ├── weather.dart
│   ├── agro_climatic_prediction.dart
│   └── ...
├── providers/                   # State management
│   ├── auth_provider.dart
│   ├── weather_provider.dart
│   └── ...
├── services/                    # Business logic
│   ├── auth_service.dart
│   ├── weather_service.dart
│   ├── firebase_service.dart
│   └── ...
├── screens/                     # UI screens
│   ├── auth_screen.dart
│   ├── climate_dashboard_screen.dart
│   └── ...
└── widgets/                     # Reusable widgets
    ├── auth_wrapper.dart
    ├── agro_prediction_card.dart
    └── ...
```

## 🔑 Key Components

### 1. Main Application (`main.dart`)
- Initializes all services
- Sets up Provider state management
- Configures Firebase
- Handles error handling and logging

### 2. Authentication System
- **Service**: `AuthService` (Firebase Auth)
- **Provider**: `AuthProvider` (State management)
- **Screen**: `AuthScreen` (UI)
- **Features**: Email/password, anonymous auth, password reset

### 3. Weather System
- **Service**: `WeatherService` (WeatherAPI.com), `ZimbabweApiService` (Open-Meteo)
- **Provider**: `WeatherProvider` (State management)
- **Screen**: `WeatherScreen`, `WeatherForecastScreen`
- **Features**: Current weather, forecasts, historical data, alerts

### 4. Prediction System
- **Service**: `AgroPredictionService` (Algorithm)
- **Provider**: `AgroClimaticProvider` (State management)
- **Screen**: `EnhancedPredictionsScreen`
- **Features**: Long-term predictions, crop recommendations, risk assessment

### 5. Notification System
- **Service**: `NotificationService` (Push + SMS)
- **Provider**: `NotificationProvider` (State management)
- **Features**: Push notifications, SMS alerts, local notifications

## 🔄 Data Flow

```
User Action → Provider → Service → API/Backend → Response → Provider → UI Update
```

## 🗄️ Backend Services

### Firebase
- **Auth**: User authentication
- **Firestore**: Database (weather_data, predictions, users)
- **Messaging**: Push notifications
- **AI**: Agricultural insights

### APIs
- **WeatherAPI.com**: Primary weather data source
- **Open-Meteo**: Fallback weather data (free)
- **Vonage SMS**: SMS notifications

### Local Storage
- **SharedPreferences**: Simple key-value storage
- **Offline Storage**: Cached weather data and predictions

## 📊 State Management

### Providers
1. **AuthProvider**: Authentication state
2. **WeatherProvider**: Weather data state
3. **AgroClimaticProvider**: Predictions state
4. **NotificationProvider**: Notifications state

### How It Works
- Providers extend `ChangeNotifier`
- `notifyListeners()` triggers UI updates
- `Consumer<Provider>` widgets rebuild on changes

## 🔌 Integration Points

### 1. Authentication ↔ Weather
- User must be authenticated to save personalized data
- User ID associates data with user

### 2. Weather ↔ Predictions
- Historical weather data used for predictions
- Current weather influences predictions

### 3. Predictions ↔ Notifications
- Predictions trigger notifications for critical conditions
- Crop recommendations trigger agricultural alerts

### 4. Notifications ↔ SMS
- Critical alerts trigger SMS
- User phone number stored in profile

### 5. Offline ↔ Online
- Data cached locally for offline access
- Automatic sync when online

## 🎯 Key Features

### Weather Features
- ✅ Current weather for Zimbabwe cities
- ✅ 7-day weather forecast
- ✅ Hourly weather forecast
- ✅ Historical weather data
- ✅ Weather alerts and warnings
- ✅ Air quality data
- ✅ Pollen data

### Agricultural Features
- ✅ Long-term climate predictions
- ✅ Crop recommendations
- ✅ Pest and disease risk assessment
- ✅ Yield predictions
- ✅ Irrigation scheduling advice
- ✅ Planting/harvesting recommendations

### Notification Features
- ✅ Push notifications
- ✅ SMS alerts (critical conditions)
- ✅ Local notifications
- ✅ Weather alerts
- ✅ Agricultural recommendations

### User Features
- ✅ User authentication
- ✅ Anonymous authentication
- ✅ User profiles
- ✅ Location preferences
- ✅ Notification preferences

## 🛠️ Key Services

### AuthService
```dart
- signInWithEmailAndPassword()
- createUserWithEmailAndPassword()
- signInAnonymously()
- signOut()
- sendPasswordResetEmail()
```

### WeatherService
```dart
- getCurrentWeather()
- getForecast()
- getWeatherAlerts()
- getHistoricalWeather()
```

### AgroPredictionService
```dart
- generateLongTermPrediction()
- analyzeSequentialPatterns()
- getCropRecommendation()
```

### NotificationService
```dart
- sendWeatherAlert()
- sendAgroRecommendation()
- sendSMS()
- initialize()
```

### FirebaseService
```dart
- saveWeatherData()
- getWeatherData()
- savePrediction()
- getPredictions()
```

## 📱 Screens

### Main Screens
1. **AuthScreen**: Login/signup
2. **MainScreen**: Main app with bottom navigation
3. **ClimateDashboardScreen**: Main dashboard
4. **WeatherScreen**: Current weather
5. **EnhancedPredictionsScreen**: Predictions
6. **RecommendationsScreen**: Crop recommendations
7. **IrrigationScheduleScreen**: Water scheduling

### Secondary Screens
- WeatherForecastScreen
- WeatherAlertsScreen
- AnalyticsScreen
- AIInsightsScreen
- SupervisorDashboardScreen
- HelpScreen

## 🔐 Configuration

### Environment Variables
- Firebase project ID
- WeatherAPI.com API key
- Vonage SMS API key/secret
- Open-Meteo API (no key required)

### Firebase Configuration
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `firebase_options.dart` (Generated)

## 🚀 Getting Started

### 1. Initialize Services
```dart
await EnvironmentService.initialize();
await FirebaseConfig.initializeWithFallback();
await NotificationService.initialize();
```

### 2. Set Up Providers
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
    // ...
  ],
)
```

### 3. Use Providers in UI
```dart
Consumer<WeatherProvider>(
  builder: (context, provider, child) {
    return Text(provider.currentWeather?.temperature.toString() ?? 'Loading...');
  },
)
```

## 📝 Common Patterns

### Loading State
```dart
if (provider.isLoading) {
  return CircularProgressIndicator();
}
```

### Error Handling
```dart
if (provider.error != null) {
  return Text('Error: ${provider.error}');
}
```

### Data Display
```dart
provider.currentWeather != null
  ? WeatherCard(weather: provider.currentWeather!)
  : Text('No data available')
```

## 🐛 Troubleshooting

### Firebase Not Initialized
- Check `google-services.json` is in `android/app/`
- Verify Firebase project configuration
- Check internet connection

### Weather Data Not Loading
- Check API key is valid
- Verify network connection
- Check location is valid
- Try fallback API (Open-Meteo)

### Notifications Not Working
- Check notification permissions
- Verify Firebase Messaging setup
- Check SMS service configuration

### Predictions Not Generating
- Check Firebase connection
- Verify historical data exists
- Check location is set

## 📚 Additional Resources

- **Detailed Explanation**: `CODEBASE_EXPLANATION.md`
- **Integration Diagrams**: `INTEGRATION_DIAGRAM.md`
- **Firebase Setup**: `FIREBASE_SETUP.md`
- **Production Deployment**: `PRODUCTION_DEPLOYMENT.md`

## 🎓 Key Concepts

### Provider Pattern
- State management solution
- Automatic UI updates
- Reactive programming

### Service Layer
- Business logic separation
- API abstraction
- Error handling

### Repository Pattern
- Data access abstraction
- Multiple data sources
- Caching strategy

### Observer Pattern
- Real-time updates
- Event-driven architecture
- Decoupled components

## 🔍 Quick Debugging

### Check Auth State
```dart
final authProvider = Provider.of<AuthProvider>(context);
print('Authenticated: ${authProvider.isAuthenticated}');
print('User: ${authProvider.user?.email}');
```

### Check Weather State
```dart
final weatherProvider = Provider.of<WeatherProvider>(context);
print('Current Weather: ${weatherProvider.currentWeather?.temperature}');
print('Location: ${weatherProvider.currentLocation}');
```

### Check Firebase Connection
```dart
final isConnected = await FirebaseConfig.testConnection();
print('Firebase Connected: $isConnected');
```

### Check Notification Status
```dart
final notificationProvider = Provider.of<NotificationProvider>(context);
print('Notifications Enabled: ${notificationProvider.notificationsEnabled}');
```

## 💡 Tips

1. **Always check loading state** before displaying data
2. **Handle errors gracefully** with user-friendly messages
3. **Use offline caching** for better user experience
4. **Test with different network conditions**
5. **Monitor Firebase usage** to avoid quota limits
6. **Use environment variables** for API keys
7. **Implement proper error logging** for debugging
8. **Test notifications** on physical devices
9. **Validate user input** before API calls
10. **Use Provider efficiently** to avoid unnecessary rebuilds

