import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/offer_models.dart';

/// A horizontal offer card: a vertical purple gradient rail on the left
/// carrying the vertical [Offer.code], and a surface body with a yellow pill
/// badge, a headline, a description and an apply / locked button.
///
/// Locked offers fade the rail + text and disable the button.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = offer.locked;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Rail(code: offer.code, faded: locked),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge(text: offer.badge),
                    SizedBox(height: 10.h),
                    _Headline(
                      percentLabel: offer.percentLabel,
                      subLabel: offer.subLabel,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      offer.description,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13.sp,
                        height: 1.35,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _ApplyButton(locked: locked),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.code, required this.faded});
  final String code;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: faded ? 0.45 : 1,
      child: Container(
        width: 64.w,
        decoration: BoxDecoration(gradient: AppTheme.brandGradient(scheme)),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            code,
            style: GoogleFonts.beVietnamPro(
      color: AppColors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: scheme.onTertiary,
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.percentLabel, required this.subLabel});
  final String percentLabel;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: percentLabel,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          TextSpan(
            text: '  $subLabel',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        locked ? scheme.onSurface.withValues(alpha: 0.18) : scheme.primary;
    final textColor =
        locked ? scheme.onSurfaceVariant : scheme.primary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: locked ? null : () {},
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(44.h),
          side: BorderSide(color: borderColor, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          locked ? 'Locked' : 'Apply Code',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
