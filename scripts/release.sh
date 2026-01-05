#!/bin/bash
set -e

# Configuration
TAP_REPO_URL="git@github.com:jascodes/homebrew-tap.git"
TAP_DIR="../homebrew-tap"
BUILD_SCRIPT="./scripts/build-fork.sh"
ZIP_PATH="./build/VoiceInk.zip"

# Ensure gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed. Please install it (brew install gh) and login."
    exit 1
fi

# 1. Run the Build
echo "Step 1: Building Fork..."
$BUILD_SCRIPT

# Extract Version from the built app
# agvtool can be unreliable, so we use xcodebuild to get the source of truth
MARKETING_VERSION=$(xcodebuild -showBuildSettings 2>/dev/null | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')

# Fallback if xcodebuild fails (unlikely)
if [ -z "$MARKETING_VERSION" ]; then
    MARKETING_VERSION="1.0"
    echo "Warning: Could not detect MARKETING_VERSION, defaulting to 1.0"
fi
FORK_BUILD_NUM=$(cat ".fork_version") 
# Note: build-fork.sh increments AFTER build, so we need the CURRENT one (minus 1? No, it increments for NEXT time).
# Wait, look at build-fork.sh: it reads current, builds, THEN increments.
# So if we read .fork_version NOW, it is the NEXT one. We want the PREVIOUS one (the one just built).
BUILT_FORK_NUM=$((FORK_BUILD_NUM - 1))
VERSION="$MARKETING_VERSION-JC.$BUILT_FORK_NUM"

echo "Detected Built Version: $VERSION"

# 2. Release to GitHub
echo "Step 2: Creating GitHub Release v$VERSION..."
# Create release and upload zip
# --generate-notes autogenerates changelog from commits
# Explicitly target the fork to avoid permission errors if upstream is set
gh release create "v$VERSION" "$ZIP_PATH" --repo "jascodes/voiceink" --generate-notes --title "v$VERSION"

echo "Release URL: https://github.com/jascodes/voiceink/releases/tag/v$VERSION"
DOWNLOAD_URL="https://github.com/jascodes/voiceink/releases/download/v$VERSION/VoiceInk.zip"

# 3. Update Homebrew Tap
echo "Step 3: Updating Homebrew Tap..."

# Calculate Hash
NEW_HASH=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo "New Hash: $NEW_HASH"

# Clone/Pull Tap
if [ ! -d "$TAP_DIR" ]; then
    echo "Cloning homebrew-tap..."
    git clone "$TAP_REPO_URL" "$TAP_DIR"
else
    echo "Pulling homebrew-tap..."
    (cd "$TAP_DIR" && git pull)
fi

# Update Formula
FORMULA_PATH="$TAP_DIR/Casks/voiceink.rb"
if [ ! -f "$FORMULA_PATH" ]; then
    echo "Error: Formula not found at $FORMULA_PATH. Please create it first."
    exit 1
fi

# Use sed to update content
# MacOS sed requires empty extension for -i
# We look for lines starting with 'version', 'sha256', and 'url'
sed -i '' "s|version \".*\"|version \"$VERSION\"|g" "$FORMULA_PATH"
sed -i '' "s|sha256 \".*\"|sha256 \"$NEW_HASH\"|g" "$FORMULA_PATH"
# Only replace the specific release URL pattern to avoid breaking other things if structure changes
# But since the structure is standard, we can replace the whole line if it matches our pattern
# Or honestly, relying on variable interpolation in Ruby is better: url ".../v#{version}/VoiceInk.zip"
# If the ruby file uses #{version}, we DON'T need to update the URL line!
# Let's assume the Ruby file uses interpolation.

echo "Updated Formula. Committing..."
(cd "$TAP_DIR" && git add . && git commit -m "Update VoiceInk to $VERSION" && git push)

echo "Done! Release v$VERSION is live and Homebrew Tap is updated."
