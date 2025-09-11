@echo off
REM Script to help set up GitHub Secrets for APK signing

echo 🔐 Setting up GitHub Secrets for APK Signing
echo ============================================

echo.
echo This script will help you set up GitHub Secrets for automated APK signing.
echo You'll need to add these secrets to your GitHub repository.
echo.

REM Check if keystore exists
if not exist "android\app\release-key.keystore" (
    echo ❌ Error: Keystore file not found!
    echo Please run the release script first to create the keystore.
    pause
    exit /b 1
)

echo ✅ Keystore found: android\app\release-key.keystore
echo.

REM Encode keystore to base64
echo 📝 Encoding keystore to base64...
powershell -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('android\app\release-key.keystore'))" > keystore_base64.txt

echo ✅ Keystore encoded to keystore_base64.txt
echo.

echo 📋 GitHub Secrets to Add:
echo =========================
echo.
echo 1. Go to: https://github.com/PraiseTechzw/agric_climatic/settings/secrets/actions
echo.
echo 2. Add these secrets:
echo.
echo    KEYSTORE_BASE64:
echo    - Copy the contents of keystore_base64.txt
echo    - This is your keystore file encoded in base64
echo.
echo    KEYSTORE_PASSWORD:
echo    - Naph2003*
echo    - This is your keystore password
echo.
echo    KEY_PASSWORD:
echo    - Naph2003*
echo    - This is your key password
echo.
echo 3. Click "Add secret" for each one
echo.

echo 📁 Files created:
echo - keystore_base64.txt (keystore in base64 format)
echo.

echo ⚠️  Important Security Notes:
echo - Keep your keystore file secure and backed up
echo - Never commit keystore files to git
echo - The keystore_base64.txt file contains sensitive data
echo - Delete it after setting up GitHub Secrets
echo.

echo 🚀 Next Steps:
echo 1. Add the secrets to GitHub
echo 2. Commit and push your changes
echo 3. Create a new release to test automated signing
echo.

pause
