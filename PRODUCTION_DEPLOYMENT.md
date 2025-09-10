# 🚀 Production Deployment Guide

This guide will help you deploy your AgriClimatic Flutter app to production using GitHub Actions for automated APK building and release management.

## 📋 Prerequisites

1. **GitHub Repository**: Your code should be in a GitHub repository
2. **Flutter SDK**: Flutter 3.24.0 or later installed locally
3. **Android Studio**: For testing and debugging
4. **Git**: For version control and tagging

## 🏗️ Setup Instructions

### 1. Initial Repository Setup

If you haven't already, initialize your git repository and push to GitHub:

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: AgriClimatic Flutter app"

# Add remote origin (replace with your GitHub repository URL)
git remote add origin https://github.com/yourusername/agric_climatic.git

# Push to GitHub
git push -u origin main
```

### 2. Configure GitHub Actions

The workflow file `.github/workflows/build-and-release.yml` is already created and will:
- Trigger on version tags (v1.0.0, v1.1.0, etc.)
- Build APK and AAB files
- Create GitHub releases automatically
- Upload artifacts for download

### 3. Make Release Script Executable

```bash
# Make the release script executable
chmod +x scripts/release.sh
```

## 🚀 Creating Your First Release

### Method 1: Using the Release Script (Recommended)

```bash
# Run the release script
./scripts/release.sh
```

The script will:
1. Check for uncommitted changes
2. Show current version
3. Ask for release type (patch/minor/major/custom)
4. Update version numbers in all files
5. Create git commit and tag
6. Push to GitHub

### Method 2: Manual Release

1. **Update version in `pubspec.yaml`**:
   ```yaml
   version: 1.0.0+1  # Format: version+build_number
   ```

2. **Update Android build.gradle.kts**:
   ```kotlin
   versionCode = 1
   versionName = "1.0.0"
   ```

3. **Commit and tag**:
   ```bash
   git add .
   git commit -m "Bump version to 1.0.0+1"
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin main
   git push origin v1.0.0
   ```

## 📱 Release Process

### Automatic Process

1. **Create Tag**: When you push a version tag (v1.0.0), GitHub Actions automatically:
   - Builds the Flutter app
   - Creates APK files for different architectures
   - Creates an App Bundle (AAB) for Play Store
   - Creates a GitHub release with download links

2. **Monitor Progress**: Check the Actions tab in your GitHub repository

3. **Download APK**: Once complete, download from the Releases section

### Manual Testing

Before distributing:

1. **Download APK**: Get the APK from GitHub releases
2. **Test on Device**: Install on a physical Android device
3. **Verify Features**: Test all app functionality
4. **Check Performance**: Ensure smooth operation

## 🔧 Configuration Files

### Version Management

- **`pubspec.yaml`**: Main version number
- **`android/app/build.gradle.kts`**: Android-specific versioning
- **Git tags**: Release markers (v1.0.0, v1.1.0, etc.)

### Build Configuration

The workflow builds:
- **APK files**: For direct installation
  - `app-arm64-v8a-release.apk` (64-bit ARM)
  - `app-armeabi-v7a-release.apk` (32-bit ARM)
  - `app-x86_64-release.apk` (64-bit x86)
- **AAB file**: For Google Play Store (`app-release.aab`)

## 📊 Release Management

### Version Numbering

Follow semantic versioning:
- **Major** (2.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes, backward compatible

### Build Numbers

- Increment with each release
- Used by Android for update detection
- Must be unique and increasing

## 🛠️ Troubleshooting

### Common Issues

1. **Build Fails**:
   - Check Flutter version compatibility
   - Verify all dependencies are properly configured
   - Check GitHub Actions logs for specific errors

2. **APK Not Installing**:
   - Enable "Install from unknown sources"
   - Check device architecture compatibility
   - Verify APK integrity

3. **Version Conflicts**:
   - Ensure version numbers are consistent across files
   - Check for duplicate tags
   - Verify git history is clean

### Debug Commands

```bash
# Check Flutter version
flutter --version

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Check git status
git status
git log --oneline

# List tags
git tag -l
```

## 📈 Monitoring Releases

### GitHub Insights

- **Actions Tab**: Monitor build status
- **Releases Tab**: View all releases and downloads
- **Insights Tab**: Track download statistics

### Release Notes

Each release automatically includes:
- Version information
- Installation instructions
- Supported architectures
- Feature highlights

## 🔐 Security Considerations

### APK Signing

Currently using debug keys. For production:

1. **Generate Release Keystore**:
   ```bash
   keytool -genkey -v -keystore release-key.keystore -alias agricclimatic -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Update `android/app/build.gradle.kts`**:
   ```kotlin
   signingConfigs {
       create("release") {
           storeFile = file("../release-key.keystore")
           storePassword = "your_store_password"
           keyAlias = "agricclimatic"
           keyPassword = "your_key_password"
       }
   }
   ```

3. **Add to GitHub Secrets**:
   - `KEYSTORE_PASSWORD`
   - `KEY_PASSWORD`
   - `KEYSTORE_BASE64` (base64 encoded keystore)

## 🎯 Next Steps

1. **Create your first release** using the release script
2. **Test the APK** on various devices
3. **Set up proper signing** for production
4. **Configure Play Store** if planning to publish
5. **Set up monitoring** and crash reporting

## 📞 Support

If you encounter issues:
1. Check GitHub Actions logs
2. Verify Flutter and Android setup
3. Review this guide for common solutions
4. Check the Flutter documentation

---

**Happy Deploying! 🚀**

Your AgriClimatic app is now ready for production deployment with automated CI/CD pipeline.