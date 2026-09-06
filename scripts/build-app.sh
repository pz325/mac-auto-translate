#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_ROOT="$PROJECT_ROOT/work/release-build"
MODULE_CACHE="$PROJECT_ROOT/work/swift-module-cache"
APP="$PROJECT_ROOT/dist/MacAutoTranslate.app"

mkdir -p "$MODULE_CACHE"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" \
swift build --disable-sandbox --package-path "$PROJECT_ROOT" --scratch-path "$BUILD_ROOT" -c release --product MacAutoTranslate

BIN_DIR=$(CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" \
    swift build --disable-sandbox --package-path "$PROJECT_ROOT" --scratch-path "$BUILD_ROOT" -c release --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MacAutoTranslate" "$APP/Contents/MacOS/MacAutoTranslate"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_ROOT/Resources/MenuBarIconTemplate.png" "$APP/Contents/Resources/MenuBarIconTemplate.png"
cp "$PROJECT_ROOT/Resources/MenuBarIconTemplate@2x.png" "$APP/Contents/Resources/MenuBarIconTemplate@2x.png"
chmod 755 "$APP/Contents/MacOS/MacAutoTranslate"
codesign --force --deep --sign - "$APP"

echo "Built $APP"
