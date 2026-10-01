import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's standard surface card: [AppTheme.surfaceCard] (white / dark card
/// fill with a hairline border) around [child].
///
/// [radius] is used exactly as given — pass `18.r` for a ScreenUtil-scaled
/// corner or `18` for a fixed one, matching the screen you're migrating.
/// With [onTap] the card gets an ink ripple clipped to its corners.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.width,
    this.onTap,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decoration = AppTheme.surfaceCard(scheme, radius: radius);

    if (onTap == null) {
      return Container(
        width: width,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    final card = Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: width,
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}
