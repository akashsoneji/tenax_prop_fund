---
name: flutter-design-system
description: |
  Use this skill when creating or refactoring reusable UI components, design tokens, buttons, cards, dialogs, bottom sheets, or white-label styling in Flutter.
  Triggers on: "create reusable component", "design system", "custom button", "custom card", "bottom sheet", "dialog", "shimmer effect", "theme extension", "white label ui".
---

# Flutter Design System & Reusable Components Skill

This skill guides the construction of consistent, reusable, theme-driven components.

## 1. Component Architecture & Reusability

- Place shared UI widgets in `lib/core/widgets/` or `lib/shared/widgets/`.
- Every shared component MUST:
  1. Accept custom callbacks (e.g. `onPressed`, `onChanged`, `onTap`).
  2. Support optional customizations (e.g. `backgroundColor`, `icon`, `isLoading`, `isEnabled`).
  3. Default to theme values when parameters are omitted.
  4. Have a `const` constructor when possible.

## 2. Standard Component Patterns

### A. Primary Action Button
```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _buildChild(theme.colorScheme.primary),
      );
    }

    return FilledButton(
      onPressed: isEnabled ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _buildChild(theme.colorScheme.onPrimary),
    );
  }

  Widget _buildChild(Color spinnerColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}
```

### B. Standard Card Container
```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: border ?? Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### C. Standard Modal Bottom Sheet Pattern
```dart
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
```

## 3. White-Labeling & Multi-Theme Rules
- Never branch code in the UI for white-label styling (e.g. `if (flavor == 'client_a')`).
- Define all flavor styling in `AppTheme` / `ThemeData` / `ThemeExtension` so swapping themes changes the entire look automatically.
