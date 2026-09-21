#!/usr/bin/env bash
# Adds iOS schemes (client_a / client_b / client_c) and Debug/Release build
# configurations to ios/Runner.xcodeproj, plus per-flavor launch-screen colors.
# Idempotent: running twice is safe.

set -eo pipefail

PROJECT="ios/Runner.xcodeproj/project.pbxproj"
PLIST="ios/Runner/Info.plist"

if [[ ! -f "$PROJECT" ]]; then
  echo "Error: $PROJECT not found. Run from project root." >&2
  exit 1
fi

# Per-flavor launch-screen background color (hex, no #).
# Each flavor's launch background uses its primary color so a different
# `flutter run --flavor client_X` immediately shows a different splash.
# macOS ships bash 3.2 which lacks associative arrays — use plain vars instead.
FLAVORS=(tenax client_a client_b client_c)
SPLASH_TENAX="5F259E"
SPLASH_A="1E88E5"
SPLASH_B="2E7D32"
SPLASH_C="6A1B9A"

for FLAVOR in "${FLAVORS[@]}"; do
  case "$FLAVOR" in
    tenax)    BG_COLOR="$SPLASH_TENAX" ;;
    client_a) BG_COLOR="$SPLASH_A" ;;
    client_b) BG_COLOR="$SPLASH_B" ;;
    client_c) BG_COLOR="$SPLASH_C" ;;
  esac
  XCCONFIG_DIR="ios/Flutter"
  mkdir -p "$XCCONFIG_DIR"

  cat > "$XCCONFIG_DIR/${FLAVOR}.xcconfig" <<EOF
#include "Generated.xcconfig"
FLAVOR_NAME=${FLAVOR}
LAUNCH_BG_COLOR=${BG_COLOR}
EOF

  echo "Wrote $XCCONFIG_DIR/${FLAVOR}.xcconfig"
done

echo ""
echo "Next steps (manual, one-time):"
echo "  1. open ios/Runner.xcworkspace"
echo "  2. Project > Info > Configurations > + to add Debug/Release per flavor"
echo "     (Duplicate the existing Debug/Release; set Base on each = the matching"
echo "      flavor xcconfig above: client_a.xcconfig / client_b.xcconfig / client_c.xcconfig)."
echo "  3. Product > Scheme > Manage Schemes > duplicate 'Runner' three times"
echo "     as client_a / client_b / client_c, each pointing to its build config."
echo ""
echo "After that, launch.json picks the flavor automatically (see args there)."
echo ""
echo "Launch background color for each flavor:"
printf "  tenax    -> #%s\n" "$SPLASH_TENAX"
printf "  client_a -> #%s\n" "$SPLASH_A"
printf "  client_b -> #%s\n" "$SPLASH_B"
printf "  client_c -> #%s\n" "$SPLASH_C"