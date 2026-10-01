# CLAUDE CODE INSTRUCTIONS — Tenax Prop Trading App

You are a senior Flutter architect and lead mobile engineer.

You are architecting and implementing a **production-grade Flutter trading application** using **GetX**, designed for approximately **100+ screens**, real-time WebSocket market/trading data, REST APIs, reusable UI components, multiple white-label clients/flavors, and long-term maintainability.

The most important requirement is:

> **Business logic, controllers, repositories, models, API integration and WebSocket logic should remain shared across all flavors whenever the business behavior is the same.**

Different clients/flavors will primarily have different:
- Colors
- Logos
- Fonts
- Icons
- Images
- App branding
- Some widget styles
- Some screen layouts
- Some optional/hidden UI sections
- Occasionally completely different UI for the same business functionality

However:
> **The underlying content, API contracts, business rules, models and controllers should NOT be duplicated just because the UI differs.**

Do not create separate controllers for each flavor unless the actual business logic is genuinely different.

---

## Why Controllers Remain Shared (foundational principle)

Controllers contain **business orchestration**: validate input, call the repository, manage loading/error/success states, expose `Rx*` state to the UI. This orchestration is identical across flavors because the **business is identical** — only the visual presentation of the result changes.

Therefore:
- One controller feeds many views.
- The controller never branches on flavor for logic.
- A different screen layout does NOT justify a different controller — only a different `View` widget.
- A different color, logo, or hidden section is solved by Theme + Config, not by duplicating the controller.

Treat this as a hard rule. Push back if a future request would break it.

---

## 1. Technology

Use:
- Flutter
- Dart
- GetX (state management, DI, routing)
- REST API (Dio)
- WebSocket (centralized manager)
- JSON serialization (`json_serializable` / manual `fromJson`)
- Repository pattern
- Feature-based architecture
- Reusable widgets
- Dependency injection through GetX bindings
- Environment/flavor configuration
- Android product flavors
- iOS schemes/configurations
- VS Code `launch.json`
- CI/CD-friendly architecture

Do not introduce unnecessary architectural complexity. The architecture should be easy for a medium/large Flutter team to understand.

---

## 2. Main Architecture Principle

Use this strict flow:

```text
UI (View)
 ↓
GetX Controller
 ↓
Repository
 ↓
Service (ApiService / WebSocketService)
 ↓
REST API / WebSocket
```

Concrete example:

```text
TradingView
    ↓
TradingController
    ↓
TradingRepository
    ↓
TradingApiService  |  TradingWebSocketService
```

Controllers must NOT:
- Directly call `Dio` / `http`
- Directly create HTTP requests
- Directly open WebSocket connections
- Contain flavor-specific UI code
- Contain large amounts of widget logic

Repositories/Services handle data access. Repositories also decide whether data comes from REST, WebSocket, or local cache — controllers stay unaware.

---

## 3. White Label Architecture (CRITICAL)

The app ships exactly three flavors:
```text
tenax
pipze_funded
alibabafx_prop
```

All three use the SAME UI (the Tenax design). A flavor-specific screen is built only when the user explicitly asks for it.

All clients use the **same Flutter application codebase**.

Do NOT duplicate the complete application per client.

Do NOT create:
```dart
TenaxController
PipzeFundedController
AlibabafxPropController
```
when the business logic is the same.

Only `TradingController`, `TradingRepository`, `TradingModel` remain shared.

Only UI/configuration varies.

---

## 4. UI Variation Strategy — Three Levels

### Level 1: Theme / Brand Configuration (90% of changes)
For simple differences: primary color, secondary color, background, text colors, button styles, border radius, typography, logo, icons, images.

Use centralized configuration:
```text
FlavorConfig
AppTheme
BrandConfig
AssetConfig
```

Do NOT hardcode client-specific colors throughout widgets.

Bad:
```dart
if (flavor == 'pipze_funded') {
  color = Colors.blue;
}
```

Good:
```dart
AppTheme.primaryColor
// or
Get.find<BrandConfig>().primaryColor
```

### Level 2: Reusable Widget Variations (small UI differences)
When business content is same but a component differs:

