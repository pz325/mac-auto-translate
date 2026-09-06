#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODE="${1:-}"

fail() {
    echo "Release stopped: $1" >&2
    exit 1
}

case "$MODE" in
    ""|--dry-run) ;;
    *) fail "usage: ./scripts/release.sh [--dry-run]" ;;
esac

cd "$PROJECT_ROOT"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
printf '%s\n' "$VERSION" | rg -q '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "Info.plist version must use X.Y.Z format."
TAG="v$VERSION"

[ -z "$(git status --porcelain)" ] || {
    git status --short >&2
    fail "commit or stash all changes before creating a release tag."
}

git fetch --quiet origin || fail "could not refresh the origin remote."
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) || fail "the current branch has no upstream."
[ "$(git rev-parse HEAD)" = "$(git rev-parse "$UPSTREAM")" ] || fail "push the current commit before creating the tag."

git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null && fail "$TAG already exists locally."
REMOTE_TAG=$(git ls-remote --tags origin "refs/tags/$TAG") || fail "could not check remote tags."
[ -z "$REMOTE_TAG" ] || fail "$TAG already exists on origin."

./scripts/check-secrets.sh
git diff --check

TEST_MODULE_CACHE="$PROJECT_ROOT/work/release-test-module-cache"
mkdir -p "$TEST_MODULE_CACHE"
CLANG_MODULE_CACHE_PATH="$TEST_MODULE_CACHE" \
SWIFTPM_MODULECACHE_OVERRIDE="$TEST_MODULE_CACHE" \
swift test --disable-sandbox --scratch-path "$PROJECT_ROOT/work/release-test-build"

if [ "$MODE" = "--dry-run" ]; then
    echo "Dry run passed. $TAG is ready to publish."
    exit 0
fi

git tag -a "$TAG" -m "MacAutoTranslate $VERSION"
git push origin "$TAG"
echo "Published $TAG. GitHub Actions will build and create the release."
