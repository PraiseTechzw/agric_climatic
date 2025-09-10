# 📱 AgriClimatic Production Scripts

This directory contains scripts to help you deploy your AgriClimatic Flutter app to production with automated APK building and release management.

## 🚀 Quick Start

### Windows Users
```cmd
# Setup production environment
scripts\setup-production.bat

# Create a new release
scripts\release.bat
```

### Linux/Mac Users
```bash
# Setup production environment
./scripts/setup-production.sh

# Create a new release
./scripts/release.sh
```

## 📋 Available Scripts

### 1. Setup Production (`setup-production.bat` / `setup-production.sh`)

**Purpose**: Initializes your project for production deployment

**What it does**:
- ✅ Checks Flutter installation
- ✅ Initializes git repository (if needed)
- ✅ Configures GitHub remote
- ✅ Updates Flutter dependencies
- ✅ Runs Flutter doctor
- ✅ Tests Flutter build
- ✅ Provides next steps guidance

**Usage**:
```bash
# Windows
scripts\setup-production.bat

# Linux/Mac
./scripts/setup-production.sh
```

### 2. Release Management (`release.bat` / `release.sh`)

**Purpose**: Creates new app releases with automatic versioning

**What it does**:
- ✅ Checks for uncommitted changes
- ✅ Shows current version information
- ✅ Provides release type options:
  - Patch release (1.0.0 → 1.0.1)
  - Minor release (1.0.0 → 1.1.0)
  - Major release (1.0.0 → 2.0.0)
  - Custom version
  - Build number increment only
- ✅ Updates version in all files:
  - `pubspec.yaml`
  - `android/app/build.gradle.kts`
- ✅ Creates git commit and tag
- ✅ Pushes to GitHub
- ✅ Triggers automated build

**Usage**:
```bash
# Windows
scripts\release.bat

# Linux/Mac
./scripts/release.sh
```

## 🔧 Configuration

### Version Management

The scripts automatically manage version numbers in:
- **`pubspec.yaml`**: Main Flutter version
- **`android/app/build.gradle.kts`**: Android-specific versioning

### Git Integration

- Creates semantic version tags (v1.0.0, v1.1.0, etc.)
- Commits version changes automatically
- Pushes to GitHub remote

### GitHub Actions

When you create a release, GitHub Actions automatically:
- Builds APK files for different architectures
- Creates App Bundle (AAB) for Play Store
- Creates GitHub release with download links
- Uploads artifacts for distribution

## 📱 Release Process

### 1. Create Release
```bash
# Run the release script
scripts\release.bat  # Windows
./scripts/release.sh # Linux/Mac
```

### 2. Choose Release Type
- **Patch**: Bug fixes (1.0.0 → 1.0.1)
- **Minor**: New features (1.0.0 → 1.1.0)
- **Major**: Breaking changes (1.0.0 → 2.0.0)
- **Custom**: Specify your own version
- **Build Only**: Just increment build number

### 3. Monitor Build
- Check GitHub Actions tab
- Wait for build completion
- Download APK from Releases

### 4. Test & Distribute
- Test APK on physical device
- Verify all features work
- Distribute to users

## 🛠️ Troubleshooting

### Common Issues

**Script won't run**:
- Make sure you're in the project root directory
- Check that Flutter is installed and in PATH
- Verify git is initialized

**Build fails**:
- Check Flutter doctor output
- Verify all dependencies are installed
- Check GitHub Actions logs for specific errors

**Version conflicts**:
- Ensure no uncommitted changes
- Check git status before running release script
- Verify version numbers are consistent

### Debug Commands

```bash
# Check Flutter installation
flutter --version
flutter doctor

# Check git status
git status
git log --oneline

# Check project structure
dir scripts  # Windows
ls scripts   # Linux/Mac

# Test Flutter build
flutter clean
flutter pub get
flutter build apk --debug
```

## 📚 Additional Resources

- **Production Guide**: `../PRODUCTION_DEPLOYMENT.md`
- **GitHub Actions**: `.github/workflows/build-and-release.yml`
- **Flutter Docs**: https://flutter.dev/docs
- **GitHub Releases**: https://github.com/yourusername/agric_climatic/releases

## 🎯 Best Practices

1. **Always test locally** before creating releases
2. **Commit all changes** before running release script
3. **Test APK** on physical devices after build
4. **Use semantic versioning** for meaningful releases
5. **Keep release notes** descriptive and helpful
6. **Monitor build status** in GitHub Actions

## 🆘 Support

If you encounter issues:
1. Check this README for common solutions
2. Review the production deployment guide
3. Check GitHub Actions logs
4. Verify Flutter and git setup

---

**Happy Deploying! 🚀**

Your AgriClimatic app is now ready for automated production deployment.
