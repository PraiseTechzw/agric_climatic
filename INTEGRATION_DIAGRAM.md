# 🔗 AgriClimatic Integration Diagram

## Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Screens    │  │   Widgets    │  │  Navigation  │            │
│  │              │  │              │  │              │            │
│  │ - Dashboard  │  │ - Cards      │  │ - Bottom Nav │            │
│  │ - Weather    │  │ - Charts     │  │ - Drawer     │            │
│  │ - Predictions│  │ - Forms      │  │ - Routes     │            │
│  │ - Alerts     │  │ - Buttons    │  │              │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                               │ User Actions & State Updates
                               │
┌──────────────────────────────▼─────────────────────────────────────┐
│                    STATE MANAGEMENT (Provider)                     │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │ AuthProvider   │  │WeatherProvider │  │AgroClimatic    │     │
│  │                │  │                │  │Provider        │     │
│  │ - User State   │  │ - Weather Data │  │ - Predictions  │     │
│  │ - Auth Status  │  │ - Forecasts    │  │ - Recommendations│   │
│  │ - Error State  │  │ - Alerts       │  │ - Analytics    │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│  ┌────────────────┐                                               │
│  │Notification    │                                               │
│  │Provider        │                                               │
│  │ - Notifications│                                               │
│  │ - SMS Status   │                                               │
│  └────────────────┘                                               │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                               │ Service Calls
                               │
┌──────────────────────────────▼─────────────────────────────────────┐
│                        SERVICE LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │AuthService   │  │WeatherService│  │AgroPrediction│            │
│  │              │  │              │  │Service       │            │
│  │ - Sign In    │  │ - Current    │  │ - Predictions│            │
│  │ - Sign Up    │  │ - Forecast   │  │ - Crop Recs  │            │
│  │ - Sign Out   │  │ - Historical │  │ - Risk Assess│            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │Notification  │  │Firebase      │  │Zimbabwe      │            │
│  │Service       │  │Service       │  │ApiService    │            │
│  │ - Push       │  │ - Firestore  │  │ - Open-Meteo │            │
│  │ - SMS        │  │ - Auth       │  │ - Soil Data  │            │
│  │ - Local      │  │ - Messaging  │  │ - Crop Data  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
                               │ API Calls & Data Operations
                               │
┌──────────────────────────────▼─────────────────────────────────────┐
│                    BACKEND SERVICES & APIS                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  Firebase    │  │ WeatherAPI   │  │  Open-Meteo  │            │
│  │              │  │   .com       │  │     API      │            │
│  │ - Auth       │  │ - Current    │  │ - Free API   │            │
│  │ - Firestore  │  │ - Forecast   │  │ - Historical │            │
│  │ - Messaging  │  │ - Alerts     │  │ - Soil Data  │            │
│  │ - AI         │  │ - Air Quality│  │ - Crop Data  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │  Vonage SMS  │  │  Offline     │                              │
│  │   Service    │  │  Storage     │                              │
│  │ - SMS API    │  │ - Local Cache│                              │
│  │ - Alerts     │  │ - Sync       │                              │
│  └──────────────┘  └──────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow Example: Weather Data Fetching

```
1. USER ACTION
   └─► User opens Weather Screen
       │
       ▼
2. PROVIDER
   └─► WeatherProvider.loadCurrentWeather()
       │
       ▼
3. SERVICE LAYER
   └─► ZimbabweApiService.getCurrentWeather('Harare')
       │
       ├─► Check NetworkService.hasInternetConnection()
       │   │
       │   ├─► Online: Continue
       │   └─► Offline: Load from cache
       │
       ▼
4. API CALL
   └─► GET https://api.open-meteo.com/v1/forecast
       │   ?latitude=-17.8252
       │   &longitude=31.0335
       │   &current_weather=true
       │   &timezone=Africa/Harare
       │
       ▼
5. DATA PARSING
   └─► Parse JSON response
       │
       ├─► Extract temperature
       ├─► Extract humidity
       ├─► Extract precipitation
       ├─► Extract wind speed
       └─► Create Weather object
       │
       ▼
6. DATA PERSISTENCE
   ├─► FirebaseService.saveZimbabweWeatherData()
   │   └─► Save to Firestore 'weather_data' collection
   │
   └─► OfflineStorageService.saveWeatherData()
       └─► Save to local cache
       │
       ▼
7. NOTIFICATION TRIGGER
   └─► WeatherProvider._triggerWeatherNotifications()
       │
       ├─► Check temperature
       │   ├─► > 35°C → Send heat warning
       │   └─► < 5°C → Send frost alert
       │
       ├─► Check humidity
       │   ├─► > 85% → Send high humidity alert
       │   └─► < 30% → Send low humidity alert
       │
       └─► Check precipitation
           ├─► > 20mm → Send heavy rainfall warning
           └─► 0mm (dry season) → Send irrigation reminder
       │
       ▼
8. NOTIFICATION SERVICE
   └─► NotificationService.sendWeatherAlert()
       │
       ├─► Local Notification (FlutterLocalNotifications)
       ├─► Firebase Notification (FirebaseMessaging)
       └─► SMS Notification (VonageSMSService) [if critical]
       │
       ▼
9. STATE UPDATE
   └─► WeatherProvider updates state
       │
       ├─► _currentWeather = weather data
       ├─► _isLoading = false
       └─► notifyListeners()
       │
       ▼
10. UI UPDATE
    └─► Screen rebuilds automatically
        │
        └─► Display weather data to user
```

