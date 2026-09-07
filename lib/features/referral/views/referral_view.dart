import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Obx(
                () => DataStateBuilder<ReferralData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      HeroSkeleton(),
                      SizedBox(height: 18),
                      StatGridSkeleton(),
                      SizedBox(height: 26),
                      CardSkeleton(lines: 4),
                    ],
                  ),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CodeHeroCard(controller: c, data: data),
                      const SizedBox(height: 18),
                      _StatGridCard(data: data),
                      const SizedBox(height: 26),
                      const _SectionTitle('How you get paid'),
                      const _HowYouGetPaidCard(),
                      const SizedBox(height: 18),
                      const ReferralWarningBanner(
                        title: 'Referral earnings need a funded account',
                        body:
                            'You can collect them once you have passed a challenge. '
                            'Until then they accrue.',
                      ),
                      const SizedBox(height: 26),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 17,
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
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: c),
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
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 12),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.referralCode,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 32,
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
            const SizedBox(height: 18),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Copy Code',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ios_share_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Share Link',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
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
        padding: const EdgeInsets.all(6),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 24,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _StepRow(
                number: _steps[i].$1,
                title: _steps[i].$2,
                body: _steps[i].$3,
              ),
              if (i != _steps.length - 1) const Divider(height: 1),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(18),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your link to get started.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
