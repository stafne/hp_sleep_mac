#!/bin/bash

# HP Py Sleep - Standalone Installer Script
# This script downloads and installs the latest HP Py Sleep release
# Robust version: prefers DMG drag-and-drop; falls back to ZIP when needed.

set -e  # Exit on any error
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository information
GITHUB_REPO="stafne/hp_sleep_mac"
GITHUB_API_BASE="https://api.github.com"

echo "============================================================"
echo "🚀 HP Py Sleep - Standalone Installer"
echo "============================================================"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This installer is designed for macOS only.${NC}"
    echo "Current OS: $OSTYPE"
    exit 1
fi

echo -e "${BLUE}📱 Detected macOS system${NC}"
echo ""

# Check for required tools (jq optional)
check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl is required but not installed.${NC}"
        echo "Please install curl and try again."
        exit 1
    fi
    echo -e "${GREEN}✅ curl is available${NC}"
    
    if command -v jq &> /dev/null; then
        JQ_AVAILABLE=1
        echo -e "${GREEN}✅ jq is available${NC}"
    else
        JQ_AVAILABLE=0
        echo -e "${YELLOW}⚠️  jq not found; will use simplified API parsing and DMG fallback${NC}"
    fi
    
    echo ""
}

# Get latest release information (uses jq when available)
get_latest_release() {
    echo -e "${BLUE}📡 Fetching latest release information...${NC}"
    
    local api_url="${GITHUB_API_BASE}/repos/${GITHUB_REPO}/releases/latest"
    local response
    local temp_file
    
    temp_file=$(mktemp)
    
    # Download with better error handling
    if ! curl -s -L -o "$temp_file" "$api_url"; then
        echo -e "${RED}❌ Failed to fetch release information${NC}"
        rm -f "$temp_file"
        exit 1
    fi
    
    if [[ "$JQ_AVAILABLE" -eq 1 ]]; then
        # Validate JSON
        if ! jq empty "$temp_file" 2>/dev/null; then
            echo -e "${RED}❌ Invalid JSON response from GitHub API${NC}"
            echo "Response content:"
            cat "$temp_file"
            rm -f "$temp_file"
            exit 1
        fi
    fi
    
    # Check if response contains error
    if [[ "$JQ_AVAILABLE" -eq 1 ]]; then
        if jq -e '.message' "$temp_file" &> /dev/null; then
            local error_msg
            error_msg=$(jq -r '.message' "$temp_file")
            echo -e "${RED}❌ GitHub API error: $error_msg${NC}"
            rm -f "$temp_file"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Latest release information retrieved${NC}"
    cat "$temp_file"
    rm -f "$temp_file"
}

# Find the ZIP asset
find_zip_asset() {
    local release_data="$1"
    local asset_name
    local temp_file
    
    temp_file=$(mktemp)
    echo "$release_data" > "$temp_file"
    
    if [[ "$JQ_AVAILABLE" -eq 1 ]]; then
        asset_name=$(jq -r '.assets[] | select(.name | endswith(".zip") and (contains("hp_py_sleep") or contains("hp_sleep"))) | .name' "$temp_file" | head -1)
    else
        # crude grep fallback
        asset_name=$(grep -o '"name"\s*:\s*"[^"]*\.zip"' "$temp_file" | grep -E 'hp_py_sleep|hp_sleep' | head -1 | sed -E 's/.*:"([^"]+)"/\1/')
    fi
    
    if [ -z "$asset_name" ] || [ "$asset_name" = "null" ]; then
        echo -e "${RED}❌ No ZIP asset found in the latest release${NC}"
        echo "Available assets:"
        jq -r '.assets[].name' "$temp_file"
        rm -f "$temp_file"
        exit 1
    fi
    
    rm -f "$temp_file"
    echo "$asset_name"
}

