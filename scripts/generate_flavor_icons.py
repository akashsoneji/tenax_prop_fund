"""Builds a flavor's app icons from its single logo image.

Source (first one found):
  assets/flavors/<flavor>/app_icon.png   (optional, dedicated launcher art)
  assets/flavors/<flavor>/logo.png

Outputs:
  ios/flavors/<flavor>/AppIcon.appiconset/*               (no alpha; iOS rejects it)
  android/app/src/<flavor>/res/mipmap-*/ic_launcher.png

Runs automatically from scripts/prepare_ios_flavor.sh (the VS Code preLaunchTask),
so replacing the PNG and re-launching is enough. Skips work when outputs are newer
than the source.
"""
import json
import shutil
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("[icons] Pillow not installed (pip3 install pillow) — skipping icon generation.")
    sys.exit(0)

ROOT = Path(__file__).resolve().parents[1]
ANDROID_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def main(flavor: str) -> None:
    asset_dir = ROOT / "assets/flavors" / flavor
    source = next(
        (p for p in (asset_dir / "app_icon.png", asset_dir / "logo.png") if p.exists()),
        None,
    )
    if source is None:
        print(f"[icons] No app_icon.png/logo.png in {asset_dir} — keeping default icon.")
        return

    ios_set = ROOT / "ios/flavors" / flavor / "AppIcon.appiconset"
    android_res = ROOT / "android/app/src" / flavor / "res"
    marker = ios_set / "Icon-App-1024x1024@1x.png"
    if marker.exists() and marker.stat().st_mtime >= source.stat().st_mtime:
        print(f"[icons] {flavor} icons up to date.")
        return

    config = json.loads((ROOT / "config/flavors" / f"{flavor}.json").read_text())
    background = "#" + config.get("PRIMARY_COLOR", "000000").lstrip("#")

    image = Image.open(source).convert("RGBA")
    flat = Image.new("RGB", image.size, background)
    flat.paste(image, mask=image.split()[3])

    runner_set = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((runner_set / "Contents.json").read_text())
    ios_set.mkdir(parents=True, exist_ok=True)
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        pixels = round(float(entry["size"].split("x")[0]) * int(entry["scale"].rstrip("x")))
        flat.resize((pixels, pixels), Image.LANCZOS).save(ios_set / filename)
    shutil.copy(runner_set / "Contents.json", ios_set / "Contents.json")

    for density, pixels in ANDROID_SIZES.items():
        out = android_res / f"mipmap-{density}"
        out.mkdir(parents=True, exist_ok=True)
        image.resize((pixels, pixels), Image.LANCZOS).save(out / "ic_launcher.png")

    print(f"[icons] {flavor} icons generated from {source.relative_to(ROOT)}.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python3 scripts/generate_flavor_icons.py <flavor>")
    main(sys.argv[1])
