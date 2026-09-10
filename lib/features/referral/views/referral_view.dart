import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/referral_controller.dart';
import '../models/referral_models.dart';
import '../widgets/referral_warning_banner.dart';

/// Refer & earn screen: referral-code hero, a 2x2 stat grid, a "How you get
/// paid" explainer, a funded-account warning and the empty referrals state.
class ReferralView extends StatelessWidget {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<ReferralController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'referral.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Obx(
                () => DataStateBuilder<ReferralData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HeroSkeleton(),
                      SizedBox(height: 18.h),
                      const StatGridSkeleton(),
                      SizedBox(height: 26.h),
                      const CardSkeleton(lines: 4),
                    ],
                  ),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CodeHeroCard(controller: c, data: data),
                      SizedBox(height: 18.h),
                      _StatGridCard(data: data),
                      SizedBox(height: 26.h),
                      const _SectionTitle('How you get paid'),
                      const _HowYouGetPaidCard(),
                      SizedBox(height: 18.h),
                      const ReferralWarningBanner(
                        title: 'Referral earnings need a funded account',
                        body:
                            'You can collect them once you have passed a challenge. '
                            'Until then they accrue.',
                      ),
                      SizedBox(height: 26.h),
                      const _SectionTitle('Your referrals'),
                      const _EmptyReferralsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// Entrance fade+rise wrapper shared by the composed sections.
class _Enter extends StatelessWidget {
  const _Enter({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + delayMs),
      curve: AppMotion.enter,
      builder: (context, t, c) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * 16.h), child: c),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Referral-code hero
// ---------------------------------------------------------------------------
class _CodeHeroCard extends StatelessWidget {
  const _CodeHeroCard({required this.controller, required this.data});
  final ReferralController controller;
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 20.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your referral code',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        data.referralCode,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.tertiary,
                          letterSpacing: 1.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                _CopyButton(onTap: controller.copyCode),
              ],
            ),
            SizedBox(height: 18.h),
            _FrostedShareButton(onTap: controller.shareLink),
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Copy Code',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.copy_rounded, size: 16.w, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedShareButton extends StatelessWidget {
  const _FrostedShareButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: SizedBox(
          height: 50.h,
          width: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ios_share_rounded,
                    size: 18.w, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  'Share Link',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2x2 stat grid
// ---------------------------------------------------------------------------
class _StatGridCard extends StatelessWidget {
  const _StatGridCard({required this.data});
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      delayMs: 60,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                      label: 'Signed up', value: '${data.signedUp}'),
                ),
                Expanded(
                  child: _StatCell(
                      label: 'Purchased', value: '${data.purchased}'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child:
                      _StatCell(label: 'Earned', value: data.earnedLabel),
                ),
                Expanded(
                  child: _StatCell(label: 'Your rate', value: data.rateLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How you get paid
// ---------------------------------------------------------------------------
class _HowYouGetPaidCard extends StatelessWidget {
  const _HowYouGetPaidCard();

  static const _steps = [
    (
      '1',
      'They use your code',
      'The discount applies at their checkout, so they gain too.',
    ),
    (
      '2',
      'They buy a challenge',
      'You earn 10% of the fee they pay, on every purchase they ever make.',
    ),
    (
      '3',
      'It lands in your rewards',
      'Referral earnings are paid with your normal reward request.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      delayMs: 120,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _StepRow(
                number: _steps[i].$1,
                title: _steps[i].$2,
                body: _steps[i].$3,
              ),
              if (i != _steps.length - 1) Divider(height: 1.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
  });
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty referrals
// ---------------------------------------------------------------------------
class _EmptyReferralsCard extends StatelessWidget {
  const _EmptyReferralsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      delayMs: 160,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nobody yet',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Share your link to get started.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.groups_rounded,
                  color: Colors.white, size: 24.w),
            ),
          ],
        ),
      ),
    );
  }
}