```text
LoginScreen
 ├── LoginHeader
 ├── LoginForm
 ├── LoginButton
 └── LoginFooter

LoginHeader
 ├── PipzeFundedHeader
 ├── AlibabafxPropHeader
 └── DefaultHeader
```

But the controller remains a single `LoginController`. Do not duplicate the controller.

### Level 3: Completely Different Screen Layout (rare)
Same business, fundamentally different UI:

```text
PipzeFundedTradingView
AlibabafxPropTradingView
CommonTradingView
```

All of them must use the same `TradingController`, `TradingRepository`, `TradingModel`.

The architecture must allow:

```text
TradingScreen
     ↓
FlavorResolver (centralized, no scattered if-else)
     ↓
PipzeFundedTradingView / AlibabafxPropTradingView / CommonTradingView
     ↓
Shared TradingController
```

---

## 5. UI Decision Tree (use this for every UI change request)

```text
Is only color/logo/font changing?
        ↓
      Theme

Is only text/icon/image changing?
        ↓
      Config / Assets

Is a small widget different?
        ↓
      Flavor-specific reusable widget

Is the screen layout substantially different?
        ↓
      Flavor-specific View

Is business logic different?
        ↓
      Only then consider separate business implementation
```

Default to the **cheapest** level. Duplication is the last resort.

---

## 6. Feature-Based Architecture

Do NOT organize the entire app only by file type.

Avoid:
```text
controllers/
views/
models/
widgets/
services/
```
with hundreds of files per folder.

Use feature-based modules:
```text
lib/
├── app/
├── core/
├── features/
└── shared/
```

Inside `features/`:
```text
features/
├── authentication/
├── dashboard/
├── market/
├── trading/
├── orders/
├── portfolio/
├── watchlist/
├── funds/
├── notifications/
├── profile/
├── settings/
└── ...
```

Each feature should contain its own:
```text
controllers/
views/
widgets/
bindings/
data/
   ├── models/
   └── repositories/
services/        // only if a feature genuinely needs its own service
```

---

## 7. Final Folder Structure

```text
project/
│
├── android/
├── ios/
├── assets/
│   ├── common/
│   └── flavors/
│       ├── tenax/
│       ├── pipze_funded/
│       └── alibabafx_prop/
│
├── lib/
│   │
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── routes/
│   │   │   ├── app_routes.dart
│   │   │   └── app_pages.dart
│   │   ├── bindings/
│   │   └── flavor/
│   │       ├── flavor.dart
│   │       ├── flavor_config.dart
│   │       └── flavor_resolver.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── helpers/
│   │   ├── logger/
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── api_interceptor.dart
│   │   │   └── api_response.dart
│   │   │
│   │   ├── websocket/
│   │   │   ├── websocket_manager.dart
│   │   │   ├── websocket_connection.dart
│   │   │   ├── websocket_message.dart
│   │   │   └── websocket_subscription_manager.dart
│   │   │
│   │   ├── storage/
│   │   ├── permissions/
│   │   └── localization/
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── app_card.dart
│   │   │   ├── app_dialog.dart
│   │   │   ├── app_bottom_sheet.dart
│   │   │   ├── app_loader.dart
│   │   │   ├── app_error_view.dart
│   │   │   ├── app_empty_view.dart
│   │   │   ├── app_price.dart
│   │   │   ├── app_amount.dart
│   │   │   └── app_chart.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_dimensions.dart
│   │   │
│   │   ├── models/
│   │   └── utils/
│   │
│   └── features/
│       │
│       ├── authentication/
│       │   ├── bindings/
│       │   ├── controllers/
│       │   ├── models/
│       │   ├── repositories/
│       │   ├── services/
│       │   ├── views/
│       │   │   └── flavor_overrides/         // optional, per-flavor screens
│       │   └── widgets/
│       │
│       ├── dashboard/
│       ├── market/
│       ├── trading/
│       ├── orders/
│       ├── portfolio/
│       ├── watchlist/
│       ├── funds/
│       ├── notifications/
│       ├── profile/
│       └── settings/
│
├── test/
│
├── integration_test/
│
├── .vscode/
│   └── launch.json
│
├── pubspec.yaml
└── README.md
```

