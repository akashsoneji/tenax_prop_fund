import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A reusable document-upload tile
///
/// Two visual states from the design:
/// - [filled] `true`  → brand purple→magenta gradient background.
/// - [filled] `false` → faint lavender wash (a secondary/optional slot).
/// A small white rounded square holds the `+` (or a check once a file is set).
class UploadDropzone extends StatelessWidget {
  const UploadDropzone({
    super.key,
    required this.onTap,
    this.filled = true,
    this.hasFile = false,
    this.height = 150,
  });

  final VoidCallback onTap;

  /// Gradient (primary) vs faint (secondary) styling.
  final bool filled;

  /// Whether a document has been attached (swaps `+` for a check).
  final bool hasFile;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final faint = scheme.primary.withValues(alpha: 0.08);
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: filled ? AppTheme.brandGradient(scheme) : null,
            color: filled ? null : faint,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: filled
                    ? AppColors.white.withValues(alpha: 0.18)
                    : AppColors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 30.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: filled ? Colors.white : scheme.onSurface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  hasFile ? Icons.check_rounded : Icons.add_rounded,
                  size: 18.w,
                  color: filled ? scheme.primary : scheme.surface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
