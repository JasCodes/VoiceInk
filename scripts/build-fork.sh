#!/bin/bash
set -e

# Configuration
FORK_VERSION_FILE=".fork_version"
SCHEME="VoiceInk"
CONFIGURATION="Release"
EXPORT_PATH="./build"

# Ensure agvtool is available
if ! command -v agvtool &> /dev/null; then
    echo "Error: agvtool is not installed (part of Xcode Command Line Tools)"
    exit 1
fi

# Get upstream build version (from project.pbxproj)
# Use xcodebuild for reliability as agvtool was returning empty strings
UPSTREAM_VERSION=$(agvtool what-version -terse | tr -d '\n')
MARKETING_VERSION=$(xcodebuild -showBuildSettings 2>/dev/null | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')

if [ -z "$MARKETING_VERSION" ]; then
    echo "Error: Could not determine MARKETING_VERSION"
    exit 1
fi

echo "Base Version: $MARKETING_VERSION"
echo "Upstream Build: $UPSTREAM_VERSION"

# Manage Fork Version
if [ ! -f "$FORK_VERSION_FILE" ]; then
    echo "1" > "$FORK_VERSION_FILE"
fi

FORK_BUILD_NUM=$(cat "$FORK_VERSION_FILE")
NEW_FORK_BUILD_NUM=$((FORK_BUILD_NUM + 1))

# Construct Compound Version
COMPOUND_VERSION="${UPSTREAM_VERSION}-JC.${FORK_BUILD_NUM}"

echo "Building Fork Version: $COMPOUND_VERSION"

# Signing Configuration
# We rely on Local.xcconfig for DEVELOPMENT_TEAM.
# We force "Developer ID Application" so it finds the cert for that team.
echo "Signing with Developer ID Application..."

xcodebuild -project VoiceInk.xcodeproj \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -archivePath "$EXPORT_PATH/VoiceInk.xcarchive" \
           CURRENT_PROJECT_VERSION="$COMPOUND_VERSION" \
           archive

# Package into ZIP for distribution (Homebrew/Sparkle)
echo "Packaging into ZIP..."
# Package into ZIP for distribution (Homebrew/Sparkle)
echo "Packaging into ZIP..."
APPS_DIR="$EXPORT_PATH/VoiceInk.xcarchive/Products/Applications"
# Find the .app inside the directory (there should only be one)
APP_PATH=$(find "$APPS_DIR" -maxdepth 1 -name "*.app" | head -n 1)

ZIP_PATH="$EXPORT_PATH/VoiceInk.zip"

if [ -d "$APP_PATH" ]; then
    APP_NAME=$(basename "$APP_PATH")
    echo "Found App: $APP_NAME"
    
    # -c: create, -k: PKZip, --keepParent: include *.app folder in zip
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    echo "Created Release Artifact: $ZIP_PATH"
else
    echo "Error: No App found in $APPS_DIR"
    exit 1
fi

echo "Build Complete: VoiceInk $MARKETING_VERSION ($COMPOUND_VERSION)"

# Increment fork version for next time
echo "$NEW_FORK_BUILD_NUM" > "$FORK_VERSION_FILE"
echo "Next fork build number will be: $NEW_FORK_BUILD_NUM"