Modify this structure only if a clearly better production-grade organization is justified — and explain why before doing it.

---

## 8. GetX Rules (strict)

Use GetX consistently.

For every feature:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Service
```

Controllers should:
- manage UI state
- expose observable state (`Rx*`)
- call repositories
- handle user actions
- manage loading/error/success states
- contain presentation-level business orchestration

Controllers should NOT:
- directly call `Dio` / `http`
- directly open WebSocket connections
- contain client/flavor-specific UI code
- contain large amounts of widget logic

Use GetX bindings for DI:

```text
TradingBinding
 ↓
TradingController
 ↓
TradingRepository
 ↓
TradingApiService
TradingWebSocketService
```

Bindings are co-located with each feature under `features/<feature>/bindings/`.

---

## 9. WebSocket Architecture (critical for trading)

Do NOT create a WebSocket connection separately for every screen.

Create centralized WebSocket infrastructure:

```text
WebSocket Server
       ↓
WebSocketManager (singleton)
       ↓
SubscriptionManager (tracks topics per controller)
       ↓
Market/Trading Repositories (Rx streams per topic)
       ↓
GetX Controllers
       ↓
Widgets (granular Obx rebuilds)
```

The WebSocket manager must support:
- connect / disconnect
- reconnect with exponential backoff
- heartbeat / ping-pong
- authentication handshake
- subscribe / unsubscribe
- automatic resubscribe after reconnect
- connection state stream (`Rx<WsConnectionState>`)
- error handling
- message parsing
- duplicate-message protection (idempotency keys)
- cleanup on app shutdown

Do NOT allow individual widgets to own WebSocket connections. Only the `WebSocketManager` owns the socket.

---

## 10. Real-Time State Management

The application will receive high-frequency market updates.

Do NOT rebuild the entire screen/application for every tick.

Use **granular reactive state**:

```text
BTC price update
 ↓
BTC observable state (Rx<double>)
 ↓
