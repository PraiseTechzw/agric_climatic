@echo off
REM AgriClimatic Production Setup Script for Windows
REM This script helps you set up the production deployment environment

echo 🚀 AgriClimatic Production Setup
echo ==================================

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Initializing git repository...
    git init
    echo ✅ Git repository initialized
) else (
    echo ✅ Git repository found
)

REM Check Flutter installation
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
) else (
    echo ✅ Flutter found
    flutter --version | findstr "Flutter"
)

REM Check if we're in a Flutter project
if not exist "pubspec.yaml" (
    echo ❌ Not in a Flutter project directory
    echo Please run this script from your Flutter project root
    pause
    exit /b 1
)

echo ✅ Flutter project detected

REM Check if GitHub remote is configured
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  No GitHub remote configured
    echo.
    echo To set up GitHub remote, run:
    echo   git remote add origin https://github.com/yourusername/agric_climatic.git
    echo.
    set /p configure_remote="Do you want to configure the remote now? (y/N): "
    if /i "%configure_remote%"=="y" (
        set /p repo_url="Enter your GitHub repository URL: "
        git remote add origin "%repo_url%"
        echo ✅ GitHub remote configured
    )
) else (
    echo ✅ GitHub remote configured
    git remote get-url origin
)

REM Check if there are uncommitted changes
git diff-index --quiet HEAD -- >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  You have uncommitted changes
    echo Uncommitted files:
    git diff --name-only
    echo.
    set /p commit_changes="Do you want to commit these changes now? (y/N): "
    if /i "%commit_changes%"=="y" (
        git add .
        git commit -m "Setup production deployment configuration"
        echo ✅ Changes committed
    )
)

REM Check if main branch exists
git show-ref --verify --quiet refs/heads/main >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  No main branch found, creating...
    git checkout -b main
    echo ✅ Main branch created
)

REM Verify Flutter dependencies
echo 📦 Checking Flutter dependencies...
flutter pub get
echo ✅ Dependencies updated

REM Run Flutter doctor
echo 🔍 Running Flutter doctor...
flutter doctor

REM Test build
echo 🔨 Testing Flutter build...
flutter build apk --debug
if %errorlevel% equ 0 (
    echo ✅ Flutter build successful
) else (
    echo ❌ Flutter build failed
    echo Please fix the build issues before proceeding
    pause
    exit /b 1
)

echo.
echo 🎉 Production setup complete!
echo.
echo 📋 Next steps:
echo 1. Push your code to GitHub:
echo    git push -u origin main
echo.
echo 2. Create your first release:
echo    .\scripts\release.bat
echo.
echo 3. Monitor the build process in GitHub Actions
echo.
echo 📚 Documentation:
echo - Production Guide: PRODUCTION_DEPLOYMENT.md
echo - Release Script: scripts\release.bat
echo - GitHub Actions: .github\workflows\build-and-release.yml
echo.
echo Happy Deploying! 🚀
pause
