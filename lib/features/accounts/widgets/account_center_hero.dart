import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// The "ACCOUNT CENTER" hero — a compact gradient banner. Eyebrow + title sit
/// beside the primary CTA; a single-row metric strip (Owned / Active / Funded /
/// Provisioning) replaces the old tall 2×2 grid so the card stays short on
/// mobile. Mirrors the web header, condensed. Fully theme-driven.
class AccountCenterHero extends StatelessWidget {
  const AccountCenterHero({
    super.key,
    required this.ownedTotal,
    required this.active,
    required this.funded,
    required this.provisioning,
    required this.trialEnabled,
    required this.onFreeTrial,
    required this.onStartChallenge,
  });

  final int ownedTotal;
  final int active;
  final int funded;
  final int provisioning;
  final bool trialEnabled;
  final VoidCallback onFreeTrial;
  final VoidCallback onStartChallenge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.24),
            blurRadius: 14.r,
            offset: Offset(0, 8.h),
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
                    _Eyebrow(label: 'accounts.center'.tr),
                    SizedBox(height: 6.h),
                    Text(
                      'accounts.subtitle'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              if (trialEnabled)
                _IconCta(
                  icon: Icons.card_giftcard_rounded,
                  tooltip: 'accounts.free_trial'.tr,
                  onTap: onFreeTrial,
                ),
            ],
          ),
          SizedBox(height: 10.h),
          _MetricStrip(
            owned: ownedTotal,
            active: active,
            funded: funded,
            provisioning: provisioning,
          ),
          SizedBox(height: 10.h),
          _HeroButton(
            label: 'accounts.start_challenge'.tr,
            icon: Icons.rocket_launch_rounded,
            onTap: onStartChallenge,
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-row metric strip — four compact figures separated by hairlines.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.owned,
    required this.active,
    required this.funded,
    required this.provisioning,
  });

  final int owned;
  final int active;
  final int funded;
  final int provisioning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: 'accounts.stat_owned'.tr, value: owned),
          ),
          const _StripDivider(),
          Expanded(
            child: _Metric(label: 'accounts.stat_active'.tr, value: active),
          ),
          const _StripDivider(),
          Expanded(
            child: _Metric(label: 'accounts.stat_funded'.tr, value: funded),
          ),
          const _StripDivider(),
          Expanded(
            child: _Metric(
              label: 'accounts.stat_provisioning'.tr,
              value: provisioning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.w,
      height: 26.h,
      color: AppColors.white.withValues(alpha: 0.14),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value',
            maxLines: 1,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.72),
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Small circular icon action (Free trial) shown beside the title.
class _IconCta extends StatelessWidget {
  const _IconCta({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36.w,
            height: 36.h,
            child: Icon(Icons.card_giftcard_rounded,
                size: 19.w, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(30.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          height: 38.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16.w, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8.w),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