Only dependent widgets rebuild (Obx on that exact Rx)
```

Do NOT:
```text
WebSocket update → entire application rebuild
```

Use `Obx(() => Text('$price'))` scoped to the smallest possible widget so a tick for `BTCUSDT` does not re-render the `ETHUSDT` row.

---

## 11. REST + WebSocket Split

REST for:
- authentication
- user profile
- account information
- order history
- portfolio history
- KYC
- settings
- static/reference data

WebSocket for:
- live prices
- market depth
- order updates
- portfolio real-time updates
- trade updates
- real-time notifications

Repositories hide the source (REST / WS / cache) from controllers.

---

## 12. White Label Configuration

Create a centralized flavor configuration:

```text
FlavorConfig
├── flavorName
├── appName
├── apiBaseUrl
├── websocketUrl
├── primaryColor
├── secondaryColor
├── logo
├── splashLogo
├── fonts
├── featureFlags
└── uiConfiguration
```

Per-client classes:
```dart
class TenaxConfig extends FlavorConfig { ... }
class PipzeFundedConfig extends FlavorConfig { ... }
class AlibabafxPropConfig extends FlavorConfig { ... }
```

These configurations must NOT duplicate business logic. They only hold visual/network configuration.

---

## 13. Flavor Resolver (no scattered if-else)

Create a centralized resolver. Examples:

```dart
FlavorResolver.loginView()
FlavorResolver.tradingView()
FlavorResolver.dashboardView()
FlavorResolver.orderForm()
```

Internally it reads the active flavor and returns the correct widget.

Do NOT scatter:
```dart
if (flavor == ...) ...
```
throughout widgets.

Only use flavor-specific view implementations when the UI is genuinely different. For small changes, use configuration/theme instead of creating a new screen.

---

## 14. Reusable UI System (Design System)

Build a proper design system. Common components:

```text
AppButton
AppTextField
AppDropdown
AppCard
AppContainer
AppDialog
AppBottomSheet
AppAppBar
AppTabBar
AppLoader
AppErrorView
AppEmptyView
AppPrice
AppAmount
AppPercentage
AppIcon
```

All flavors must be able to reuse these.

Do NOT hardcode colors, dimensions, typography, or button styles in individual screens. All such values come from `AppTheme` / `AppColors` / `AppTypography` / `AppDimensions` or `BrandConfig`.

---

## 15. iOS and Android Architecture

Do NOT create:
```text
lib/android/
lib/ios/
```
or separate Dart application code per platform.

There is **one** shared Flutter application in `lib/`.

Platform-specific configuration belongs in:
```text
android/
ios/
```

Both Android and iOS consume the same Dart/Flutter feature architecture.

---

## 16. Flavors (white-label)

Support multiple clients as flavors:
```text
tenax
pipze_funded
alibabafx_prop
```

Use Android product flavors and iOS schemes/configurations appropriately.

Do NOT duplicate the Flutter application per client.

---

## 17. VS Code `launch.json`

Every client's config lives in ONE file: `config/flavors/<flavor>.json`. The build passes only that file with `--dart-define-from-file`. That way a build for one client never contains another client's URLs, name, colors or images (see §24).

Each launch config uses this pattern:

```json
{
  "name": "Pipze Funded — Debug",
  "request": "launch",
  "type": "dart",
  "program": "lib/main.dart",
  "preLaunchTask": "prepare-ios-pipze_funded",
  "args": [
    "--flavor", "pipze_funded",
    "--dart-define-from-file=config/flavors/pipze_funded.json",
    "--dart-define=ENV=development"
  ]
}
```

The developer picks a config from the VS Code dropdown and presses F5. The matching flavor launches.

`FlavorConfig.fromEnvironment()` in `lib/app/flavor/flavor_config.dart` is the only place that reads these values, through `String.fromEnvironment`. It throws at startup if a required key is missing.

Keys in `config/flavors/<flavor>.json`:

| Key | Example | Required |
|---|---|---|
| `FLAVOR` | `pipze_funded` | yes |
| `APP_NAME` | `Pipze Funded` | yes |
| `API_BASE_URL` | `https://pipzefunded.com/api/v1` | yes |
| `WEB_BASE_URL` | `https://pipzefunded.com` | yes |
| `WS_URL` | `wss://pipzefunded.com/trade-engine/ws` | yes |
| `CHART_BASE_URL` | `https://pipzefunded.com/mobile-chart` | yes |
| `PUSHER_HOST` | `pipzefunded.com` | yes |
| `PUSHER_APP_KEY` | `f316…` | yes |
| `PRIMARY_COLOR` | `5F259E` (RRGGBB or AARRGGBB) | yes |
| `SECONDARY_COLOR` | `FDCC29` | yes |
| `DARK_PRIMARY_COLOR` | `E6A541` | no |
| `FEATURE_FLAGS` | `trading,challenges,payouts,reports` | no |
| `LOGO_ASSET` / `SPLASH_LOGO_ASSET` | `assets/flavors/pipze_funded/logo.png` | no |

`ENV` (`development` / `staging` / `production`) is passed separately with `--dart-define=ENV=…`.

---

## 18. Build Commands (CI/CD friendly)

```text
# Run (debug)
flutter run --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=development

# Build APK
flutter build apk --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production

# Build App Bundle
flutter build appbundle --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production

# Build iOS
flutter build ios --release --flavor pipze_funded --dart-define-from-file=config/flavors/pipze_funded.json --dart-define=ENV=production
```

Replace `pipze_funded` with any flavor: `tenax`, `pipze_funded`, `alibabafx_prop`. The `--flavor` value and the JSON file name must match.

These commands are CI/CD-ready and are documented in `README.md`.

---

## 19. Flavor Switching Requirement

When the developer changes the selected configuration in `launch.json` (or the build command) from `tenax` to `pipze_funded`, the application must start with:
- Pipze Funded configuration
- Pipze Funded theme
- Pipze Funded assets
- Pipze Funded UI overrides (only if one was explicitly requested)
- Pipze Funded API/WebSocket endpoints

