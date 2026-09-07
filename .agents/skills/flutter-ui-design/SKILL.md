---
name: flutter-ui-design
description: |
  Use this skill when designing, building, or fixing Flutter UI screens and widgets.
  Triggers on: "create screen", "build ui", "design widget", "fix layout overflow", "renderflex error", "responsive layout", "make responsive", "pixel perfect".
---

# Flutter UI & Layout Engineering Skill

Follow this strict guide when constructing or styling Flutter UI to ensure pixel-perfect, overflow-free, and beautiful interfaces.

## 1. Core Layout Principles & Preventing Layout Bugs

### Avoid Common Overflow Traps:
- **Unbounded Height in Column**: When using `ListView`, `GridView`, or `Expanded` inside a `Column` or `SingleChildScrollView`:
  - Set `shrinkWrap: true` and `physics: const NeverScrollableScrollPhysics()` on inner lists if nested inside a scroll view.
  - Or wrap list in an `Expanded` / `Flexible` if inside a bounded `Column`.
- **RenderFlex Overflow on Small Screens / Keyboard Open**:
  - Always wrap screen bodies that contain forms/inputs in `SingleChildScrollView(physics: const BouncingScrollPhysics(), child: ...)` with `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
  - Set `resizeToAvoidBottomInset: true` on `Scaffold`.
- **Text Overflow**:
  - Always wrap dynamic text in `Flexible` or `Expanded` when placed inside a `Row`.
  - Set `maxLines: 1` (or `2`), `overflow: TextOverflow.ellipsis`.

## 2. Widget Structure & Decomposition Rule

- **Max 100-150 lines per widget**: Break complex screens into small, focused sub-widgets (e.g., `_HeaderSection`, `_TradingCard`, `_MetricsGrid`).
- **One public widget per file**: Private sub-widgets are prefixed with `_`.
- **Pure UI separation**: Keep View classes stateless or declarative. Never embed HTTP calls, WebSocket subscriptions, or raw business logic directly in widget classes.

## 3. Design Tokens & Styling Conventions

- **Colors & Themes**:
  - Use `Theme.of(context).colorScheme` or custom theme extension tokens.
  - Never hardcode raw hex values (e.g. `Color(0xFF1E293B)`) directly in widget build methods — use centralized constants or theme tokens.
- **Typography**:
  - Always use `Theme.of(context).textTheme` (e.g. `textTheme.titleLarge`, `textTheme.bodyMedium`) with `.copyWith()` for minor adjustments.
- **Spacing System**:
  - Standard spacing increments: `4`, `8`, `12`, `16`, `20`, `24`, `32`, `48`.
  - Use `const SizedBox(width: 8)` and `const SizedBox(height: 16)` instead of margin where possible.
- **Border Radii & Elevation**:
  - Rounded corners: `BorderRadius.circular(8)` for chips/inputs, `12` or `16` for cards, `24` for modal bottom sheets.

## 4. Scaffold Standard Template

```dart
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Title'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _HeaderSection(),
              SizedBox(height: 16),
              _ContentSection(),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 5. Checklist Before Marking UI Done
- [ ] No `RenderFlex` overflow errors in portrait or landscape.
- [ ] All static widgets, icons, insets, and strings use `const`.
- [ ] Uses `SafeArea` for top notch and bottom gesture pill protection.
- [ ] Form inputs stay visible above virtual keyboard.
- [ ] Text widgets handle extreme strings without breaking layout.
