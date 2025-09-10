#!/bin/bash

# AgriClimatic Production Setup Script
# This script helps you set up the production deployment environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AgriClimatic Production Setup${NC}"
echo "=================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Initializing git repository...${NC}"
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${GREEN}✅ Git repository found${NC}"
fi

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
else
    echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -n 1)${NC}"
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Not in a Flutter project directory${NC}"
    echo "Please run this script from your Flutter project root"
    exit 1
fi

echo -e "${GREEN}✅ Flutter project detected${NC}"

# Make scripts executable
echo -e "${BLUE}📝 Making scripts executable...${NC}"
chmod +x scripts/release.sh
chmod +x scripts/setup-production.sh
echo -e "${GREEN}✅ Scripts made executable${NC}"

# Check if GitHub remote is configured
if ! git remote get-url origin &> /dev/null; then
    echo -e "${YELLOW}⚠️  No GitHub remote configured${NC}"
    echo ""
    echo "To set up GitHub remote, run:"
    echo "  git remote add origin https://github.com/yourusername/agric_climatic.git"
    echo ""
    read -p "Do you want to configure the remote now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your GitHub repository URL: " REPO_URL
        git remote add origin "$REPO_URL"
        echo -e "${GREEN}✅ GitHub remote configured${NC}"
    fi
else
    echo -e "${GREEN}✅ GitHub remote configured: $(git remote get-url origin)${NC}"
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo "Uncommitted files:"
    git diff --name-only
    echo ""
    read -p "Do you want to commit these changes now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Setup production deployment configuration"
        echo -e "${GREEN}✅ Changes committed${NC}"
    fi
fi

# Check if main branch exists
if ! git show-ref --verify --quiet refs/heads/main; then
    echo -e "${YELLOW}⚠️  No main branch found, creating...${NC}"
    git checkout -b main
    echo -e "${GREEN}✅ Main branch created${NC}"
fi

# Verify Flutter dependencies
echo -e "${BLUE}📦 Checking Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies updated${NC}"

# Run Flutter doctor
echo -e "${BLUE}🔍 Running Flutter doctor...${NC}"
flutter doctor
echo ""

# Test build
echo -e "${BLUE}🔨 Testing Flutter build...${NC}"
if flutter build apk --debug; then
    echo -e "${GREEN}✅ Flutter build successful${NC}"
else
    echo -e "${RED}❌ Flutter build failed${NC}"
    echo "Please fix the build issues before proceeding"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Production setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Push your code to GitHub:"
echo "   git push -u origin main"
echo ""
echo "2. Create your first release:"
echo "   ./scripts/release.sh"
echo ""
echo "3. Monitor the build process in GitHub Actions"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "- Production Guide: PRODUCTION_DEPLOYMENT.md"
echo "- Release Script: scripts/release.sh"
echo "- GitHub Actions: .github/workflows/build-and-release.yml"
echo ""
echo -e "${GREEN}Happy Deploying! 🚀${NC}"
