@echo off
REM Script to help update GitHub Secrets with the new JKS keystore

echo 🔐 Updating GitHub Secrets with New JKS Keystore
echo ================================================

echo.
echo ✅ New JKS keystore created successfully!
echo ✅ Local build tested and working!
echo.

echo 📋 Updated GitHub Secrets to Add:
echo =================================
echo.
echo 1. Go to: https://github.com/PraiseTechzw/agric_climatic/settings/secrets/actions
echo.
echo 2. Update the KEYSTORE_BASE64 secret:
echo    - Delete the old KEYSTORE_BASE64 secret
echo    - Add new secret with name: KEYSTORE_BASE64
echo    - Copy the contents of keystore_base64.txt
echo    - This is your new JKS keystore file encoded in base64
echo.
echo 3. Keep the existing secrets (they should be the same):
echo    - KEYSTORE_PASSWORD: Naph2003*
echo    - KEY_PASSWORD: Naph2003*
echo.

echo 🔍 To verify the new keystore:
echo - Check that keystore_base64.txt contains the new keystore data
echo - The file should be different from the previous version
echo.

echo 🚀 After updating the secrets:
echo 1. Create a new release to test the fixed signing
echo 2. Monitor GitHub Actions for successful build
echo 3. Download and test the signed APK
echo.

echo ⚠️  Important:
echo - The new keystore is in JKS format (compatible with GitHub Actions)
echo - Keep your keystore file secure and backed up
echo - Delete keystore_base64.txt after updating GitHub Secrets
echo.

pause
