#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_ROOT="$PROJECT_ROOT/work/release-build"
MODULE_CACHE="$PROJECT_ROOT/work/swift-module-cache"
APP="$PROJECT_ROOT/dist/MacAutoTranslate.app"
UNIVERSAL_BUILD="${MAC_AUTO_TRANSLATE_UNIVERSAL:-0}"

mkdir -p "$MODULE_CACHE"

run_swift_build() {
    CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
    SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" \
    swift build --disable-sandbox --package-path "$PROJECT_ROOT" --scratch-path "$BUILD_ROOT" "$@"
}

case "$UNIVERSAL_BUILD" in
    0)
        run_swift_build -c release --product MacAutoTranslate
        BIN_DIR=$(run_swift_build -c release --show-bin-path)
        ;;
    1)
        run_swift_build -c release --product MacAutoTranslate --arch arm64 --arch x86_64
        BIN_DIR=$(run_swift_build -c release --show-bin-path --arch arm64 --arch x86_64)
        ;;
    *)
        echo "MAC_AUTO_TRANSLATE_UNIVERSAL must be 0 or 1." >&2
        exit 1
        ;;
esac

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MacAutoTranslate" "$APP/Contents/MacOS/MacAutoTranslate"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_ROOT/Resources/MenuBarIcon.png" "$APP/Contents/Resources/MenuBarIcon.png"
cp "$PROJECT_ROOT/Resources/MenuBarIcon@2x.png" "$APP/Contents/Resources/MenuBarIcon@2x.png"
chmod 755 "$APP/Contents/MacOS/MacAutoTranslate"
codesign --force --deep --sign - "$APP"

echo "Built $APP"