# Download the release asset
download_asset() {
    local release_data="$1"
    local asset_name="$2"
    local download_url
    local file_size
    local temp_file
    
    temp_file=$(mktemp)
    echo "$release_data" > "$temp_file"
    
    if [[ "$JQ_AVAILABLE" -eq 1 ]]; then
        download_url=$(jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url" "$temp_file")
        file_size=$(jq -r ".assets[] | select(.name == \"$asset_name\") | .size" "$temp_file")
    else
        download_url=$(grep -A5 "\"name\": \"$asset_name\"" "$temp_file" | grep -o '"browser_download_url"\s*:\s*"[^"]*"' | head -1 | sed -E 's/.*:"([^"]+)"/\1/')
        file_size=0
    fi
    
    rm -f "$temp_file"
    
    echo -e "${BLUE}📥 Downloading: $asset_name${NC}"
    echo -e "${BLUE}📊 Size: $((file_size / 1024 / 1024)) MB${NC}"
    echo ""
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Download the file
    local zip_path="${temp_dir}/${asset_name}"
    
    if ! curl -L -o "$zip_path" "$download_url"; then
        echo -e "${RED}❌ Failed to download $asset_name${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Download completed${NC}"
    echo "$zip_path"
}

# Install the application
install_app_from_zip() {
    local zip_path="$1"
    local temp_dir
    local app_name
    
    temp_dir=$(dirname "$zip_path")
    
    echo -e "${BLUE}📦 Extracting application...${NC}"
    
    # Extract the ZIP file
    if ! unzip -q "$zip_path" -d "$temp_dir"; then
        echo -e "${RED}❌ Failed to extract ZIP file${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Find the .app file
    app_name=$(find "$temp_dir" -name "*.app" -type d | head -1)
    
    if [ -z "$app_name" ]; then
        echo -e "${RED}❌ No .app file found in the downloaded package${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    local app_basename
    app_basename=$(basename "$app_name")
    local app_destination="/Applications/$app_basename"
    
    echo -e "${BLUE}📱 Found app: $app_basename${NC}"
    
    # Remove existing installation if it exists
    if [ -d "$app_destination" ]; then
        echo -e "${YELLOW}⚠️  Removing existing installation...${NC}"
        rm -rf "$app_destination"
    fi
    
    # Copy to Applications folder
    echo -e "${BLUE}📂 Installing to Applications folder...${NC}"
    
    if ! ditto --noqtn "$app_name" "/Applications/$(basename "$app_name")" 2>/dev/null; then
        # fallback copy
        if ! cp -R "$app_name" "/Applications/"; then
        echo -e "${RED}❌ Failed to install to Applications folder${NC}"
        echo "You may need to run with sudo or check permissions."
        rm -rf "$temp_dir"
        exit 1
        fi
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    echo ""
    echo -e "${GREEN}🎉 HP Py Sleep has been installed to: $app_destination${NC}"
    echo ""
    
    # Show security notice
    echo -e "${YELLOW}⚠️  IMPORTANT: Security Notice${NC}"
    echo ""
    echo "Since this app is not code-signed, macOS will show a security warning."
    echo ""
    echo -e "${BLUE}To launch HP Py Sleep:${NC}"
    echo "1. Open Applications, locate hp_py_sleep_mac.app"
    echo "2. Right-click → Open"
    echo "3. If blocked: Apple menu → System Settings → Privacy & Security → 'hp_py_sleep_mac.app was blocked' → Open Anyway"
    echo "4. The app will launch"
    echo ""
    echo -e "${BLUE}Note:${NC} You only need to do this once. After that, you can launch normally."
    echo ""
    
    # Ask if user wants to launch
    echo -e "${BLUE}Would you like to launch HP Py Sleep now? (y/n):${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🚀 Launching HP Py Sleep...${NC}"
        open "$app_destination"
        echo ""
        echo -e "${YELLOW}If you see a security warning, right-click the app and select 'Open'.${NC}"
    fi
}

# DMG preferred install
install_app_from_dmg_latest() {
    local dmg_url="https://github.com/${GITHUB_REPO}/releases/latest/download/hp_py_sleep_mac.dmg"
    local tmpdmg
    tmpdmg=$(mktemp -t hp_py_sleep_mac.dmg.XXXXXX)
    echo -e "${BLUE}📥 Downloading DMG...${NC}"
    if ! curl -L -o "$tmpdmg" "$dmg_url"; then
        echo -e "${YELLOW}⚠️  DMG download failed; will try ZIP method${NC}"
        return 1
    fi
    echo -e "${BLUE}💿 Attaching DMG...${NC}"
    local mount_point
    mount_point=$(hdiutil attach -nobrowse -noautoopen "$tmpdmg" | awk '/Volumes\//{print $3; exit}') || true
    if [[ -z "$mount_point" ]]; then
        echo -e "${YELLOW}⚠️  Could not mount DMG; will try ZIP method${NC}"
        rm -f "$tmpdmg"
        return 1
    fi
    local app_src="$mount_point/hp_py_sleep_mac.app"
    if [[ ! -d "$app_src" ]]; then
        echo -e "${YELLOW}⚠️  App not found in DMG; will try ZIP method${NC}"
        hdiutil detach "$mount_point" >/dev/null 2>&1 || true
        rm -f "$tmpdmg"
        return 1
    fi
    echo -e "${BLUE}📂 Installing to Applications...${NC}"
    sudo rm -rf "/Applications/HP Py Sleep.app" "/Applications/hp_py_sleep_mac.app" 2>/dev/null || true
    if ! sudo ditto --noqtn "$app_src" "/Applications/hp_py_sleep_mac.app"; then
        echo -e "${RED}❌ Failed to copy app to Applications from DMG${NC}"
        hdiutil detach "$mount_point" >/dev/null 2>&1 || true
        rm -f "$tmpdmg"
        return 1
    fi
    hdiutil detach "$mount_point" >/dev/null 2>&1 || true
    rm -f "$tmpdmg"
    echo -e "${GREEN}✅ Installed via DMG${NC}"
    return 0
}

# Main installation process
main() {
    echo -e "${BLUE}Starting HP Py Sleep installation...${NC}"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Try DMG first (no jq required)
    if install_app_from_dmg_latest; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
        echo -e "${BLUE}HP Py Sleep is now available in your Applications folder.${NC}"
        exit 0
    fi

    # Fallback: ZIP via GitHub API
    local release_data
    release_data=$(get_latest_release)
    
    local version
    if [[ "$JQ_AVAILABLE" -eq 1 ]]; then
        version=$(echo "$release_data" | jq -r '.tag_name')
    else
        version=$(echo "$release_data" | grep -o '"tag_name"\s*:\s*"[^"]*"' | head -1 | sed -E 's/.*:"([^"]+)"/\1/')
    fi
    echo -e "${GREEN}📋 Found version: $version${NC}"
    echo ""
    
    local asset_name
    asset_name=$(find_zip_asset "$release_data")
    echo -e "${GREEN}📦 Found asset: $asset_name${NC}"
    echo ""
    
    # Ask for confirmation
    echo -e "${BLUE}Ready to download and install HP Py Sleep $version${NC}"
    echo -e "${BLUE}Continue? (y/n):${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    echo ""
    
    # Download and install
    local zip_path
    zip_path=$(download_asset "$release_data" "$asset_name")
    install_app_from_zip "$zip_path"
    
    echo ""
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo -e "${BLUE}HP Py Sleep is now available in your Applications folder.${NC}"
}

# Run main function
main "$@"
