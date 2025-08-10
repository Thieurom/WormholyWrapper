#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/pmusolino/Wormholy.git"
FRAMEWORK_NAME="Wormholy"
PACKAGE_NAME="WormholyWrapper"
SCHEME="$FRAMEWORK_NAME-iOS"
CONFIGURATION=Release
OUTPUT_DIR="output"
BUILD_DIR="$(pwd)/$OUTPUT_DIR"
WRAPPER_DIR="$(pwd)"
BIN_DIR="bin"

TAG="$1"
if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

# Check if tag already exists in this repository
if git tag -l | grep -q "^$TAG$"; then
  echo "❌ Tag '$TAG' already exists in this repository"
  echo "   Cannot rebuild existing tags to maintain version integrity"
  exit 1
fi

echo "▶ Cloning Wormholy@$TAG into $OUTPUT_DIR/wormholy_build..."
mkdir -p "$BUILD_DIR"
git -c advice.detachedHead=false clone --quiet --branch "$TAG" --depth 1 "$REPO_URL" "$BUILD_DIR/wormholy_build"
cd "$BUILD_DIR/wormholy_build"

PLATFORMS=("iphoneos" "iphonesimulator")
DESTINATIONS=("generic/platform=iOS" "generic/platform=iOS Simulator")
ARCHIVES=()

for i in "${!PLATFORMS[@]}"; do
  PLATFORM="${PLATFORMS[$i]}"
  DESTINATION="${DESTINATIONS[$i]}"

  echo "▶ Archiving for $PLATFORM..."

  ARCHIVE_PATH="$BUILD_DIR/${PLATFORM}.xcarchive"

  xcodebuild archive \
    -quiet \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -sdk "$PLATFORM" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | xcbeautify

  FRAMEWORK_PATH="$ARCHIVE_PATH/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"
  if [ ! -d "$FRAMEWORK_PATH" ]; then
    echo "Framework not found at: $FRAMEWORK_PATH"
    exit 1
  fi
  ARCHIVES+=("$(cd "$(dirname "$FRAMEWORK_PATH")" && pwd)/$FRAMEWORK_NAME.framework")
done

cd "$WRAPPER_DIR"

echo "▶ Creating XCFramework..."
XCFRAMEWORK_PATH="$BUILD_DIR/$FRAMEWORK_NAME.xcframework"
xcodebuild -create-xcframework \
  -framework "${ARCHIVES[0]}" \
  -framework "${ARCHIVES[1]}" \
  -output "$XCFRAMEWORK_PATH" \

echo "▶ Zipping XCFramework..."
ZIP_PATH="$BUILD_DIR/$FRAMEWORK_NAME.xcframework.zip"
(cd "$BUILD_DIR" && zip -rq "$(basename "$ZIP_PATH")" "$FRAMEWORK_NAME.xcframework")

echo "▶ Move to bin..."
mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/$FRAMEWORK_NAME.xcframework.zip"
mv "$ZIP_PATH" "$BIN_DIR/"

echo "▶ Cleaning output directory..."
rm -rf "$BUILD_DIR"

echo "✅ Successfully built and packaged Wormholy@$TAG"
echo "📦 Binary available at: $BIN_DIR/$FRAMEWORK_NAME.xcframework.zip"

