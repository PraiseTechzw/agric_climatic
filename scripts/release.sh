#!/bin/bash

# AgriClimatic Release Script
# This script helps you create a new release by updating version numbers and creating git tags

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AgriClimatic Release Script${NC}"
echo "=================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes. Please commit or stash them first.${NC}"
    echo "Uncommitted files:"
    git diff --name-only
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled."
        exit 1
    fi
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"

# Parse version parts
IFS='+' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
VERSION_NAME="${VERSION_PARTS[0]}"
BUILD_NUMBER="${VERSION_PARTS[1]:-1}"

echo -e "${BLUE}Version name: ${VERSION_NAME}${NC}"
echo -e "${BLUE}Build number: ${BUILD_NUMBER}${NC}"

# Ask for release type
echo ""
echo "What type of release do you want to create?"
echo "1) Patch release (1.0.0 -> 1.0.1)"
echo "2) Minor release (1.0.0 -> 1.1.0)"
echo "3) Major release (1.0.0 -> 2.0.0)"
echo "4) Custom version"
echo "5) Just increment build number"

read -p "Choose an option (1-5): " -n 1 -r
echo

case $REPLY in
    1)
        # Patch release
        IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NAME"
        MAJOR="${VERSION_PARTS[0]}"
        MINOR="${VERSION_PARTS[1]}"
        PATCH=$((VERSION_PARTS[2] + 1))
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    2)
        # Minor release
        IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NAME"
        MAJOR="${VERSION_PARTS[0]}"
        MINOR=$((VERSION_PARTS[1] + 1))
        NEW_VERSION="$MAJOR.$MINOR.0"
        ;;
    3)
        # Major release
        IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NAME"
        MAJOR=$((VERSION_PARTS[0] + 1))
        NEW_VERSION="$MAJOR.0.0"
        ;;
    4)
        read -p "Enter new version (e.g., 1.2.3): " NEW_VERSION
        ;;
    5)
        NEW_VERSION="$VERSION_NAME"
        NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
        ;;
    *)
        echo -e "${RED}❌ Invalid option. Release cancelled.${NC}"
        exit 1
        ;;
esac

# Increment build number if not custom
if [ -z "$NEW_BUILD_NUMBER" ]; then
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
fi

FULL_VERSION="$NEW_VERSION+$NEW_BUILD_NUMBER"
TAG_NAME="v$NEW_VERSION"

echo ""
echo -e "${GREEN}📋 Release Summary:${NC}"
echo "  Current version: $CURRENT_VERSION"
echo "  New version: $FULL_VERSION"
echo "  Tag name: $TAG_NAME"
echo ""

read -p "Do you want to proceed with this release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 1
fi

# Update pubspec.yaml
echo -e "${BLUE}📝 Updating pubspec.yaml...${NC}"
sed -i.bak "s/version: .*/version: $FULL_VERSION/" pubspec.yaml
rm pubspec.yaml.bak

# Update Android build.gradle.kts
echo -e "${BLUE}📝 Updating Android build.gradle.kts...${NC}"
sed -i.bak "s/versionCode = .*/versionCode = $NEW_BUILD_NUMBER/" android/app/build.gradle.kts
sed -i.bak "s/versionName = \".*\"/versionName = \"$NEW_VERSION\"/" android/app/build.gradle.kts
rm android/app/build.gradle.kts.bak

# Commit changes
echo -e "${BLUE}💾 Committing changes...${NC}"
git add pubspec.yaml android/app/build.gradle.kts
git commit -m "Bump version to $FULL_VERSION

- Updated version in pubspec.yaml
- Updated versionCode and versionName in Android build.gradle.kts
- Ready for release $TAG_NAME"

# Create and push tag
echo -e "${BLUE}🏷️  Creating and pushing tag...${NC}"
git tag -a "$TAG_NAME" -m "Release $TAG_NAME

Version: $FULL_VERSION
Build: $NEW_BUILD_NUMBER

Features:
- Agricultural climate prediction and analysis
- SMS and push notifications
- Zimbabwe-specific weather data"

git push origin main
git push origin "$TAG_NAME"

echo ""
echo -e "${GREEN}✅ Release $TAG_NAME created successfully!${NC}"
echo ""
echo -e "${YELLOW}📱 Next steps:${NC}"
echo "1. GitHub Actions will automatically build the APK"
echo "2. Check the Actions tab in your GitHub repository"
echo "3. Once complete, the APK will be available in the Releases section"
echo "4. Download and test the APK before distributing"
echo ""
echo -e "${BLUE}🔗 Useful links:${NC}"
echo "  - GitHub Actions: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/')/actions"
echo "  - Releases: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/')/releases"
echo ""
echo -e "${GREEN}🎉 Happy releasing!${NC}"
