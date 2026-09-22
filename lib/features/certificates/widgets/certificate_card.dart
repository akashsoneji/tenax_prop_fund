import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/certificate_model.dart';

/// One certificate as an achievement tile: a medal seal on the left, the name
/// and blurb beside it, and the unlock criteria as a checklist underneath.
///
/// Earned tiles get a tinted seal, a gradient accent edge and a "View" affordance;
/// locked ones stay muted so the shelf reads at a glance. Fully theme-driven and
/// animates in with a fade + slide so a list staggers naturally via [index].
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.certificate,
    required this.onTap,
    this.index = 0,
  });

  final Certificate certificate;
  final VoidCallback onTap;
  final int index;

  /// Keeps the tile height stable when the backend returns a long list.
  static const _maxCriteria = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final earned = certificate.earned;
    final criteria = certificate.criteria.take(_maxCriteria).toList();
    final accent = earned ? AppColors.success : scheme.onSurface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18.h),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: AppTheme.surfaceCard(scheme, radius: 20.r),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent edge — the shelf's colour cue for earned vs locked.
                  Container(
                    width: 4.w,
                    color: accent.withValues(alpha: earned ? 1 : 0.12),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 16.h, 16.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MedalSeal(earned: earned),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _Heading(
                                  certificate: certificate,
                                  earned: earned,
                                ),
                              ),
                            ],
                          ),
                          if (criteria.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            for (final item in criteria)
                              _CriterionRow(text: item, earned: earned),
                          ],
                          SizedBox(height: 12.h),
                          _Footer(earned: earned),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Name + blurb block beside the seal.
class _Heading extends StatelessWidget {
  const _Heading({required this.certificate, required this.earned});

  final Certificate certificate;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          certificate.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.heading(
            color: scheme.onSurface.withValues(alpha: earned ? 1 : 0.7),
            fontSize: 17.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          certificate.blurb,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            color: scheme.onSurface.withValues(alpha: 0.55),
            fontSize: 13.sp,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Circular medal with a ribbon notch — tinted when earned, outlined when not.
class _MedalSeal extends StatelessWidget {
  const _MedalSeal({required this.earned});

  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned ? AppTheme.brandGradient(scheme) : null,
        color: earned ? null : scheme.onSurface.withValues(alpha: 0.06),
        border: earned
            ? null
            : Border.all(
                color: scheme.onSurface.withValues(alpha: 0.12),
                width: 1.5.w,
              ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.30),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ]
            : null,
      ),
      child: Icon(
        earned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
        size: 24.w,
        color: earned
            ? AppColors.white
            : scheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

/// A single unlock condition, ticked when the certificate is already earned.
class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.text, required this.earned});

  final String text;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              earned
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14.w,
              color: earned
                  ? AppColors.success
                  : scheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                color: scheme.onSurface.withValues(alpha: 0.65),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip on the left, the tap affordance on the right when earned.
class _Footer extends StatelessWidget {
  const _Footer({required this.earned});

  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = earned ? AppColors.success : scheme.onSurface;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: earned ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withValues(alpha: earned ? 1 : 0.35),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                earned
                    ? 'certificates.earned'.tr
                    : 'certificates.locked'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  color: tone.withValues(alpha: earned ? 1 : 0.5),
                  fontSize: 11.5.sp,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (earned)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'certificates.view'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(
                  color: scheme.primary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15.w,
                color: scheme.primary,
              ),
            ],
          ),
      ],
    );
  }
}