## Authentication Flow

```
1. USER ACTION
   └─► User enters email/password
       │
       ▼
2. UI LAYER
   └─► AuthScreen calls AuthProvider.signInWithEmailAndPassword()
       │
       ▼
3. PROVIDER
   └─► AuthProvider.signInWithEmailAndPassword()
       │
       ├─► Set _isLoading = true
       ├─► Clear _errorMessage
       └─► Call AuthService.signInWithEmailAndPassword()
       │
       ▼
4. SERVICE LAYER
   └─► AuthService.signInWithEmailAndPassword()
       │
       └─► FirebaseAuth.instance.signInWithEmailAndPassword()
           │
           ▼
5. FIREBASE AUTH
   └─► Firebase authenticates user
       │
       ├─► Success: Returns UserCredential
       └─► Error: Throws FirebaseAuthException
       │
       ▼
6. RESPONSE HANDLING
   ├─► Success:
   │   ├─► AuthProvider._user = credential.user
   │   ├─► AuthProvider._isLoading = false
   │   └─► AuthProvider.notifyListeners()
   │
   └─► Error:
       ├─► AuthProvider._errorMessage = error message
       ├─► AuthProvider._isLoading = false
       └─► AuthProvider.notifyListeners()
       │
       ▼
7. UI UPDATE
   └─► AuthWrapper listens to AuthProvider
       │
       ├─► If authenticated: Show MainScreen
       └─► If not authenticated: Show AuthScreen
```

## Prediction Generation Flow

```
1. USER ACTION
   └─► User opens Predictions screen
       │
       ▼
2. PROVIDER
   └─► AgroClimaticProvider.loadPrediction()
       │
       ▼
3. SERVICE LAYER
   └─► AgroPredictionService.generateLongTermPrediction()
       │
       ├─► Step 1: Get Historical Data
       │   └─► FirebaseService.getWeatherData()
       │       └─► Query Firestore for past 365 days
       │
       ├─► Step 2: Analyze Patterns
       │   └─► _analyzeWeatherPatterns()
       │       ├─► Filter by season
       │       ├─► Calculate averages
       │       ├─► Detect anomalies
       │       └─► Calculate trends
       │
       ├─► Step 3: Generate Prediction
       │   └─► _generatePrediction()
       │       ├─► Apply seasonal adjustments
       │       ├─► Add daily variation
       │       └─► Calculate evapotranspiration
       │
       ├─► Step 4: Get Crop Recommendations
       │   └─► _getCropRecommendation()
       │       ├─► Score crops based on conditions
       │       ├─► Check temperature suitability
       │       ├─► Check humidity suitability
       │       └─► Return best crop
       │
       ├─► Step 5: Assess Risks
       │   ├─► _assessPestRisk()
       │   └─► _assessDiseaseRisk()
       │
       ├─► Step 6: Calculate Yield
       │   └─► _calculateYieldPrediction()
       │       ├─► Base yield: 70%
       │       ├─► Temperature impact: ±20%
       │       ├─► Humidity impact: ±10%
       │       └─► Precipitation impact: ±15%
       │
       └─► Step 7: Generate Alerts
           └─► _generateWeatherAlerts()
               ├─► Temperature warnings
               ├─► Humidity alerts
               └─► Precipitation warnings
       │
       ▼
4. CREATE PREDICTION OBJECT
   └─► AgroClimaticPrediction(
       ├─► location: 'Harare'
       ├─► temperature: 25.5°C
       ├─► humidity: 65%
       ├─► precipitation: 5mm
       ├─► cropRecommendation: 'maize'
       ├─► pestRisk: 'medium'
       ├─► diseaseRisk: 'low'
       ├─► yieldPrediction: 85%
       └─► weatherAlerts: [...]
       )
       │
       ▼
5. STATE UPDATE
   └─► AgroClimaticProvider updates state
       │
       ├─► _currentPrediction = prediction
       ├─► _isLoading = false
       └─► notifyListeners()
       │
       ▼
6. UI UPDATE
   └─► Screen displays prediction data
       │
       ├─► Temperature chart
       ├─► Crop recommendations
       ├─► Risk assessments
       └─► Weather alerts
```

