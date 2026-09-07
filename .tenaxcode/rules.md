# Project rules

## Imported from .cursorrules

# Flutter & Dart Agent Rules (Cursor / Windsurf / Multi-IDE)

## UI & Layout Architecture
- **Overflow Prevention**: Always wrap scrollable content with `SingleChildScrollView(physics: BouncingScrollPhysics())` and ensure `resizeToAvoidBottomInset: true` on `Scaffold`.
- **Text Safety**: In `Row`s, always wrap dynamic text widgets in `Expanded` or `Flexible` with `maxLines` and `overflow: TextOverflow.ellipsis`.
- **Theme Tokens**: Never hardcode colors or raw hex values directly in widgets. Use `Theme.of(context).colorScheme` or centralized tokens.
- **Decomposition**: Keep individual widget classes small (under 150 lines). Extract reusable components to `lib/core/widgets/` or feature-level private widgets `_MySubWidget`.
- **Performance**: Always use `const` constructors for static widgets, insets, and borders. Use `ListView.builder` for dynamic or large lists.

## Architecture
- Separate pure UI (Views) from Business Logic & Controllers (GetX / Riverpod / Bloc).
- Never place API calls, Dio requests, or WebSocket management directly inside widgets.
- Refer to detailed skills in `.agents/skills/` and `.claude/skills/`.

## MANDATORY DEFAULTS — apply on EVERY new screen / design / controller (no need to ask)
When building or editing ANY feature (screen, widget, or controller), ALWAYS deliver ALL of the following by default, without being told each time:

### 1. GetX architecture (non-negotiable)
- Follow the existing feature layout: `lib/features/<feature>/` split into `bindings/`, `controllers/`, `models/`, `repositories/`, `views/`, `widgets/`.
- Controllers extend `BaseController<T>` and implement `fetch()`; expose state as `Rx`/`.obs`; never hold UI (`BuildContext`, widgets) in the controller.
- Views are `GetView<Controller>` / `GetWidget` — pure UI only. NO API calls, Dio, or WebSocket logic in widgets (put them in repositories/services).
- Dependencies are wired through a `*_binding.dart`; inject shared singletons with `Get.find<...>()` (e.g. `ApiClient`). Register the route + binding in `lib/app/routes/app_pages.dart`.
- Loading state uses `DataStateBuilder` with a matching skeleton (`app_shimmer.dart` / `skeletons/skeletons.dart`) — never a bare spinner where a skeleton fits.

### 2. Dark + Light mode — automatic, always
- Every color MUST come from `Theme.of(context).colorScheme` OR the central tokens in `lib/shared/theme/app_colors.dart` (`AppColors.*`). NEVER write `Color(0xFF…)` literals in feature code.
- Design so BOTH themes look correct with zero extra work — pick `scheme.surface`/`onSurface`/`primary` etc. so it adapts. Only branch on `Get.isDarkMode` when a design genuinely differs per theme.
- Hero/gradient cards use `BorderRadius.circular(20-22)` by default (NOT `heroPillRadius`, unless a design screenshot shows the half-circle bulge).

### 3. Localization — always
- ALL user-facing strings go through `.tr` and are added to BOTH `en` and `hi` maps in `lib/core/localization/app_translations.dart`. Never hardcode display text in a widget.

### 4. Reusable widgets + fonts/tokens
- Reuse existing shared widgets first (`lib/shared/widgets/*`: `AppGradientButton`, `AppTextField`, `AppLabeledField`, `AppToast`, `DataStateBuilder`, etc.). Extract a new reusable widget instead of copy-pasting UI.
- Primary CTAs use `AppGradientButton` (white text) per brand rule.
- All text styles come from `Theme.of(context).textTheme.*` or `AppText.*` (`lib/shared/theme/app_text.dart`). NEVER use `GoogleFonts.*` literals or raw `TextStyle` font families in feature code.
- Keep widget classes under 150 lines; extract `_SubWidget`s or feature-level widgets.

### 5. Render / layout self-check — ALWAYS re-verify after building a design
After creating or editing any UI, re-read the design and confirm it has NO render issues before reporting done:
- Wrap scroll content in `SingleChildScrollView(physics: BouncingScrollPhysics())`; `Scaffold` has `resizeToAvoidBottomInset: true`.
- Every dynamic text inside a `Row` is wrapped in `Expanded`/`Flexible` with `maxLines` + `overflow: TextOverflow.ellipsis` (prevents "RenderFlex overflowed").
- No `ListView`/`Column` with unbounded height inside another scrollable — wrap in `Expanded`/`SizedBox`; use `ListView.builder`/`GridView.builder` for lists.
- No `Expanded`/`Flexible` outside a `Flex`, no `Positioned` outside a `Stack`.
- Use `const` constructors for static widgets/insets/borders.
- Run `flutter analyze lib/features/<feature>` and fix everything before saying it's done.

## Imported from CLAUDE.md

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

