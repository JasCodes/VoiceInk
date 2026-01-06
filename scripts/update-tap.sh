#!/bin/bash
set -e

TAP_REPO_URL="git@github.com:jascodes/homebrew-tap.git"
TAP_DIR="../homebrew-tap"
ZIP_PATH="./build/VoiceInk.zip"

# Extract Version
MARKETING_VERSION=$(xcodebuild -showBuildSettings 2>/dev/null | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')
if [ -z "$MARKETING_VERSION" ]; then
    MARKETING_VERSION="1.0"
fi
FORK_BUILD_NUM=$(cat ".fork_version") 
BUILT_FORK_NUM=$((FORK_BUILD_NUM - 1))
VERSION="$MARKETING_VERSION-JC.$BUILT_FORK_NUM"


if [ -z "$VERSION" ]; then
    echo "Error: VERSION is empty!"
    exit 1
fi

echo "Detected Version: $VERSION"
# Detect App Name from Zip
# zipinfo -1 lists file names only. We look for the top-level folder ending in .app/
APP_NAME_IN_ZIP=$(zipinfo -1 "$ZIP_PATH" | grep -m 1 "\.app/$" | sed 's/\/$//')

if [ -z "$APP_NAME_IN_ZIP" ]; then
    echo "Error: Could not detect .app name in zip"
    exit 1
fi

echo "Detected App Name: $APP_NAME_IN_ZIP"

if [ -z "$APP_NAME_IN_ZIP" ]; then
    # Fallback to grep without / at end if unzip format is different
     APP_NAME_IN_ZIP=$(unzip -l "$ZIP_PATH" | grep -o "[^ ]*\.app/" | head -n 1 | sed 's/\/$//')
fi

if [ -z "$APP_NAME_IN_ZIP" ]; then
    echo "Error: Could not detect .app name in zip"
    exit 1
fi

echo "Detected App Name: $APP_NAME_IN_ZIP"

# Clone/Pull Tap
if [ ! -d "$TAP_DIR" ]; then
    echo "Cloning homebrew-tap..."
    git clone "$TAP_REPO_URL" "$TAP_DIR"
else
    echo "Pulling homebrew-tap..."
    (cd "$TAP_DIR" && git pull)
fi

FORMULA_DIR="$TAP_DIR/Casks"
mkdir -p "$FORMULA_DIR"
FORMULA_PATH="$FORMULA_DIR/voiceink.rb"

# Create Formula if missing
if [ ! -f "$FORMULA_PATH" ]; then
    echo "Creating new formula at $FORMULA_PATH..."
    cat > "$FORMULA_PATH" <<EOF
cask "voiceink" do
  version "$VERSION"
  sha256 "$NEW_HASH"

  url "https://github.com/jascodes/voiceink/releases/download/v#{version}/VoiceInk.zip"
  name "VoiceInk"
  desc "Transcribe audio to text with ease"
  homepage "https://github.com/jascodes/voiceink"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "$APP_NAME_IN_ZIP"

  zap trash: [
    "~/Library/Application Support/VoiceInk",
    "~/Library/Caches/bio.jas.VoiceInk",
    "~/Library/Preferences/bio.jas.VoiceInk.plist",
  ]
end
EOF
else
    echo "Updating existing formula..."
    # Update version and sha256
    sed -i '' "s|version \".*\"|version \"$VERSION\"|g" "$FORMULA_PATH"
    sed -i '' "s|sha256 \".*\"|sha256 \"$NEW_HASH\"|g" "$FORMULA_PATH"
fi

echo "Commiting changes to Homebrew Tap..."
(cd "$TAP_DIR" && git add . && git commit -m "Update VoiceInk to $VERSION" && git push)

echo "Homebrew Tap Updated!"
