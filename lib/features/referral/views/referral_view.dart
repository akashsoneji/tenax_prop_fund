import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/referral_controller.dart';
import '../models/referral_models.dart';
import '../widgets/referral_commission_row.dart';
import '../widgets/referral_warning_banner.dart';
import '../widgets/referral_withdraw_sheet.dart';

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
          PinnedGradientAppBar(
            title: 'referral.title'.tr,
            actions: [
              _HistoryAction(
                onTap: () => Get.toNamed(AppRoutes.referralHistory),
              ),
            ],
          ),
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
                      HeroSkeleton(height: 250.h),
                      SizedBox(height: 26.h),
                      const CardSkeleton(lines: 4),
                    ],
                  ),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CodeHeroCard(controller: c, data: data),
                      SizedBox(height: 26.h),
                      _SectionTitle('referral.how_you_get_paid'.tr),
                      const _HowYouGetPaidCard(),
                      SizedBox(height: 18.h),
                      ReferralWarningBanner(
                        title: 'referral.warning_title'.tr,
                        body: 'referral.warning_body'.tr,
                      ),
                      SizedBox(height: 26.h),
                      _SectionTitle('referral.your_referrals'.tr),
                      if (data.referrals.isEmpty)
                        const _EmptyReferralsCard()
                      else
                        _ReferralsList(referrals: data.referrals),
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

/// The hero's single accent. One knob: change these two and the badge, code
/// pill, stat values and share CTA all follow.
const _heroAccent = AppColors.white;
const _heroAccentDeep = AppColors.frostWhite;

class _CodeHeroCard extends StatelessWidget {
  const _CodeHeroCard({required this.controller, required this.data});
  final ReferralController controller;
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(scheme.primary, AppColors.black, 0.52)!,
              Color.lerp(scheme.primary, AppColors.black, 0.34)!,
              Color.lerp(scheme.primary, AppColors.black, 0.58)!,
            ],
            stops: const [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.32),
              blurRadius: 22.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroHeader(),
            SizedBox(height: 12.h),
            _CodePill(code: data.referralCode, onCopy: controller.copyCode),
            SizedBox(height: 10.h),
            _HeroStatsStrip(data: data),
            SizedBox(height: 10.h),
            _HeroMetaRow(data: data),
            SizedBox(height: 10.h),
            _ShareLinkButton(onTap: controller.shareLink),
            SizedBox(height: 10.h),
            _WithdrawButton(onTap: () => showReferralWithdrawSheet(data)),
          ],
        ),
      ),
    );
  }
}

/// Gift badge + "YOUR REFERRAL CODE" eyebrow with the gold underline.
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11.r),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.card_giftcard_rounded,
            size: 18.w,
            color: _heroAccent,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'referral.your_referral_code'.tr.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppColors.white.withValues(alpha: 0.88),
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                width: 28.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: _heroAccent,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The gold-outlined pill holding the referral code with an inline copy action.
class _CodePill extends StatelessWidget {
  const _CodePill({required this.code, required this.onCopy});
  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 0, 6.w, 0),
      height: 54.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _heroAccent.withValues(alpha: 0.14),
            AppColors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: _heroAccent.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: _heroAccent.withValues(alpha: 0.22),
            blurRadius: 14.r,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 21.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                height: 1.0,
                color: _heroAccent,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24.h,
            color: AppColors.white.withValues(alpha: 0.22),
          ),
          Material(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 15.w,
                      color: AppColors.white,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'referral.copy_code'.tr,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four referral stats in one translucent strip inside the hero.
class _HeroStatsStrip extends StatelessWidget {
  const _HeroStatsStrip({required this.data});
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final cells = <({IconData icon, String label, String value, bool gold})>[
      (
        icon: Icons.person_rounded,
        label: 'referral.signed_up'.tr,
        value: '${data.signedUp}',
        gold: false,
      ),
      (
        icon: Icons.shopping_cart_rounded,
        label: 'referral.purchased'.tr,
        value: '${data.purchased}',
        gold: false,
      ),
      (
        icon: Icons.paid_rounded,
        label: 'referral.earned'.tr,
        value: data.earnedLabel,
        gold: true,
      ),
      (
        icon: Icons.percent_rounded,
        label: 'referral.your_rate'.tr,
        value: data.rateLabel,
        gold: true,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            Expanded(
              child: _HeroStatCell(
                icon: cells[i].icon,
                label: cells[i].label,
                value: cells[i].value,
                gold: cells[i].gold,
              ),
            ),
            if (i != cells.length - 1)
              Container(
                width: 1,
                height: 30.h,
                color: AppColors.white.withValues(alpha: 0.14),
              ),
          ],
        ],
      ),
    );
  }
}

/// Secondary hero line: clicks, conversion rate and lifetime paid, each in an
/// equal third so the values line up as a grid instead of hugging the left.
class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({required this.data});
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('referral.clicks'.tr, '${data.clicks}'),
      ('referral.conversion'.tr, data.conversionRate),
      ('referral.total_paid'.tr, data.totalPaidLabel),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroStatCell extends StatelessWidget {
  const _HeroStatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.gold,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.w, color: _heroAccent),
          SizedBox(height: 6.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.74),
            ),
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.beVietnamPro(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: gold ? _heroAccent : AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width gold share CTA sitting inside the hero.
class _ShareLinkButton extends StatelessWidget {
  const _ShareLinkButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Ink(
          height: 44.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_heroAccentDeep, _heroAccent, _heroAccentDeep],
            ),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Row(
            children: [
              const Spacer(),
              Icon(
                Icons.ios_share_rounded,
                size: 17.w,
                color: AppColors.heroInkDeep,
              ),
              SizedBox(width: 10.w),
              Container(
                width: 1,
                height: 18.h,
                color: AppColors.heroInkDeep.withValues(alpha: 0.35),
              ),
              SizedBox(width: 10.w),
              Text(
                'referral.share_link'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heroInkDeep,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                size: 17.w,
                color: AppColors.heroInkDeep,
              ),
              SizedBox(width: 14.w),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark "Withdraw earnings" CTA under the share button; opens the withdraw
/// sheet (amount + payout method).
class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Ink(
          height: 44.h,
          decoration: BoxDecoration(
            color: AppColors.heroInkDeep,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 17.w,
                color: AppColors.white,
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  'referral.withdraw'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-bar "History" pill that opens the paginated commission history.
class _HistoryAction extends StatelessWidget {
  const _HistoryAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 16.w, color: AppColors.white),
              SizedBox(width: 5.w),
              Text(
                'referral.history'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
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
// Referral commission rows
// ---------------------------------------------------------------------------
class _ReferralsList extends StatelessWidget {
  const _ReferralsList({required this.referrals});
  final List<Referral> referrals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Enter(
      delayMs: 160,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          children: [
            for (var i = 0; i < referrals.length; i++) ...[
              ReferralCommissionRow(referral: referrals[i]),
              if (i != referrals.length - 1) Divider(height: 1.h),
            ],
          ],
        ),
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
                    'referral.empty_title'.tr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'referral.empty_hint'.tr,
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
              child: Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 24.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