**without modifying shared feature/controller code.**

If a code change is required to switch flavors, the architecture is wrong — refactor.

---

## 20. Do Not Duplicate Controllers (HARD RULE)

If:
```text
Tenax Login
Pipze Funded Login
AlibabaFX Prop Login
```
all use the same login API, authentication logic, validation, session management, models, repository, then there MUST be only:

```text
LoginController
LoginRepository
AuthService
LoginModel
```

The views may differ.

Same rule for:
```text
Trading, Orders, Portfolio, Watchlist, Market, Funds, Profile, Notifications, Dashboard
```

---

## 21. When Controller Duplication IS Allowed

Only create separate controllers if the **actual business behavior is different**.

Example: one flavor has a fundamentally different trading workflow.

Even then, first try to share a common domain/service layer before duplicating everything.

Avoid duplication by default.

---

## 22. Monorepo / Future Packages

Keep the architecture monorepo-friendly.

For the current product, use one main Flutter application:
```text
apps/
└── trading_app/
```

If shared packages become necessary later, the structure must support extracting modules into:
```text
packages/
├── design_system/
├── network/
├── websocket/
└── shared/
```

Do NOT create packages unnecessarily at the beginning. Wait until the same code is needed in a second app — then extract.

---

## 23. Environment Separation (separate from flavors)

Separate:
```text
development
staging
production
```
from:
```text
tenax
pipze_funded
alibabafx_prop
```

Do not mix environment and client configuration unnecessarily.

Valid combinations:
```text
tenax + staging
tenax + production
pipze_funded + staging
pipze_funded + production
```

API URL and WebSocket URL must be configurable.

NEVER hardcode production URLs in feature code.

---

## 24. Security

Do NOT put:
- secrets
- private API keys
- credentials
- signing keys

into Dart source code.

Use build configuration (`--dart-define-from-file=config/flavors/<flavor>.json`) for non-secret config and secure storage (`flutter_secure_storage`) for tokens.

**Client data isolation (hard rule).** A client's build must contain ONLY that client's data. Decompiling the Pipze app must never reveal AlibabaFX's URL, name, colors or logo.
- Client URLs, name, colors, flags and asset paths live only in `config/flavors/<flavor>.json`. Never write a client host or brand name in `lib/`.
- Client images live only in `assets/flavors/<flavor>/`, declared in `pubspec.yaml` with `flavors: [<flavor>]`.
- Before a release, unzip the APK and confirm it has only its own `assets/flavors/<flavor>/` and no other client's strings. The commands are in `README.md`.

Remember: mobile apps cannot keep true secrets fully secret from a determined reverse engineer. Treat secrets accordingly.

---

## 25. Testing

The architecture must support:
- unit tests
- controller tests
- repository tests
- widget tests
- integration tests

At minimum, design testable boundaries around:
```text
Controllers
Repositories
ApiServices
WebSocketServices
FlavorConfig
```

Repositories and services accept their dependencies via constructor (no global lookups inside) so they can be mocked.

---

## 26. Coding Rules

1. Keep controllers small.
2. Keep widgets reusable.
3. Keep business logic out of widgets.
4. Keep networking out of controllers.
5. Keep WebSocket management centralized.
6. Avoid duplicate code.
7. Avoid flavor checks scattered throughout the code.
8. Prefer configuration over conditional UI.
9. Prefer composition over inheritance.
10. Use meaningful names.
11. Keep files reasonably small.
12. Do NOT create unnecessary abstraction layers.
13. Do NOT create separate controllers for flavors when business logic is shared.
14. Do NOT duplicate screens unless the layout is genuinely different.
15. Use comments only when they explain non-obvious decisions — never narrate the code.

---

## 27. Before Coding — Required Deliverables

Before writing any feature code, on the FIRST interaction in this project, provide:

1. Final folder structure (this file already covers it — confirm any deviations).
2. Architecture diagram (View → Controller → Repository → Service).
3. Data flow diagram.
4. Flavor architecture diagram.
5. WebSocket architecture diagram.
6. UI customization strategy (three levels + decision tree).
7. GetX dependency flow.
8. Explanation of why controllers remain shared (already in this file — refer back).
9. `launch.json` strategy (working pattern above).
10. Android/iOS flavor strategy.
11. Example of a common screen.
12. Example of a flavor-specific screen.
13. Example of the same controller used by multiple flavor UIs.

