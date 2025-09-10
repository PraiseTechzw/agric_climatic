# 🌾 AgriClimatic

**AgriClimatic** - Zimbabwe Agricultural Climate Prediction & Analysis App with SMS & Push Notifications

A comprehensive Flutter application that provides agricultural climate predictions, weather analysis, and real-time notifications specifically designed for Zimbabwe's farming community.

## ✨ Features

- 🌡️ **Weather Prediction**: Advanced climate forecasting for agricultural planning
- 📱 **SMS Notifications**: Real-time alerts via SMS for critical weather updates
- 🔔 **Push Notifications**: In-app notifications for weather changes
- 📊 **Data Visualization**: Interactive charts and graphs for weather trends
- 🗺️ **Location Services**: GPS-based weather data for specific regions
- 🔐 **User Authentication**: Secure login with Firebase Auth
- ☁️ **Cloud Storage**: Data persistence with Supabase
- 📈 **Analytics**: Weather pattern analysis and historical data

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.24.0 or later
- Android Studio / VS Code
- Git
- Firebase account
- Supabase account

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/agric_climatic.git
   cd agric_climatic
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Follow the setup guide in `FIREBASE_SETUP.md`
   - Add your `google-services.json` to `android/app/`

4. **Configure Supabase**:
   - Follow the setup guide in `supabase_setup_guide.md`
   - Update your Supabase credentials

5. **Run the app**:
   ```bash
   flutter run
   ```

## 📱 Production Deployment

### Automated APK Building & Releases

This project includes automated CI/CD pipeline for production deployment:

- **GitHub Actions**: Automated APK building on every release
- **Version Management**: Automatic versioning and tagging
- **Release Scripts**: Easy-to-use scripts for creating releases
- **Multiple Architectures**: APK builds for ARM64, ARM, and x86_64

### Quick Deployment

**Windows Users**:
```cmd
# Setup production environment
scripts\setup-production.bat

# Create a new release
scripts\release.bat
```

**Linux/Mac Users**:
```bash
# Setup production environment
./scripts/setup-production.sh

# Create a new release
./scripts/release.sh
```

### Release Process

1. **Create Release**: Run the release script
2. **Choose Version**: Select patch/minor/major release
3. **Auto Build**: GitHub Actions builds APK automatically
4. **Download**: Get APK from GitHub Releases
5. **Test & Distribute**: Test on devices and distribute

## 📚 Documentation

- **Production Guide**: `PRODUCTION_DEPLOYMENT.md` - Complete deployment guide
- **Firebase Setup**: `FIREBASE_SETUP.md` - Firebase configuration
- **Supabase Setup**: `supabase_setup_guide.md` - Database setup
- **Scripts Guide**: `scripts/README.md` - Release management scripts

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── services/                 # Business logic services
├── models/                   # Data models
├── screens/                  # UI screens
├── widgets/                  # Reusable widgets
└── utils/                    # Utility functions

scripts/
├── setup-production.bat     # Windows setup script
├── setup-production.sh      # Linux/Mac setup script
├── release.bat              # Windows release script
└── release.sh               # Linux/Mac release script

.github/
└── workflows/
    └── build-and-release.yml # GitHub Actions workflow
```

### Dependencies

- **Flutter**: UI framework
- **Firebase**: Authentication, messaging, Firestore
- **Supabase**: Database and real-time features
- **Provider**: State management
- **fl_chart**: Data visualization
- **Geolocator**: Location services
- **Twilio**: SMS notifications

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
```

### Firebase Configuration

1. Create a Firebase project
2. Enable Authentication, Firestore, and Cloud Messaging
3. Download `google-services.json`
4. Place it in `android/app/`

### Supabase Configuration

1. Create a Supabase project
2. Run the SQL scripts in the root directory
3. Update your Supabase credentials

## 📱 Supported Platforms

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+ (planned)
- **Web**: Progressive Web App (planned)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: Check the guides in the project root
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions

## 🎯 Roadmap

- [ ] iOS support
- [ ] Web application
- [ ] Offline mode
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] Weather alerts API integration

---

**Built with ❤️ for Zimbabwe's farming community**

*Empowering farmers with technology for better agricultural decisions*
