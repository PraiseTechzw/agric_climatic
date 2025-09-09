# 🚀 Complete Firebase & API Setup Guide

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** or **"Add project"**
3. Enter project name: `agro-climatic`
4. **Enable Google Analytics** (recommended)
5. Click **"Create project"**

### 1.2 Wait for Project Creation
- This may take 1-2 minutes
- You'll see a success message when ready

## Step 2: Add Android App to Firebase

### 2.1 Add Android App
1. In Firebase Console, click **"Add app"** (Android icon)
2. Enter package name: `com.example.agric_climatic`
3. Enter app nickname: `Agricultural Climate App`
4. **Leave SHA-1 empty for now** (we'll add it later)
5. Click **"Register app"**

### 2.2 Download Configuration File
1. Download `google-services.json`
2. **IMPORTANT**: Place it in `android/app/` directory
3. The file should be at: `android/app/google-services.json`

## Step 3: Enable Required APIs

### 3.1 Enable Cloud Firestore
1. In Firebase Console, go to **"Firestore Database"**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select location: **"europe-west1"** (closest to Zimbabwe)
5. Click **"Done"**

### 3.2 Enable Authentication
1. Go to **"Authentication"** in Firebase Console
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Anonymous"** authentication
5. Click **"Save"**

### 3.3 Enable Cloud Messaging
1. Go to **"Cloud Messaging"** in Firebase Console
2. No additional setup needed for basic functionality

## Step 4: Configure Firestore Security Rules

### 4.1 Set Up Security Rules
1. In Firestore Database, go to **"Rules"** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow public read access to all collections
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Specific rules for agricultural data
    match /weather_data/{document} {
      allow read, write: if true;
    }
    
    match /soil_data/{document} {
      allow read, write: if true;
    }
    
    match /predictions/{document} {
      allow read, write: if true;
    }
    
    match /weather_patterns/{document} {
      allow read, write: if true;
    }
    
    match /weather_alerts/{document} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

## Step 5: Update Firebase Configuration

### 5.1 Get Your Firebase Config
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"** section
3. Click on your Android app
4. Copy the configuration values

### 5.2 Update firebase_options.dart
Replace the placeholder values in `lib/firebase_options.dart` with your actual values:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'agro-climatic',
  storageBucket: 'agro-climatic.appspot.com',
);
```

## Step 6: Test the Connection

### 6.1 Run the App
```bash
flutter clean
flutter pub get
flutter run --debug
```

### 6.2 Check Backend Status
1. Look for the **"Backend Status"** widget at the top of the weather screen
2. It should show **"Backend connected successfully"** in green
3. If it shows **"Backend offline"**, check the console for errors

## Step 7: Verify Data Flow

### 7.1 Test Weather Data
1. Tap the location detection button (📍)
2. Allow location permissions
3. Check if weather data loads
4. Verify data appears in Firebase Console

### 7.2 Test Soil Data
1. Go to Soil Data screen
2. Check if soil data loads
3. Verify data appears in Firebase Console

### 7.3 Test Predictions
1. Go to Predictions screen
2. Check if predictions generate
3. Verify data appears in Firebase Console

## Troubleshooting

### Common Issues & Solutions

#### 1. "Cloud Firestore API has not been used"
**Solution:**
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Select your project: `agro-climatic`
- Go to **"APIs & Services"** > **"Library"**
- Search for **"Cloud Firestore API"**
- Click **"Enable"**
- Wait 5-10 minutes for changes to propagate

#### 2. "Permission denied" errors
**Solution:**
- Check Firestore security rules
- Ensure rules allow public read access
- Verify the rules are published

#### 3. App crashes on startup
**Solution:**
- Check `google-services.json` is in correct location
- Verify Firebase configuration values
- Run `flutter clean` and `flutter pub get`

#### 4. Location detection not working
**Solution:**
- Check device location permissions
- Ensure GPS is enabled
- Test on physical device (not emulator)

#### 5. No data appearing in Firebase
**Solution:**
- Check internet connection
- Verify Firebase project is active
- Check console logs for errors
- Ensure APIs are enabled

## Step 8: Production Setup (Optional)

### 8.1 Security Rules for Production
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authenticated users only
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Public read access for agricultural data
    match /weather_data/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 8.2 Enable User Authentication
1. In Firebase Console, go to **Authentication**
2. Enable **"Email/Password"** sign-in
3. Configure user management

### 8.3 Set Up Monitoring
1. Go to **"Performance Monitoring"**
2. Enable performance tracking
3. Set up alerts for errors

## Verification Checklist

- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] `google-services.json` downloaded and placed correctly
- [ ] Cloud Firestore enabled
- [ ] Authentication enabled
- [ ] Security rules configured
- [ ] `firebase_options.dart` updated with real values
- [ ] App builds and runs successfully
- [ ] Backend status shows "connected"
- [ ] Weather data loads
- [ ] Soil data loads
- [ ] Predictions generate
- [ ] Data appears in Firebase Console

## Support

If you encounter issues:

1. **Check Console Logs**: Look for error messages
2. **Verify Configuration**: Ensure all values are correct
3. **Test APIs**: Use Firebase Console to test database operations
4. **Check Permissions**: Verify all required permissions are granted

## Next Steps

Once everything is working:

1. **Test All Features**: Weather, soil, predictions, analytics
2. **Add Real Data**: Connect to actual weather APIs
3. **Customize UI**: Adjust colors, fonts, layouts
4. **Add Features**: Notifications, alerts, user accounts
5. **Deploy**: Prepare for production release

The app will work in offline mode even without Firebase, but with limited functionality. The backend connection provides real-time data synchronization and enhanced features.