Multiple clients/flavors exist:
```text
client_a
client_b
client_c
client_d
```

All clients use the **same Flutter application codebase**.

Do NOT duplicate the complete application per client.

Do NOT create:
```dart
ClientAController
ClientBController
ClientCController
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
if (flavor == 'client_a') {
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
 ├── ClientAHeader
 ├── ClientBHeader
 └── DefaultHeader
```

But the controller remains a single `LoginController`. Do not duplicate the controller.

### Level 3: Completely Different Screen Layout (rare)
Same business, fundamentally different UI:

```text
ClientATradingView
ClientBTradingView
CommonTradingView
```

All of them must use the same `TradingController`, `TradingRepository`, `TradingModel`.

The architecture must allow:

```text
TradingScreen
     ↓
FlavorResolver (centralized, no scattered if-else)
     ↓
ClientATradingView / ClientBTradingView / CommonTradingView
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
│       ├── client_a/
│       ├── client_b/
│       └── client_c/
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
class ClientAConfig extends FlavorConfig { ... }
class ClientBConfig extends FlavorConfig { ... }
class ClientCConfig extends FlavorConfig { ... }
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
client_a
client_b
client_c
```

Use Android product flavors and iOS schemes/configurations appropriately.

Do NOT duplicate the Flutter application per client.

---

## 17. VS Code `launch.json`

Create `.vscode/launch.json` configurations — one per flavor.

Working pattern (use this exactly):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Client A — Debug",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--flavor", "client_a",
        "--dart-define=FLAVOR=client_a",
        "--dart-define=API_BASE_URL=https://api.client_a.com",
        "--dart-define=WS_URL=wss://ws.client_a.com",
        "--dart-define=ENV=development"
      ]
    },
    {
      "name": "Client B — Debug",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--flavor", "client_b",
        "--dart-define=FLAVOR=client_b",
        "--dart-define=API_BASE_URL=https://api.client_b.com",
        "--dart-define=WS_URL=wss://ws.client_b.com",
        "--dart-define=ENV=development"
      ]
    },
    {
      "name": "Client A — Release",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--flavor", "client_a",
        "--dart-define=FLAVOR=client_a",
        "--dart-define=API_BASE_URL=https://api.client_a.com",
        "--dart-define=WS_URL=wss://ws.client_a.com",
        "--dart-define=ENV=production"
      ],
      "flutterMode": "release"
    }
  ]
}
```

The developer selects a config from the VS Code dropdown → press F5 → the matching flavor launches.

Read env vars in Dart:
```dart
const _flavor        = String.fromEnvironment('FLAVOR', defaultValue: 'client_a');
const _apiBaseUrl    = String.fromEnvironment('API_BASE_URL');
const _wsUrl         = String.fromEnvironment('WS_URL');
const _env           = String.fromEnvironment('ENV', defaultValue: 'development');
```

---

## 18. Build Commands (CI/CD friendly)

Document and use these commands:

```text
# Run (debug)
flutter run --flavor client_a --dart-define=FLAVOR=client_a --dart-define=API_BASE_URL=https://api.client_a.com

# Build APK
flutter build apk --release --flavor client_a --dart-define=FLAVOR=client_a --dart-define=API_BASE_URL=https://api.client_a.com --dart-define=ENV=production

# Build App Bundle
flutter build appbundle --release --flavor client_a --dart-define=FLAVOR=client_a --dart-define=API_BASE_URL=https://api.client_a.com --dart-define=ENV=production

# Build iOS
flutter build ios --release --flavor client_a --dart-define=FLAVOR=client_a --dart-define=API_BASE_URL=https://api.client_a.com --dart-define=ENV=production
```

Same for `client_b`, `client_c`.

These commands are CI/CD-ready. Document them in `README.md`.

---

## 19. Flavor Switching Requirement

When the developer changes the selected configuration in `launch.json` (or the build command) from `client_a` to `client_b`, the application must start with:
- Client B configuration
- Client B theme
- Client B assets
- Client B UI variations
- Client B API/WebSocket endpoints

**without modifying shared feature/controller code.**

If a code change is required to switch flavors, the architecture is wrong — refactor.

---

## 20. Do Not Duplicate Controllers (HARD RULE)

If:
```text
Client A Login
Client B Login
Client C Login
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

Example: Client A has a fundamentally different trading workflow.

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
client_a
client_b
client_c
```

Do not mix environment and client configuration unnecessarily.

Valid combinations:
```text
client_a + staging
client_a + production
client_b + staging
client_b + production
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

Use build configuration (`--dart-define`) for non-secret config and secure storage (`flutter_secure_storage`) for tokens.

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
4. `assets/brand/<flavor>/...` per-flavor assets.
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

Create an example where `client_a` and `client_b`:
- share the same `LoginController`
- share the same `LoginRepository`
- share the same `ApiService`
- share the same `LoginModel`

but:
- `client_a` → blue theme + Layout A
- `client_b` → green theme + Layout B

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
          Client A              Client B
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
