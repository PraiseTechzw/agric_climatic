# AgriClimatic - Production Deployment Guide

## Overview
AgriClimatic is a Zimbabwe Agricultural Climate Prediction App built with Flutter. This guide covers the steps needed to deploy the app to production.

## Prerequisites
- Flutter SDK 3.9.0 or higher
- Android Studio / Xcode for platform-specific builds
- Firebase project configured
- Supabase project configured
- Google Play Console account (for Android)
- Apple Developer account (for iOS)

## Environment Configuration

### 1. Firebase Configuration
1. Create a Firebase project at https://console.firebase.google.com
2. Enable the following services:
   - Authentication
   - Firestore Database
   - Cloud Messaging
   - Firebase AI
3. Download the configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

### 2. Supabase Configuration
1. Create a Supabase project at https://supabase.com
2. Set up the following tables:
   - `weather_data`
   - `soil_data`
   - `predictions`
   - `weather_alerts`
   - `user_data`
   - `analytics`
3. Configure Row Level Security (RLS) policies
4. Update the Supabase URL and API key in `lib/services/environment_service.dart`

### 3. API Keys
- Open-Meteo API: No API key required (free tier)
- Zimbabwe-specific data: Configure in `lib/services/zimbabwe_api_service.dart`

## Build Configuration

### Android Release Build
1. Generate a release keystore:
   ```bash
   keytool -genkey -v -keystore android/app/release.keystore -alias agric_climatic -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Update `android/app/build.gradle.kts` with your keystore details:
   ```kotlin
   signingConfigs {
       create("release") {
           storeFile = file("release.keystore")
           storePassword = "your_store_password"
           keyAlias = "agric_climatic"
           keyPassword = "your_key_password"
       }
   }
   ```

3. Build the release APK:
   ```bash
   flutter build apk --release
   ```

4. Build the release AAB (for Google Play):
   ```bash
   flutter build appbundle --release
   ```

### iOS Release Build
1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing and capabilities
3. Set the bundle identifier to `com.agricclimatic.zimbabwe`
4. Build for release:
   ```bash
   flutter build ios --release
   ```

## Security Configuration

### 1. Firebase Security Rules
Configure Firestore security rules in Firebase Console:
```javascript
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
```

### 2. Supabase RLS Policies
Configure Row Level Security policies in Supabase:
```sql
-- Enable RLS on all tables
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Public read access" ON weather_data FOR SELECT USING (true);
CREATE POLICY "Public read access" ON soil_data FOR SELECT USING (true);
CREATE POLICY "Public read access" ON predictions FOR SELECT USING (true);
CREATE POLICY "Public read access" ON weather_alerts FOR SELECT USING (true);

-- Create policies for authenticated write access
CREATE POLICY "Authenticated write access" ON weather_data FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated write access" ON soil_data FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated write access" ON predictions FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated write access" ON weather_alerts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

## Performance Optimization

### 1. Code Optimization
- Enable ProGuard/R8 for Android builds
- Enable tree shaking for Flutter builds
- Optimize images and assets
- Use lazy loading for large datasets

### 2. Network Optimization
- Implement proper caching strategies
- Use compression for API responses
- Implement offline functionality
- Optimize API calls

### 3. Memory Management
- Dispose of controllers and streams properly
- Use weak references where appropriate
- Implement proper image caching
- Monitor memory usage

## Monitoring and Analytics

### 1. Firebase Analytics
- Enable Firebase Analytics
- Track user engagement
- Monitor app performance
- Track crashes and errors

### 2. Custom Analytics
- Track weather data usage
- Monitor prediction accuracy
- Track user preferences
- Monitor API usage

### 3. Error Tracking
- Implement crash reporting
- Track API errors
- Monitor network issues
- Track user feedback

## Testing

### 1. Unit Tests
```bash
flutter test
```

### 2. Integration Tests
```bash
flutter test integration_test/
```

### 3. Widget Tests
```bash
flutter test test/
```

### 4. Manual Testing
- Test on different devices
- Test with different network conditions
- Test offline functionality
- Test with different screen sizes

## Deployment

### 1. Google Play Store
1. Create a Google Play Console account
2. Upload the AAB file
3. Configure store listing
4. Set up pricing and distribution
5. Submit for review

### 2. Apple App Store
1. Create an Apple Developer account
2. Upload the IPA file via Xcode or App Store Connect
3. Configure app information
4. Set up pricing and availability
5. Submit for review

## Maintenance

### 1. Regular Updates
- Update dependencies regularly
- Monitor security vulnerabilities
- Update API endpoints as needed
- Keep documentation current

### 2. Monitoring
- Monitor app performance
- Track user feedback
- Monitor API usage and costs
- Track error rates

### 3. Backup and Recovery
- Regular database backups
- Backup configuration files
- Test recovery procedures
- Document recovery processes

## Troubleshooting

### Common Issues
1. **Build failures**: Check dependencies and configuration
2. **API errors**: Verify API keys and endpoints
3. **Performance issues**: Check memory usage and network calls
4. **Crash reports**: Review logs and fix issues

### Support
- Check Flutter documentation
- Review Firebase documentation
- Check Supabase documentation
- Contact support if needed

## Security Considerations

### 1. API Security
- Use HTTPS for all API calls
- Implement proper authentication
- Validate all inputs
- Use rate limiting

### 2. Data Security
- Encrypt sensitive data
- Use secure storage
- Implement proper access controls
- Regular security audits

### 3. User Privacy
- Implement privacy policy
- Collect only necessary data
- Allow users to delete data
- Comply with regulations

## Conclusion

This guide provides a comprehensive overview of deploying AgriClimatic to production. Follow the steps carefully and test thoroughly before releasing to users.

For additional support or questions, please refer to the Flutter documentation or contact the development team.
