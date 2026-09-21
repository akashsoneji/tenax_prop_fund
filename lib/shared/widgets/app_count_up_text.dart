import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated numeric text that tweens from its previous value to the new one
/// whenever [value] changes — used for live equity / balance figures so a
/// socket tick visibly counts up (or down) instead of snapping.
///
/// The caller supplies a [formatter] that turns the animating `double` into the
/// display string (currency formatting, minor→major conversion, etc.), so this
/// widget stays formatting-agnostic and reusable across features.
///
/// Honours the OS reduce-motion preference (`disableAnimations`) by rendering
/// the final formatted value immediately.
///
/// ```dart
/// AppCountUpText(
///   value: equityMinor.toDouble(),
///   formatter: (v) => formatMoney(v.round(), 'USD'),
///   style: heroStyle,
/// )
/// ```
class AppCountUpText extends StatelessWidget {
  const AppCountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = AppMotion.base,
    this.curve = AppMotion.enter,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  /// The target number to animate toward. Changing it re-runs the tween from
  /// the previously shown value.
  final double value;

  /// Turns the animating value into the display string.
  final String Function(double) formatter;

  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(
        formatter(value),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        style: style,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: duration,
      curve: curve,
      builder: (context, v, _) => Text(
        formatter(v),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
