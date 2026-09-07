---
name: flutter-animations
description: |
  Use this skill when implementing UI animations, transitions, micro-interactions, shimmer loading effects, or page transitions in Flutter.
  Triggers on: "add animation", "shimmer loading", "smooth transition", "hero animation", "micro interaction", "animated container", "fade in", "animated switcher".
---

# Flutter Animations & Micro-Interactions Skill

Guidelines for building silky-smooth, 60/120 FPS animations and micro-interactions in Flutter without unnecessary widget rebuilds.

## 1. When to Use Which Animation

| Animation Type | Widget / Technique | Best Use Case |
| :--- | :--- | :--- |
| **Simple Property Change** | `AnimatedContainer`, `AnimatedOpacity`, `AnimatedScale`, `AnimatedPositioned` | Button click states, expand/collapse height, fade in/out |
| **Widget Replacement** | `AnimatedSwitcher`, `AnimatedCrossFade` | Switching between Empty state, Error state, and Content |
| **Repeated / Staggered / Complex** | `AnimationController` + `CurvedAnimation` + `SlideTransition` / `FadeTransition` | Onboarding sequences, charts, loading spinners |
| **Shared Element** | `Hero(tag: ...)` | List item to detail screen image/card transition |
| **Content Loading** | Shimmer Skeleton (Gradient Sweep / Opacity pulse) | Loading lists, cards, avatars while fetching API data |

## 2. Best Practices for Smooth Animations

1. **Avoid `setState` for high-frequency animation ticks**:
   - Use `AnimatedBuilder` or transition widgets (`FadeTransition`, `SlideTransition`, `ScaleTransition`) that accept `listenable: animationController` directly. This only repaints the specific subtree without re-running `build()` on the parent widget.
2. **Always dispose `AnimationController`**:
   - In `StatefulWidget`, always call `_controller.dispose()` inside `void dispose()`.
3. **Use Curves**:
   - Never use linear curves for UI elements unless it's a progress bar. Use `Curves.easeOutCubic`, `Curves.easeInOutCubic`, or `Curves.fastOutSlowIn` for natural physics feel.
4. **Appropriate Durations**:
   - Micro-interactions (taps, toggles): `150ms` - `250ms`.
   - Screen transitions / Dialogs: `300ms` - `400ms`.
   - Large expansions / Onboarding: `400ms` - `600ms`.

## 3. Reusable Shimmer Skeleton Loading Pattern

```dart
class ShimmerLoadingBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoadingBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerLoadingBox> createState() => _ShimmerLoadingBoxState();
}

class _ShimmerLoadingBoxState extends State<ShimmerLoadingBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
```

## 4. AnimatedSwitcher Standard Pattern

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
        child: child,
      ),
    );
  },
  child: isLoading
      ? const ShimmerPlaceholder(key: ValueKey('loading'))
      : ContentWidget(key: const ValueKey('content')),
)
```
