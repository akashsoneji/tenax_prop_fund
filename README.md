# Tenax Prop — Flutter app (white-label)

One Flutter codebase that ships as a separate app for each client (flavor).

## Flavors

| Flavor | Config file | Assets folder |
|---|---|---|
| `tenax` | `config/flavors/tenax.json` | `assets/flavors/tenax/` |
| `pipze_funded` | `config/flavors/pipze_funded.json` | `assets/flavors/pipze_funded/` |
| `alibabafx_prop` | `config/flavors/alibabafx_prop.json` | `assets/flavors/alibabafx_prop/` |

All three flavors use the same UI, the same controllers and the same functionality. They differ only by config: colours, logo, app name and URLs.

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

## Per-flavor UI (one controller, many designs)

Each feature has **one** binding, controller, repository and set of models, and every flavor uses them. Only the UI can change per flavor.

```text
lib/features/<feature>/
├── bindings/      controllers/      models/      repositories/
├── views/
│   ├── <feature>_view.dart                  # common design (Tenax base)
│   └── flavor_overrides/
│       └── <feature>_view_<flavor>.dart     # only when the layout really differs
└── widgets/
    ├── <part>.dart                          # shared parts
    └── flavor_overrides/
        └── <part>_<flavor>.dart             # small per-flavor widget variant
```

Pick the cheapest option that works:

1. Only the colour, logo, name or a URL is different: put it in `config/flavors/<f>.json` and read it through `FlavorConfig`. Don't add a new file.
2. Only a text, icon or image is different: put it in config or under `assets/flavors/<f>/`.
3. One small widget is different: add `widgets/flavor_overrides/<part>_<flavor>.dart`.
4. The whole screen layout is different: add `views/flavor_overrides/<feature>_view_<flavor>.dart`.
5. The business logic is different: only then consider a separate controller.

Today no flavor has an override: every flavor gets the same screens. Steps 3–4 are only for when a flavor-specific design is explicitly requested.

The choice between views happens only in `lib/app/flavor/flavor_resolver.dart`, through `FlavorResolver.resolve(common:, overrides:)`. Never write `if (flavor == …)` inside a widget. To give one flavor its own screen:

1. Add `features/<feature>/views/flavor_overrides/<feature>_view_<flavor>.dart`. Build it from the shared widgets and the same controller as the common view.
2. Register it in the resolver, e.g. `overrides: {Flavor.pipzeFunded: const LoginViewPipze()}` in `FlavorResolver.loginView()`.

Nothing else changes: the binding, controller, repository and route stay shared.

## Reusable UI + flavors

### Rules

- **One UI for all three flavors.** `tenax`, `pipze_funded` and `alibabafx_prop` ship the same screens, controllers and behaviour. The only differences are config (colours, logo, app name, URLs). A flavor-specific screen is added only when explicitly requested, and only through `FlavorResolver` (see above). `Flavor.<x>` is never checked outside `lib/app/flavor/`.
- **Shared UI never imports feature code.** Widgets in `lib/shared/` take plain values (strings, colours, callbacks, child widgets), and each feature maps its own model onto them. The one exception is `lib/shared/bindings/positions_binding.dart`, because a binding has to know the classes it wires.
- **Reusable never costs speed.**
  - Shared widgets are `StatelessWidget`s with no `Obx` or `Get.find` inside. The feature wraps only the changing value in `Obx` and passes it in (e.g. `AppSymbolCard(quote: Obx(() => AppSymbolQuote(...)))`). A price tick then rebuilds one tile, not the list.
  - Live tiles (`AppPriceTile`, `AppMetricStrip`) sit in a `RepaintBoundary`.
  - `AppText` caches the font per weight, so styles are built once, not on every rebuild.
- **Same look, exact values.** A one-off design (a unique radius, colour or padding) stays a private widget in its feature rather than being bent onto a shared one.
- Spacing tokens live in `lib/shared/theme/app_spacing.dart`. Use `Gap.vLg` / `Gap.hSm`, or `14.verticalSpace` for values off the scale, instead of `SizedBox(height: 14.h)`.

### Catalogue (`lib/shared/`)

**Text**
- `AppText.heading` / `title` / `subtitle` / `body` / `regular` / `label` / `value` are weight roles. Pass `fontSize: 13.sp`, `color`, `height` and `letterSpacing` per call.
- `AppText.base(...)` takes any exact size/weight. Add `.copyWith(...)` for extras like `decoration` or `fontStyle`.
- `AppLabel` is a one-line, ellipsized text for dynamic values in a `Row`.

**Buttons**
- `AppButton`: brand gradient CTA.
- `AppButton.outlined`, `AppButton.text`, `AppButton.tonal`: the other variants. All support `loading`, `icon`, `expand` and `height`.
- `AppIconButton`: header icon tile with an optional `badge`.
- `AppGradientButton` is still available; `AppButton` wraps it.

**Containers**
- `AppCard`: surface card. `radius` is passed as-is, `onTap` adds ink.
- `AppBottomSheet` + `AppBottomSheet.show(...)` + `AppSheetGrabber`.
- `AppOptionCard`, `AppInfoBanner`, `AppEmptyView`, `AppComingSoon`, `AppBrandBadge`.

**Status & data**
- `AppStatusPill` with `AppStatusColors.of(status, scheme)` / `.label(status)`. This is the one status→colour map.
- `AppPill`, `AppChoiceChip`, `AppSegmentedControl`, `AppStatTile` / `AppStatGrid`, `KeyValueRow`, `IconLeadingRow`, `SectionHeader`.

**Lists**
- `history/`: `AppHistoryRow`, `AppHistoryEmpty`, `AppLoadMoreButton`.
- `market/`: `AppSymbolCard`, `AppSymbolQuote`, `AppPriceTile`, `AppMetricStrip`, `AppSymbolListSkeleton`.

**Forms & states**
- `AppTextField`, `AppLabeledField`, `AppLabeledDropdown`, `AppCheckbox`, `UploadDropzone`.
- `DataStateBuilder` with the shimmer skeletons in `skeletons/`, `AppToast`, `AppConfirmDialog`.

### Enforced by tests

- `test/architecture/reusable_ui_guard_test.dart` fails on a raw `GoogleFonts.` / `TextStyle(` in `lib/features`, on any `Flavor.` check outside `lib/app/flavor/`, and on a raw `OutlinedButton` / `TextButton` / `FilledButton` beyond the listed one-off designs.
- `test/goldens/` renders every shared widget for all 3 flavors in light and dark (`flutter test test/goldens`). Re-record with `--update-goldens` only for an intended design change.
- `test/goldens/shared_widgets_layout_test.dart` checks for overflow and clipping at 320 and 375 px.

## API docs

- `docs/API_REFERENCE.md`: every endpoint, with params and payloads.
- `docs/TenaxProp-Mobile-App-API.postman_collection.json`: Postman collection. Regenerate it with `python3 docs/tool/build_postman.py`.
