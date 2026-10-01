#!/usr/bin/env bash
# Writes the per-flavor xcconfig files (tenax / pipze_funded / alibabafx_prop)
# used by the iOS Debug/Release build configurations, plus each flavor's
# launch-screen colour. Idempotent: running twice is safe.

set -eo pipefail

PROJECT="ios/Runner.xcodeproj/project.pbxproj"

if [[ ! -f "$PROJECT" ]]; then
  echo "Error: $PROJECT not found. Run from project root." >&2
  exit 1
fi

# Per-flavor launch-screen background colour (hex, no #) — each flavor's
# primary colour. macOS ships bash 3.2 (no associative arrays), so use a case.
FLAVORS=(tenax pipze_funded alibabafx_prop)

splash_color() {
  case "$1" in
    tenax)          echo "5F259E" ;;
    pipze_funded)   echo "5F259E" ;;
    alibabafx_prop) echo "182430" ;;
  esac
}

for FLAVOR in "${FLAVORS[@]}"; do
  BG_COLOR="$(splash_color "$FLAVOR")"
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
echo "      flavor xcconfig above: tenax.xcconfig / pipze_funded.xcconfig / alibabafx_prop.xcconfig)."
echo "  3. Product > Scheme > Manage Schemes > duplicate 'Runner' three times"
echo "     as tenax / pipze_funded / alibabafx_prop, each pointing to its build config."
echo ""
echo "After that, launch.json picks the flavor automatically (see args there)."
echo ""
echo "Launch background color for each flavor:"
for FLAVOR in "${FLAVORS[@]}"; do
  printf "  %-15s -> #%s\n" "$FLAVOR" "$(splash_color "$FLAVOR")"
done
