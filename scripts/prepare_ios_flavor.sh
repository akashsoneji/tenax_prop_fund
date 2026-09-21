#!/usr/bin/env bash
# Prepares iOS native assets for the given flavor BEFORE a build/run.
# Wired as a preLaunchTask in .vscode/launch.json so every time you pick a
# flavor in VS Code and hit Run, the correct app icon + launch-screen color
# are copied into the Runner target.
#
# Usage: scripts/prepare_ios_flavor.sh <client_a|client_b|client_c>
#
# Per-flavor source assets live in:
#   ios/flavors/<flavor>/AppIcon.appiconset/   (optional; full iOS icon set)
#   ios/flavors/<flavor>/splash_color.txt      (hex color, no #)
# If a flavor folder is missing an icon set, the default icon is kept.

set -eo pipefail

FLAVOR="${1:-}"
if [[ -z "$FLAVOR" ]]; then
  echo "Usage: $0 <client_a|client_b|client_c>" >&2
  exit 1
fi

case "$FLAVOR" in
  tenax)    DEFAULT_COLOR="5F259E" ;;
  client_a) DEFAULT_COLOR="1E88E5" ;;
  client_b) DEFAULT_COLOR="2E7D32" ;;
  client_c) DEFAULT_COLOR="6A1B9A" ;;
  *) echo "Unknown flavor: $FLAVOR" >&2; exit 1 ;;
esac

SRC_DIR="ios/flavors/$FLAVOR"
ICONSET_DST="ios/Runner/Assets.xcassets/AppIcon.appiconset"
LAUNCH_COLORSET="ios/Runner/Assets.xcassets/LaunchBackground.colorset"

# 1. App icon — copy the flavor's icon set over the Runner's if provided.
if [[ -d "$SRC_DIR/AppIcon.appiconset" ]]; then
  rm -rf "$ICONSET_DST"
  cp -R "$SRC_DIR/AppIcon.appiconset" "$ICONSET_DST"
  echo "[iOS] AppIcon set from $SRC_DIR/AppIcon.appiconset"
else
  echo "[iOS] No flavor icon at $SRC_DIR/AppIcon.appiconset — keeping default."
fi

# 2. Launch-screen background color — write a color asset the storyboard reads.
COLOR_HEX="$DEFAULT_COLOR"
if [[ -f "$SRC_DIR/splash_color.txt" ]]; then
  COLOR_HEX="$(tr -d '#[:space:]' < "$SRC_DIR/splash_color.txt")"
fi

# Convert hex -> 0..1 float components for the iOS color asset.
R=$(printf '%d' "0x${COLOR_HEX:0:2}")
G=$(printf '%d' "0x${COLOR_HEX:2:2}")
B=$(printf '%d' "0x${COLOR_HEX:4:2}")
RF=$(awk "BEGIN{printf \"%.4f\", $R/255}")
GF=$(awk "BEGIN{printf \"%.4f\", $G/255}")
BF=$(awk "BEGIN{printf \"%.4f\", $B/255}")

mkdir -p "$LAUNCH_COLORSET"
cat > "$LAUNCH_COLORSET/Contents.json" <<EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$BF",
          "green" : "$GF",
          "red" : "$RF"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

echo "[iOS] LaunchBackground color set to #$COLOR_HEX (flavor: $FLAVOR)"
echo "[iOS] Flavor '$FLAVOR' prepared."