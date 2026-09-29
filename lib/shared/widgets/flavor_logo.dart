import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/flavor/flavor_config.dart';

/// The active flavor's logo image (`LOGO_ASSET` in `config/flavors/<f>.json`,
/// or [asset] when a screen needs a different one, e.g. `SPLASH_LOGO_ASSET`).
/// Falls back to [fallback] when the flavor ships no logo file, so a flavor
/// without artwork still renders its old monogram instead of a broken image.
class FlavorLogo extends StatelessWidget {
  const FlavorLogo({
    super.key,
    required this.size,
    required this.fallback,
    this.asset,
  });

  final double size;
  final Widget fallback;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final logoAsset = asset ?? Get.find<FlavorConfig>().logoAsset;
    if (logoAsset.isEmpty) return fallback;
    return Image.asset(
      logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
