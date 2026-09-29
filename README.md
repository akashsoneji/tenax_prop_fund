# Tenax Prop — Flutter app (white-label)

One Flutter codebase that ships as a separate app for each client (flavor).

## Flavors

| Flavor | Config file | Assets folder |
|---|---|---|
| `tenax` | `config/flavors/tenax.json` | `assets/flavors/tenax/` |
| `client_a` | `config/flavors/client_a.json` | `assets/flavors/client_a/` |
| `client_b` | `config/flavors/client_b.json` | `assets/flavors/client_b/` |
| `client_c` | `config/flavors/client_c.json` | `assets/flavors/client_c/` |
| `pipze_funded` | `config/flavors/pipze_funded.json` | `assets/flavors/pipze_funded/` |
| `alibabafx_prop` | `config/flavors/alibabafx_prop.json` | `assets/flavors/alibabafx_prop/` |

## Run & build

`--dart-define-from-file` is **required**. Without it the app stops at startup with `Missing flavor defines: …`.

```shell
# Run (debug)
flutter run --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=development

# Android APK / App Bundle
flutter build apk --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production
flutter build appbundle --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production

# iOS
flutter build ios --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production
```

Replace `pipze_funded` with any flavor from the table. The `--flavor` value and the JSON file name must match.
In VS Code, pick a config such as "Pipze Funded — Debug" from the Run dropdown and press F5. `.vscode/launch.json` already passes the right file.

`ENV` is `development`, `staging` or `production`.

## Client data isolation (important)

A build contains **only its own client's** data. If someone decompiles or reverse-engineers the Pipze app, they must not find AlibabaFX (or any other client's) URLs, name, colors or logo.

This is how the codebase guarantees it:
- Client-specific URLs, name, colors and feature flags live **only** in `config/flavors/<flavor>.json`. The build compiles in just the one file you pass. There is no client host or brand name in `lib/`.
- Client images live in `assets/flavors/<flavor>/`. `pubspec.yaml` maps each folder to its flavor, so only that client's images are bundled.

Rules for everyone:
- **Never** hardcode a client URL, name, color, logo path or key in Dart code. Add it to the JSON file and read it through `FlavorConfig`.
- **Never** put a client image in a shared folder. Put it in `assets/flavors/<flavor>/`.
- Adding a new asset folder for a client? Add it in `pubspec.yaml` with `flavors: [<flavor>]`.

Check a build before release. Replace the strings with other clients' values:

```shell
unzip -o build/app/outputs/flutter-apk/app-pipze_funded-release.apk -d /tmp/apk
unzip -l build/app/outputs/flutter-apk/app-pipze_funded-release.apk | grep assets/flavors/   # only pipze_funded
LC_ALL=C grep -a -c -F "alibabafx" /tmp/apk/lib/arm64-v8a/libapp.so                        # must be 0
```

Note: the JSON files are **not secret**. Anything inside a client's own app can be read from that app. They only keep clients separate from each other. Never put a private key or password in them.

## Adding a new client

1. Copy `config/flavors/tenax.json` to `config/flavors/<new_flavor>.json` and fill in its values.
2. Create `assets/flavors/<new_flavor>/` with `logo.png` and `splash.png`.
3. Add the folder to `pubspec.yaml` with `flavors: [<new_flavor>]`.
4. Add the Android `productFlavor` in `android/app/build.gradle.kts` and the iOS scheme (`scripts/setup_ios_flavors.sh`).
5. Add the value to `Flavor` / `Flavor.fromName` in `lib/app/flavor/flavor.dart`.
6. Add Debug and Release entries to `.vscode/launch.json`.

## API docs

- `docs/API_REFERENCE.md`: every endpoint, with params and payloads.
- `docs/TenaxProp-Mobile-App-API.postman_collection.json`: Postman collection. Regenerate it with `python3 docs/tool/build_postman.py`.
