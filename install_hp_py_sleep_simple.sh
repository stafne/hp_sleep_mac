#!/bin/bash

# HP Py Sleep - Simple Installer Script
# This script downloads and installs the latest HP Py Sleep release

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository information
GITHUB_REPO="stafne/hp_sleep_mac"

echo "============================================================"
echo "🚀 HP Py Sleep - Simple Installer"
echo "============================================================"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This installer is designed for macOS only.${NC}"
    exit 1
fi

echo -e "${BLUE}📱 Detected macOS system${NC}"
echo ""

# Check for required tools
echo -e "${BLUE}🔍 Checking dependencies...${NC}"

# Check for curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is required but not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ curl is available${NC}"

# Check for jq or python3 (for JSON parsing)
if ! command -v jq &> /dev/null; then
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Neither jq nor python3 is available.${NC}"
        echo "This script requires either jq or python3 for JSON parsing."
        echo "Please install one of them:"
        echo "  - Install Homebrew and run: brew install jq"
        echo "  - Or ensure python3 is available (built into macOS 10.15+)"
        exit 1
    else
        echo -e "${GREEN}✅ Using python3 for JSON parsing${NC}"
        USE_PYTHON_JSON=true
    fi
else
    echo -e "${GREEN}✅ jq is available${NC}"
    USE_PYTHON_JSON=false
fi

echo ""

# Get latest release information
echo -e "${BLUE}📡 Fetching latest release information...${NC}"

API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# Get release data and save to temp file
TEMP_FILE=$(mktemp)
if ! curl -s "$API_URL" > "$TEMP_FILE"; then
    echo -e "${RED}❌ Failed to fetch release information${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Parse JSON response
