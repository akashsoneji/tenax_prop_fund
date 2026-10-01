import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import 'app_glass.dart';

/// Square-ish icon button used in headers: a 38×38 tile (soft track fill +
/// border and 12r corners in light mode, a frosted glass circle in dark mode)
/// with a 20 icon. [badge] is stacked on top-right — pass it from the feature
/// (e.g. an `Obx` unread dot) so this widget itself never rebuilds on data.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.size = 38,
    this.iconSize = 20,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  /// Tile size in w. Defaults to 38.
  final double size;

  /// Icon size in w. Defaults to 20.
  final double iconSize;

  /// Accessibility label (also shown on long-press).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final iconWidget = Icon(icon, color: scheme.onSurface, size: iconSize.w);
    final surface = dark
        ? AppGlass(
            width: size.w,
            height: size.w,
            shape: BoxShape.circle,
            child: iconWidget,
          )
        : Container(
            width: size.w,
            height: size.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.trackSoft,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: iconWidget,
          );
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [surface, ?badge],
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
