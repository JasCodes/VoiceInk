#!/bin/bash
set -e

ZIP_PATH="./build/VoiceInk.zip"

# Ensure gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed."
    exit 1
fi

# Extract Version
MARKETING_VERSION=$(xcodebuild -showBuildSettings 2>/dev/null | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')
if [ -z "$MARKETING_VERSION" ]; then
    MARKETING_VERSION="1.0"
fi

# Read fork build number (we need the one that was JUST built, so read current and subtract 1 if it was incremented)
FORK_BUILD_NUM=$(cat ".fork_version") 
BUILT_FORK_NUM=$((FORK_BUILD_NUM - 1))
VERSION="$MARKETING_VERSION-JC.$BUILT_FORK_NUM"

echo "Detected Built Version: $VERSION"

if [ ! -f "$ZIP_PATH" ]; then
    echo "Error: $ZIP_PATH not found. Please run 'make release-build' first."
    exit 1
fi

echo "Creating GitHub Release v$VERSION..."
# Explicitly target the fork
gh release create "v$VERSION" "$ZIP_PATH" --repo "jascodes/voiceink" --generate-notes --title "v$VERSION"

echo "Release URL: https://github.com/jascodes/voiceink/releases/tag/v$VERSION"
