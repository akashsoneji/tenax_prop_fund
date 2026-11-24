#!/usr/bin/env bash
# Usage: ./build.sh <flavor> [apk|aab]
# Example: ./build.sh tenax      ->  build/release/tenax/TENAX_1.0.0_1_64bit.apk (+ 32bit)
#          ./build.sh tenax aab  ->  build/release/tenax/TENAX_1.0.0_1.aab  (Google Play)
#
# Every build is obfuscated and gets the flavor config as a scrambled blob
# (tool/encode_flavor_config.dart), so URLs and keys are not plain strings in
# the binary.
set -euo pipefail

cd "$(dirname "$0")"

FLAVOR="${1:-}"
TARGET="${2:-apk}"
CONFIG_DIR="config/flavors"

available_flavors() {
  for file in "$CONFIG_DIR"/*.json; do
    basename "$file" .json
  done
}

if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./build.sh <flavor> [apk|aab]"
  echo "Available flavors:"
  available_flavors | sed 's/^/  - /'
  exit 1
fi

if [[ "$TARGET" != "apk" && "$TARGET" != "aab" ]]; then
  echo "Unknown target: $TARGET (use apk or aab)"
  exit 1
fi

CONFIG="$CONFIG_DIR/$FLAVOR.json"
if [[ ! -f "$CONFIG" ]]; then
  echo "Unknown flavor: $FLAVOR"
  echo "Available flavors:"
  available_flavors | sed 's/^/  - /'
  exit 1
fi

# Release builds are signed with the flavor's own upload key; it is created on
# the first build and reused afterwards (Play rejects debug-signed bundles).
./scripts/generate_keystore.sh "$FLAVOR"

# pubspec "version: 1.0.0+1" -> VERSION_NAME=1.0.0, BUILD_NUMBER=1
VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -n 1 | awk '{print $2}')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE#*+}"
[[ "$BUILD_NUMBER" == "$VERSION_LINE" ]] && BUILD_NUMBER=0

# Every run bumps the build number in pubspec.yaml (1.0.0+1 -> 1.0.0+2) before building.
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
awk -v new_version="version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}" \
  '!done && /^version:/ { print new_version; done = 1; next } { print }' \
  pubspec.yaml > pubspec.yaml.tmp
mv pubspec.yaml.tmp pubspec.yaml

APP_PREFIX="$(echo "$FLAVOR" | tr '[:lower:]' '[:upper:]')"
APP_BASE="${APP_PREFIX}_${VERSION_NAME}_${NEW_BUILD_NUMBER}"
SYMBOLS_DIR="build/symbols/$FLAVOR"
OUTPUT_DIR="build/release/$FLAVOR"
SECURE_DEFINES="build/secure_defines/$FLAVOR.json"

echo "Building $TARGET for $FLAVOR (version ${VERSION_NAME}+${NEW_BUILD_NUMBER})"

flutter pub get
dart run tool/encode_flavor_config.dart "$FLAVOR" production

COMMON_ARGS=(
  --release
  --flavor "$FLAVOR"
  --dart-define-from-file="$SECURE_DEFINES"
  --obfuscate
  --split-debug-info="$SYMBOLS_DIR"
)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [[ "$TARGET" == "aab" ]]; then
  flutter build appbundle "${COMMON_ARGS[@]}"
  mv "build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab" "$OUTPUT_DIR/${APP_BASE}.aab"
else
  FLUTTER_APK_DIR="build/app/outputs/flutter-apk"
  # Two APKs: 64-bit (arm64-v8a) and 32-bit (armeabi-v7a). x86_64 is emulator-only, so it is not built.
  flutter build apk "${COMMON_ARGS[@]}" \
    --target-platform android-arm,android-arm64 \
    --split-per-abi
  mv "$FLUTTER_APK_DIR/app-arm64-v8a-$FLAVOR-release.apk" "$OUTPUT_DIR/${APP_BASE}_64bit.apk"
  mv "$FLUTTER_APK_DIR/app-armeabi-v7a-$FLAVOR-release.apk" "$OUTPUT_DIR/${APP_BASE}_32bit.apk"
  # Drop this flavor's leftover release files so only the renamed APKs remain.
  rm -f "$FLUTTER_APK_DIR"/app-*"$FLAVOR"-release.apk "$FLUTTER_APK_DIR"/app-*"$FLAVOR"-release.apk.sha1
fi

# The scrambled defines hold the key; do not leave them lying around.
rm -f "$SECURE_DEFINES"

echo ""
echo "Done. Output is in: $(pwd)/$OUTPUT_DIR"
ls -lh "$OUTPUT_DIR" | awk 'NR>1 {print "  " $5 "\t" $9}'
echo ""
echo "Keep $SYMBOLS_DIR safe - needed to read obfuscated crash stack traces (upload it to Play as the debug symbols)."