if [ "$USE_PYTHON_JSON" = true ]; then
    # Use Python for JSON parsing
    JSON_DATA=$(python3 -c "
import json
import sys

try:
    with open('$TEMP_FILE', 'r') as f:
        data = json.load(f)
    
    # Extract version
    print('VERSION:' + data.get('tag_name', ''))
    
    # Find ZIP asset
    zip_assets = [asset for asset in data.get('assets', []) if asset.get('name', '').endswith('.zip')]
    if zip_assets:
        asset = zip_assets[0]
        print('ASSET_NAME:' + asset.get('name', ''))
        print('DOWNLOAD_URL:' + asset.get('browser_download_url', ''))
        print('FILE_SIZE:' + str(asset.get('size', 0)))
    else:
        print('NO_ZIP_ASSET')
        print('AVAILABLE_ASSETS:' + ','.join([asset.get('name', '') for asset in data.get('assets', [])]))
        
except Exception as e:
    print('ERROR:' + str(e))
    sys.exit(1)
")
    
    # Parse the output
    if echo "$JSON_DATA" | grep -q "ERROR:"; then
        echo -e "${RED}❌ Invalid response from GitHub API${NC}"
        echo "Response content:"
        cat "$TEMP_FILE"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    if echo "$JSON_DATA" | grep -q "NO_ZIP_ASSET"; then
        echo -e "${RED}❌ No ZIP asset found in the latest release${NC}"
        echo "Available assets:"
        echo "$JSON_DATA" | grep "AVAILABLE_ASSETS:" | cut -d: -f2- | tr ',' '\n'
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    VERSION=$(echo "$JSON_DATA" | grep "VERSION:" | cut -d: -f2-)
    ASSET_NAME=$(echo "$JSON_DATA" | grep "ASSET_NAME:" | cut -d: -f2-)
    DOWNLOAD_URL=$(echo "$JSON_DATA" | grep "DOWNLOAD_URL:" | cut -d: -f2-)
    FILE_SIZE=$(echo "$JSON_DATA" | grep "FILE_SIZE:" | cut -d: -f2-)
    
else
    # Use jq for JSON parsing
    if ! jq empty "$TEMP_FILE" 2>/dev/null; then
        echo -e "${RED}❌ Invalid response from GitHub API${NC}"
        echo "Response content:"
        cat "$TEMP_FILE"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    VERSION=$(jq -r '.tag_name' "$TEMP_FILE")
    ASSET_NAME=$(jq -r '.assets[] | select(.name | endswith(".zip")) | .name' "$TEMP_FILE" | head -1)
    
    if [ -z "$ASSET_NAME" ] || [ "$ASSET_NAME" = "null" ]; then
        echo -e "${RED}❌ No ZIP asset found in the latest release${NC}"
        echo "Available assets:"
        jq -r '.assets[].name' "$TEMP_FILE"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    DOWNLOAD_URL=$(jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .browser_download_url" "$TEMP_FILE")
    FILE_SIZE=$(jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .size" "$TEMP_FILE")
fi

echo -e "${GREEN}📋 Found version: $VERSION${NC}"
echo -e "${BLUE}🔍 Looking for ZIP asset...${NC}"
echo -e "${GREEN}📦 Found asset: $ASSET_NAME${NC}"

rm -f "$TEMP_FILE"

echo ""
echo -e "${BLUE}📥 Downloading: $ASSET_NAME${NC}"
echo -e "${BLUE}📊 Size: $((FILE_SIZE / 1024 / 1024)) MB${NC}"
echo ""
echo -e "${BLUE}🚀 Starting download and installation of HP Py Sleep $VERSION${NC}"
echo ""

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)
ZIP_PATH="${TEMP_DIR}/${ASSET_NAME}"

# Download the file
echo -e "${BLUE}📥 Downloading...${NC}"
if ! curl -L -o "$ZIP_PATH" "$DOWNLOAD_URL"; then
    echo -e "${RED}❌ Failed to download $ASSET_NAME${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${GREEN}✅ Download completed${NC}"

# Extract and install
echo -e "${BLUE}📦 Extracting application...${NC}"

# Try using the system's built-in unarchiving tools
EXTRACT_SUCCESS=false

# Method 1: Try unzip with force option (overwrite files)
if unzip -q -o "$ZIP_PATH" -d "$TEMP_DIR" 2>/dev/null; then
    EXTRACT_SUCCESS=true
    echo -e "${GREEN}✅ Extracted using unzip${NC}"
fi

# Method 2: If unzip failed, try using ditto (macOS built-in)
if [ "$EXTRACT_SUCCESS" = false ]; then
    echo -e "${YELLOW}⚠️  Trying macOS ditto command...${NC}"
    if ditto -xk "$ZIP_PATH" "$TEMP_DIR" 2>/dev/null; then
        EXTRACT_SUCCESS=true
        echo -e "${GREEN}✅ Extracted using ditto${NC}"
    fi
fi

# Method 3: If both failed, try using Python's zipfile module
if [ "$EXTRACT_SUCCESS" = false ]; then
    echo -e "${YELLOW}⚠️  Trying Python zipfile extraction...${NC}"
    
    # Create a Python script to extract the ZIP file
    PYTHON_SCRIPT=$(cat << 'EOF'
import zipfile
import sys
import os

zip_path = sys.argv[1]
extract_dir = sys.argv[2]

try:
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
EOF
)
    
    # Run the Python extraction
    if python3 -c "$PYTHON_SCRIPT" "$ZIP_PATH" "$TEMP_DIR" 2>/dev/null | grep -q "SUCCESS"; then
        EXTRACT_SUCCESS=true
        echo -e "${GREEN}✅ Extracted using Python${NC}"
    fi
fi

# If all methods failed
if [ "$EXTRACT_SUCCESS" = false ]; then
    echo -e "${RED}❌ Failed to extract ZIP file with all methods${NC}"
    echo "The ZIP file may be corrupted or in an unsupported format."
    echo "Please try downloading the file manually from:"
    echo "https://github.com/stafne/hp_sleep_mac/releases"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Find the .app file
APP_PATH=$(find "$TEMP_DIR" -name "*.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ No .app file found in the downloaded package${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

APP_NAME=$(basename "$APP_PATH")
APP_DESTINATION="/Applications/$APP_NAME"

echo -e "${BLUE}📱 Found app: $APP_NAME${NC}"

# Remove existing installation if it exists
if [ -d "$APP_DESTINATION" ]; then
    echo -e "${YELLOW}⚠️  Removing existing installation...${NC}"
    rm -rf "$APP_DESTINATION"
fi

# Copy to Applications folder
echo -e "${BLUE}📂 Installing to Applications folder...${NC}"
if ! cp -R "$APP_PATH" "/Applications/"; then
    echo -e "${RED}❌ Failed to install to Applications folder${NC}"
    echo "You may need to run with sudo or check permissions."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}🎉 HP Py Sleep has been installed to: $APP_DESTINATION${NC}"
echo ""

# Show security notice
echo -e "${YELLOW}⚠️  IMPORTANT: Security Notice${NC}"
echo ""
echo "Since this app is not code-signed, macOS will show a security warning."
echo ""
echo -e "${BLUE}To launch HP Py Sleep:${NC}"
echo "1. Right-click the app in Applications"
echo "2. Select 'Open' from the context menu"
echo "3. Click 'Open' when macOS shows the security dialog"
echo "4. The app will launch normally"
echo ""
echo -e "${BLUE}Note:${NC} You only need to do this once. After that, you can launch normally."
echo ""

# Ask if user wants to launch
echo -e "${BLUE}Would you like to launch HP Py Sleep now? (y/n):${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 Launching HP Py Sleep...${NC}"
    open "$APP_DESTINATION"
    echo ""
    echo -e "${YELLOW}If you see a security warning, right-click the app and select 'Open'.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo -e "${BLUE}HP Py Sleep is now available in your Applications folder.${NC}"
