import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text.dart';

/// Circular flag/asset avatar for a market symbol. Resolves
/// `assets/svg/flags/<code>.svg` (lower-cased, broker suffix stripped) and
/// falls back to the symbol's first letter when no icon exists.
class SymbolIcon extends StatelessWidget {
  const SymbolIcon({super.key, required this.code, this.size});

  final String code;

  /// Diameter; defaults to `32.w`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary;
    final diameter = size ?? 32.w;
    var clean = code.trim().toLowerCase();
    if (clean.contains('.')) clean = clean.substring(0, clean.indexOf('.'));
    final letter = clean.isEmpty ? '?' : clean[0].toUpperCase();

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(diameter * 0.094),
        child: SvgPicture.asset(
          'assets/svg/flags/$clean.svg',
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Center(
            child: Text(letter,
                style: AppText.base(
                    fontSize: diameter * 0.375,
                    fontWeight: FontWeight.w700,
                    color: tint)),
          ),
        ),
      ),
    );
  }
}
