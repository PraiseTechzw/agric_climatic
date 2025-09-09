#!/bin/bash

# AgriClimatic Production Build Script
# This script builds the app for production deployment

set -e  # Exit on any error

echo "🚀 Starting AgriClimatic Production Build..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
print_status "Flutter version: $FLUTTER_VERSION"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run tests
print_status "Running tests..."
if flutter test; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi

# Analyze code
print_status "Analyzing code..."
if flutter analyze; then
    print_success "Code analysis passed"
else
    print_warning "Code analysis found issues"
fi

# Build for Android
print_status "Building Android APK..."
if flutter build apk --release; then
    print_success "Android APK built successfully"
else
    print_error "Android APK build failed"
    exit 1
fi

# Build for Android App Bundle
print_status "Building Android App Bundle..."
if flutter build appbundle --release; then
    print_success "Android App Bundle built successfully"
else
    print_error "Android App Bundle build failed"
    exit 1
fi

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building iOS app..."
    if flutter build ios --release; then
        print_success "iOS app built successfully"
    else
        print_warning "iOS build failed (this is normal if not on macOS)"
    fi
else
    print_warning "Skipping iOS build (not on macOS)"
fi

# Build for Web
print_status "Building Web app..."
if flutter build web --release; then
    print_success "Web app built successfully"
else
    print_warning "Web build failed"
fi

# Build for Windows
print_status "Building Windows app..."
if flutter build windows --release; then
    print_success "Windows app built successfully"
else
    print_warning "Windows build failed"
fi

# Build for Linux
print_status "Building Linux app..."
if flutter build linux --release; then
    print_success "Linux app built successfully"
else
    print_warning "Linux build failed"
fi

# Build for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building macOS app..."
    if flutter build macos --release; then
        print_success "macOS app built successfully"
    else
        print_warning "macOS build failed"
    fi
else
    print_warning "Skipping macOS build (not on macOS)"
fi

# Create build summary
print_status "Creating build summary..."
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_VERSION=$(grep "version:" pubspec.yaml | cut -d ' ' -f 2)

cat > build_summary.txt << EOF
AgriClimatic Production Build Summary
=====================================
Build Date: $BUILD_DATE
Version: $BUILD_VERSION
Flutter Version: $FLUTTER_VERSION

Build Artifacts:
- Android APK: build/app/outputs/flutter-apk/app-release.apk
- Android App Bundle: build/app/outputs/bundle/release/app-release.aab
- Web: build/web/
- Windows: build/windows/runner/Release/
- Linux: build/linux/x64/release/bundle/
- macOS: build/macos/Build/Products/Release/ (if on macOS)
- iOS: build/ios/Release-iphoneos/ (if on macOS)

Next Steps:
1. Test the built apps on target devices
2. Upload to app stores (Google Play, Apple App Store)
3. Deploy web version to hosting service
4. Distribute desktop versions as needed

For deployment instructions, see PRODUCTION_DEPLOYMENT.md
EOF

print_success "Build summary created: build_summary.txt"

# Show build artifacts
print_status "Build artifacts:"
ls -la build/app/outputs/flutter-apk/ 2>/dev/null || true
ls -la build/app/outputs/bundle/release/ 2>/dev/null || true
ls -la build/web/ 2>/dev/null || true
ls -la build/windows/runner/Release/ 2>/dev/null || true
ls -la build/linux/x64/release/bundle/ 2>/dev/null || true

print_success "🎉 Production build completed successfully!"
print_status "Check build_summary.txt for details and next steps"
