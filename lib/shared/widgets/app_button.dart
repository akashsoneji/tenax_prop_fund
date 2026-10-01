import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_gradient_button.dart';

enum AppButtonVariant {
  /// The brand gradient CTA ([AppGradientButton]) — the main action.
  primary,

  /// Bordered secondary action. Styled by the theme's `outlinedButtonTheme`.
  outlined,

  /// Link-style action. Styled by the theme's `textButtonTheme`.
  text,

  /// Soft filled secondary action: primary-tinted fill, primary label.
  tonal,
}

/// The app's single button API. Pick a [variant]; everything else (colours,
/// radius, font) comes from the theme, so every flavor re-skins it for free.
///
/// [primary] renders [AppGradientButton] unchanged. [outlined] and [text] only
/// set what the call site asks for (height, icon, loading) on top of the theme
/// styles, so they look exactly like a plain `OutlinedButton` / `TextButton`.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.height,
    this.style,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.height,
    this.style,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = false,
    this.height,
    this.style,
  }) : variant = AppButtonVariant.text;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.height,
    this.style,
  }) : variant = AppButtonVariant.tonal;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  /// Fill the parent's width. Defaults to true except for [AppButton.text].
  final bool expand;

  /// Overrides the theme's minimum height. Pass a ScreenUtil value (`44.h`).
  final double? height;

  /// Extra style merged over the variant's style for one-off call sites
  /// (e.g. a red outline for a destructive action). Ignored by [primary].
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.primary) {
      return AppGradientButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
        icon: icon,
        expand: expand,
        height: height ?? 54,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final callback = enabled ? onPressed : null;
    final sized = height == null
        ? null
        : ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, height!)),
          );
    final merged = (style ?? const ButtonStyle()).merge(sized);

    final Widget child = loading
        ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final Widget button = switch (variant) {
      AppButtonVariant.outlined => icon == null
          ? OutlinedButton(onPressed: callback, style: merged, child: child)
          : OutlinedButton.icon(
              onPressed: callback,
              style: merged,
              icon: Icon(icon, size: 18.w),
              label: child,
            ),
      AppButtonVariant.text => icon == null
          ? TextButton(onPressed: callback, style: merged, child: child)
          : TextButton.icon(
              onPressed: callback,
              style: merged,
              icon: Icon(icon, size: 18.w),
              label: child,
            ),
      _ => _tonal(scheme, callback, merged, child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _tonal(
    ColorScheme scheme,
    VoidCallback? callback,
    ButtonStyle merged,
    Widget child,
  ) {
    final tonal = OutlinedButton.styleFrom(
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      side: BorderSide.none,
    ).merge(merged);
    return icon == null
        ? OutlinedButton(onPressed: callback, style: tonal, child: child)
        : OutlinedButton.icon(
            onPressed: callback,
            style: tonal,
            icon: Icon(icon, size: 18.w),
            label: child,
          );
  }
}
