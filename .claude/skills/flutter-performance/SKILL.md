---
name: flutter-performance
description: |
  Use this skill when optimizing Flutter app performance, memory usage, rendering speed, eliminating jank, and enforcing const constructors.
  Triggers on: "optimize performance", "fix lag", "fix jank", "reduce rebuilds", "list performance", "image caching", "repaint boundary".
---

# Flutter Performance & Rendering Optimization Skill

Checklist and architectural patterns for smooth 60/120 FPS Flutter apps.

## 1. Widget Build Optimization

- **Add `const` Constructors Everywhere**:
  - `const` widgets are instantiated once at compile time and never rebuilt during frame updates.
- **Isolate Rebuild Scopes**:
  - Never call `setState` at the root of a large widget tree. Extract the updating section into a small sub-widget or reactive state consumer (e.g. `Obx(...)`, `ValueListenableBuilder`, `Consumer`).
- **Avoid Expensive Operations in `build()`**:
  - Never parse JSON, instantiate DateFormatters, perform regex search, or calculate heavy math inside `Widget.build()`. Compute them in the Controller/Provider/ViewModel or memoize them.

## 2. List & Scroll Performance

- **Use Virtualized Builders**:
  - For lists with >10 items, always use `ListView.builder` or `CustomScrollView` with `SliverList.builder`. Never use `ListView(children: [...])` or `Column` with `List.map`.
- **Provide `itemExtent` or `prototypeItem`**:
  - When list items have fixed height, specify `itemExtent: 72.0` or `prototypeItem: const ListItemTile(...)`. This avoids measuring every element before scrolling.
- **Add `addRepaintBoundaries: true`**:
  - Enabled by default in `ListView.builder`, isolating repaints to only the scrolled tile.

## 3. Repaint Boundaries for Heavy Components

Wrap complex, frequently repainting elements (such as real-time charts, candlestick graphs, QR code scanners, or custom canvas painters) in `RepaintBoundary`:

```dart
RepaintBoundary(
  child: LiveStockChart(data: liveData),
)
```

## 4. Image & Asset Optimization

- Use SVG vector icons (`flutter_svg`) instead of oversized PNGs for UI icons.
- For remote network images, always use `cached_network_image` with `memCacheWidth` and `memCacheHeight` constraints to prevent OOM (Out Of Memory) crashes:
```dart
CachedNetworkImage(
  imageUrl: userAvatarUrl,
  memCacheWidth: 120, // Prevents loading full 4K images into GPU memory
  placeholder: (context, url) => const ShimmerAvatarPlaceholder(),
  errorWidget: (context, url, error) => const Icon(Icons.person),
)
```

## 5. Performance Verification Commands
- Check lint & warnings: `flutter analyze`
- Profile mode run: `flutter run --profile`
