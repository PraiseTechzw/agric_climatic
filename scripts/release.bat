@echo off
REM AgriClimatic Release Script for Windows
REM This script helps you create a new release by updating version numbers and creating git tags

setlocal enabledelayedexpansion

echo 🚀 AgriClimatic Release Script
echo ==================================

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Not in a git repository
    pause
    exit /b 1
)

REM Check if there are uncommitted changes
git diff-index --quiet HEAD -- >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Warning: You have uncommitted changes. Please commit or stash them first.
    echo Uncommitted files:
    git diff --name-only
    echo.
    set /p continue_anyway="Do you want to continue anyway? (y/N): "
    if /i not "!continue_anyway!"=="y" (
        echo Release cancelled.
        pause
        exit /b 1
    )
)

REM Get current version from pubspec.yaml
for /f "tokens=2" %%i in ('findstr "version:" pubspec.yaml') do set CURRENT_VERSION=%%i
echo Current version: !CURRENT_VERSION!

REM Parse version parts
for /f "tokens=1,2 delims=+" %%a in ("!CURRENT_VERSION!") do (
    set VERSION_NAME=%%a
    set BUILD_NUMBER=%%b
)

if "!BUILD_NUMBER!"=="" set BUILD_NUMBER=1

echo Version name: !VERSION_NAME!
echo Build number: !BUILD_NUMBER!

REM Ask for release type
echo.
echo What type of release do you want to create?
echo 1) Patch release (1.0.0 -^> 1.0.1)
echo 2) Minor release (1.0.0 -^> 1.1.0)
echo 3) Major release (1.0.0 -^> 2.0.0)
echo 4) Custom version
echo 5) Just increment build number

set /p release_type="Choose an option (1-5): "

if "!release_type!"=="1" (
    REM Patch release
    for /f "tokens=1,2,3 delims=." %%a in ("!VERSION_NAME!") do (
        set MAJOR=%%a
        set MINOR=%%b
        set /a PATCH=%%c+1
        set NEW_VERSION=!MAJOR!.!MINOR!.!PATCH!
    )
) else if "!release_type!"=="2" (
    REM Minor release
    for /f "tokens=1,2,3 delims=." %%a in ("!VERSION_NAME!") do (
        set MAJOR=%%a
        set /a MINOR=%%b+1
        set NEW_VERSION=!MAJOR!.!MINOR!.0
    )
) else if "!release_type!"=="3" (
    REM Major release
    for /f "tokens=1,2,3 delims=." %%a in ("!VERSION_NAME!") do (
        set /a MAJOR=%%a+1
        set NEW_VERSION=!MAJOR!.0.0
    )
) else if "!release_type!"=="4" (
    set /p NEW_VERSION="Enter new version (e.g., 1.2.3): "
) else if "!release_type!"=="5" (
    set NEW_VERSION=!VERSION_NAME!
    set /a NEW_BUILD_NUMBER=!BUILD_NUMBER!+1
) else (
    echo ❌ Invalid option. Release cancelled.
    pause
    exit /b 1
)

REM Increment build number if not custom
if "!NEW_BUILD_NUMBER!"=="" set /a NEW_BUILD_NUMBER=!BUILD_NUMBER!+1

set FULL_VERSION=!NEW_VERSION!+!NEW_BUILD_NUMBER!
set TAG_NAME=v!NEW_VERSION!

echo.
echo 📋 Release Summary:
echo   Current version: !CURRENT_VERSION!
echo   New version: !FULL_VERSION!
echo   Tag name: !TAG_NAME!
echo.

set /p proceed="Do you want to proceed with this release? (y/N): "
if /i not "!proceed!"=="y" (
    echo Release cancelled.
    pause
    exit /b 1
)

REM Update pubspec.yaml
echo 📝 Updating pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: !FULL_VERSION!' | Set-Content pubspec.yaml"

REM Update Android build.gradle.kts
echo 📝 Updating Android build.gradle.kts...
powershell -Command "(Get-Content android\app\build.gradle.kts) -replace 'versionCode = .*', 'versionCode = !NEW_BUILD_NUMBER!' | Set-Content android\app\build.gradle.kts"
powershell -Command "(Get-Content android\app\build.gradle.kts) -replace 'versionName = \".*\"', 'versionName = \"!NEW_VERSION!\"' | Set-Content android\app\build.gradle.kts"

REM Commit changes
echo 💾 Committing changes...
git add pubspec.yaml android\app\build.gradle.kts
git commit -m "Bump version to !FULL_VERSION!

- Updated version in pubspec.yaml
- Updated versionCode and versionName in Android build.gradle.kts
- Ready for release !TAG_NAME!"

REM Create and push tag
echo 🏷️  Creating and pushing tag...
git tag -a "!TAG_NAME!" -m "Release !TAG_NAME!

Version: !FULL_VERSION!
Build: !NEW_BUILD_NUMBER!

Features:
- Agricultural climate prediction and analysis
- SMS and push notifications
- Zimbabwe-specific weather data"

git push origin main
git push origin "!TAG_NAME!"

echo.
echo ✅ Release !TAG_NAME! created successfully!
echo.
echo 📱 Next steps:
echo 1. GitHub Actions will automatically build the APK
echo 2. Check the Actions tab in your GitHub repository
echo 3. Once complete, the APK will be available in the Releases section
echo 4. Download and test the APK before distributing
echo.
echo 🔗 Useful links:
echo   - GitHub Actions: https://github.com/yourusername/agric_climatic/actions
echo   - Releases: https://github.com/yourusername/agric_climatic/releases
echo.
echo 🎉 Happy releasing!
pause