## Notification Flow

```
1. TRIGGER EVENT
   └─► Weather condition detected (e.g., temperature > 35°C)
       │
       ▼
2. WEATHER PROVIDER
   └─► WeatherProvider._triggerWeatherNotifications()
       │
       └─► _checkTemperatureAlerts(weather)
           │
           ├─► if temp > 35°C:
           │   └─► NotificationService.sendWeatherAlert(
           │       ├─► title: 'Extreme Heat Warning'
           │       ├─► message: 'Temperature is 35°C...'
           │       ├─► severity: 'high'
           │       └─► sendSmsIfCritical: true
           │       )
           │
           └─► if temp < 5°C:
               └─► NotificationService.sendWeatherAlert(
                   ├─► title: 'Frost Risk Alert'
                   ├─► message: 'Temperature is 5°C...'
                   ├─► severity: 'high'
                   └─► sendSmsIfCritical: true
                   )
       │
       ▼
3. NOTIFICATION SERVICE
   └─► NotificationService.sendWeatherAlert()
       │
       ├─► Local Notification
       │   └─► FlutterLocalNotificationsPlugin.show()
       │       ├─► Create AndroidNotificationDetails
       │       ├─► Set channel ID: 'weather_alerts'
       │       ├─► Set priority: high
       │       └─► Show notification
       │
       ├─► Firebase Notification
       │   └─► FirebaseMessaging.send()
       │       ├─► Get user FCM token
       │       ├─► Send to Firebase Cloud Messaging
       │       └─► Device receives push notification
       │
       └─► SMS Notification (if critical)
           └─► VonageSMSService.sendSMS()
               ├─► Get user phone number from profile
               ├─► Call Vonage API
               │   └─► POST https://api.nexmo.com/v0/messages
               │       ├─► Headers: Authorization (Basic Auth)
               │       ├─► Body: {from, to, text}
               │       └─► Response: 200 OK
               └─► SMS sent to user
       │
       ▼
4. USER RECEIVES NOTIFICATION
   └─► Multiple channels:
       │
       ├─► Local notification appears on device
       ├─► Push notification from Firebase
       └─► SMS message (if critical)
```

## Integration Summary

### Frontend ↔ Backend Integration Points

1. **Authentication**
   - Frontend: `AuthScreen` → `AuthProvider` → `AuthService` → `FirebaseAuth`
   - Backend: Firebase Authentication

2. **Weather Data**
   - Frontend: `WeatherScreen` → `WeatherProvider` → `WeatherService` → `ZimbabweApiService`
   - Backend: Open-Meteo API / WeatherAPI.com

3. **Predictions**
   - Frontend: `PredictionsScreen` → `AgroClimaticProvider` → `AgroPredictionService`
   - Backend: Firebase Firestore (historical data) + Algorithm

4. **Notifications**
   - Frontend: `NotificationProvider` → `NotificationService`
   - Backend: Firebase Messaging + Vonage SMS

5. **Data Persistence**
   - Frontend: Services → `FirebaseService` → `OfflineStorageService`
   - Backend: Firebase Firestore + Local Storage

### Key Integration Patterns

1. **Provider Pattern**: State management with automatic UI updates
2. **Service Layer**: Business logic separation from UI
3. **Repository Pattern**: Data access abstraction
4. **Observer Pattern**: Real-time data updates
5. **Strategy Pattern**: Multiple API fallbacks

### Error Handling

- Network errors: Fallback to cached data
- API errors: Try alternative API
- Firebase errors: Continue in offline mode
- Notification errors: Log but don't block app

### Offline Support

- Local caching of weather data
- Offline access to predictions
- Automatic sync when online
- Conflict resolution (server wins)