Then start generating the implementation. Do not generate all 100 screens at once. Build the foundation first and use 2–3 representative features as templates.

---

## 28. First Implementation Task (Foundation)

Before implementing 100 screens, create a working architectural skeleton:

1. `pubspec.yaml` with: `get`, `dio`, `web_socket_channel`, `hive`, `flutter_secure_storage`, `logger`, `get_storage`, `path_provider`, `intl`, `json_annotation`, `freezed` (if used), `build_runner`, `json_serializable`.
2. `Flavor` enum and `FlavorConfig` hierarchy.
3. `AppTheme` from `BrandConfig` (using `ColorScheme.fromSeed`).
4. `assets/flavors/<flavor>/...` per-flavor assets (bundled only into that flavor via `pubspec.yaml` `flavors:`).
5. GetX bindings + initial DI.
6. Routing (`app_routes.dart`, `app_pages.dart`).
7. Base reusable widgets in `shared/widgets/`.
8. REST client abstraction (`ApiClient`, `ApiInterceptor`, `ApiResponse`).
9. WebSocket manager abstraction (`WebSocketManager`, `WebSocketConnection`, `SubscriptionManager`).
10. One **authentication** feature (full vertical slice).
11. One **trading** feature (full vertical slice with WS).
12. One example of **common UI**.
13. One example of **flavor-specific UI** (Level 2 reusable widget variation).
14. One example of **completely different flavor-specific screen layout** (Level 3).
15. Unit-testable controller/repository architecture.

Use these examples as the template for the remaining features.

---

## 29. Expected Demonstration

When a per-flavor design is requested, `tenax` and `pipze_funded` must:
- share the same `LoginController`
- share the same `LoginRepository`
- share the same `ApiService`
- share the same `LoginModel`

but:
- `tenax` → Tenax palette + common layout
- `pipze_funded` → Pipze palette + its override layout (only when requested)

Then show clearly how changing the selected flavor in `launch.json` changes the UI without modifying the controller.

---

## 30. Do Not Over-Engineer

This is a large application, but avoid architecture for architecture's sake.

Do NOT create 10 layers just to call it "Clean Architecture".

The goal is:
```text
easy development
+
easy debugging
+
easy onboarding
+
easy white labeling
+
high performance
+
low duplication
+
long-term maintainability
```

---

## 31. Final Architectural Goal

```text
                    WHITE LABEL
                         │
              ┌──────────┴──────────┐
              │                     │
           Tenax             Pipze Funded
              │                     │
              ▼                     ▼
        Theme / Assets        Theme / Assets
        UI Configuration      UI Configuration
              │                     │
              └──────────┬──────────┘
                         │
                         ▼
                SHARED FLUTTER APP
                         │
              ┌──────────┴──────────┐
              │                     │
             UI                Shared Logic
              │                     │
      Flavor-specific Views    Controllers
      Reusable Widgets         Repositories
      Common Widgets           Models
                               Services
                                  │
                         ┌────────┴────────┐
                         │                 │
                       REST           WebSocket
```

**The most important rule:**

> **Same business behavior = same controller/repository/service. Different UI does NOT justify duplicating business logic.**

Build the application around this principle from day one.

---

## 32. How You Behave

- Before writing code in a module, READ existing files in that module. Mirror existing patterns.
- Place new code in the correct folder per the structure above. Never dump files in `lib/` root.
- New reusable widget → `shared/widgets/`.
- New feature → folder under `features/<feature>/` with the standard internal structure.
- After changes, run `flutter analyze` and fix all errors before reporting done.
- If a request would violate these rules, push back and propose the correct alternative.
- When uncertain, ask ONE focused question with 2–4 options. Do not guess architecture.
- Default to the simpler solution that matches existing patterns.

**You MUST follow these instructions for every code change in this project.**
