# Firebase Backend Setup Guide

This guide will help you set up Firebase as the backend for the Agricultural Climate App.

## Prerequisites

1. A Google account
2. Access to the Google Cloud Console
3. The Flutter project already configured with Firebase

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `agro-climatic`
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Required APIs

1. In the Firebase Console, go to "Project Settings" (gear icon)
2. Click on "APIs & Services" tab
3. Enable the following APIs:
   - **Cloud Firestore API**
   - **Firebase Authentication API**
   - **Firebase Cloud Messaging API**

## Step 3: Configure Firestore Database

1. In the Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to Zimbabwe: `europe-west1` or `asia-south1`)

## Step 4: Set Up Firestore Security Rules

1. In Firestore Database, go to "Rules" tab
2. Replace the default rules with:

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
    
    // Allow public read access to weather patterns
    match /weather_patterns/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow public read access to weather alerts
    match /weather_alerts/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click "Publish"

## Step 5: Configure Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous" authentication (for testing)
5. Optionally enable "Email/Password" for user accounts

## Step 6: Set Up Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. No additional setup required for basic functionality

## Step 7: Download Configuration Files

1. In Project Settings, go to "General" tab
2. Scroll down to "Your apps" section
3. Click on the Android app icon
4. Download `google-services.json`
5. Place it in `android/app/` directory

## Step 8: Test the Connection

1. Run the Flutter app
2. Check the "Backend Status" widget at the top of the weather screen
3. It should show "Backend connected successfully" in green

## Troubleshooting

### Common Issues:

1. **"Cloud Firestore API has not been used"**
   - Solution: Enable Cloud Firestore API in Google Cloud Console
   - Wait 5-10 minutes for changes to propagate

2. **"Permission denied" errors**
   - Solution: Check Firestore security rules
   - Ensure rules allow public read access

3. **App crashes on startup**
   - Solution: Check `google-services.json` is in correct location
   - Verify Firebase configuration in `firebase_options.dart`

4. **Location detection not working**
   - Solution: Check location permissions in device settings
   - Ensure GPS is enabled

## Data Collections

The app uses these Firestore collections:

- `weather_data` - Current and historical weather data
- `soil_data` - Soil analysis and conditions
- `predictions` - Long-term agricultural predictions
- `weather_patterns` - Historical weather pattern analysis
- `weather_alerts` - Weather warnings and notifications
- `users` - User preferences and settings

## Production Considerations

1. **Security Rules**: Implement proper authentication-based rules
2. **Data Validation**: Add server-side validation
3. **Rate Limiting**: Implement request rate limiting
4. **Monitoring**: Set up Firebase monitoring and alerts
5. **Backup**: Configure automated backups

## Support

If you encounter issues:

1. Check Firebase Console for error logs
2. Verify all APIs are enabled
3. Check security rules configuration
4. Ensure proper permissions are set

The app will work in offline mode even without Firebase, but with limited functionality.
