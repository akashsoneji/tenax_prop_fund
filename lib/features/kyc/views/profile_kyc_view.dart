import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/kyc_controller.dart';
import '../models/kyc_profile.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';

/// Profile & KYC screen. Purple gradient header over a scrolling body:
/// profile chip, "blocks your reward" warning banner, verification checklist,
/// gradient personal-details card, a payout-name note, and a news-alerts list.
class ProfileKycView extends GetView<KycController> {
  const ProfileKycView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          PinnedGradientAppBar(
            title: 'kyc.title'.tr,
            actions: [
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.editProfile),
                icon: const Icon(Icons.edit_rounded, color: AppColors.white),
                tooltip: 'edit_profile.title'.tr,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => SafeArea(
                top: false,
                child: DataStateBuilder<KycProfile>(
                  state: controller.state,
                  onRetry: controller.load,
                  skeleton: const _KycSkeleton(),
                  builder: (profile) => _KycBody(profile: profile),
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

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------
class _KycBody extends StatelessWidget {
  const _KycBody({required this.profile});
  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileChip(profile: profile),
          // 14.verticalSpace,
          // const _WarningBanner(),
          22.verticalSpace,
          _VerificationSection(profile: profile),
          22.verticalSpace,
          _PersonalDetailsSection(profile: profile),
          14.verticalSpace,
          const _PayoutNote(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile chip
// ---------------------------------------------------------------------------
class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.profile});
  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.track,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          _ProfileAvatar(url: profile.avatarUrl, name: profile.name),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppText.base(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                3.verticalSpace,
                Text(
                  profile.since,
                  style: AppText.base(
                    fontSize: 13.sp,
                    color: scheme.onSurface.withValues(alpha: 0.6),
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

/// Avatar that falls back to the user's initial when the API sends no (or an
/// empty) avatar URL — `NetworkImage('')` throws while resolving.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = Uri.tryParse(url)?.hasAuthority ?? false;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 28.r,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      backgroundImage: hasImage ? NetworkImage(url) : null,
      child: hasImage
          ? null
          : Text(
              initial,
              style: AppText.base(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Warning banner
// ---------------------------------------------------------------------------
class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18.w,
                color: AppTheme.accent,
              ),
              Gap.hSm,
              Expanded(
                child: Text(
                  'kyc.blocks_reward'.tr,
                  style: AppText.base(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          6.verticalSpace,
          Text(
            'kyc.blocks_reward_body'.tr,
            style: AppText.base(
              fontSize: 13.sp,
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification
// ---------------------------------------------------------------------------
class _VerificationSection extends StatelessWidget {
  const _VerificationSection({required this.profile});
  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'kyc.verification'.tr,
                style: AppText.base(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${profile.doneCount}/${profile.totalCount} ${'kyc.done'.tr}',
                style: AppText.base(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent.withValues(alpha: 1),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          radius: 18,
          child: Column(
            children: [
              for (var i = 0; i < profile.steps.length; i++) ...[
                _VerificationRow(step: profile.steps[i]),
                if (i < profile.steps.length - 1)
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    indent: 14.w,
                    endIndent: 14.w,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({required this.step});
  final KycVerificationStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionColor = step.isDone
        ? AppColors.success
        : step.isInReview
        ? AppTheme.accent
        : scheme.error;
    final actionLabel = step.isDone
        ? 'kyc.status_done'.tr
        : step.isInReview
        ? 'kyc.status_in_review'.tr
        : 'kyc.status_upload'.tr;
    final locked = step.isDone || step.isInReview;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: locked ? null : () => Get.toNamed(AppRoutes.kycDocuments),
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title.tr,
                      style: AppText.base(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    3.verticalSpace,
                    Text(
                      step.subtitle.tr,
                      style: AppText.base(
                        fontSize: 12.5.sp,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                actionLabel,
                style: AppText.base(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                ),
              ),
              if (!locked)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.w,
                  color: actionColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal details (gradient card)
// ---------------------------------------------------------------------------
class _PersonalDetailsSection extends StatelessWidget {
  const _PersonalDetailsSection({required this.profile});
  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'kyc.personal_details'.tr,
                style: AppText.base(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'kyc.edit'.tr,
                style: AppText.base(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient(scheme),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 22.r,
                spreadRadius: -6.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < profile.details.length; i++) ...[
                _DetailRow(row: profile.details[i]),
                if (i < profile.details.length - 1)
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});
  final KycDetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            row.icon,
            size: 18.w,
            color: AppColors.white.withValues(alpha: 0.85),
          ),
          Gap.hMd,
          Text(
            row.label.tr,
            style: AppText.base(
              fontSize: 14.sp,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          Gap.hSm,
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payout note
// ---------------------------------------------------------------------------
class _PayoutNote extends StatelessWidget {
  const _PayoutNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.w,
                color: scheme.primary,
              ),
              Gap.hSm,
              Expanded(
                child: Text(
                  'kyc.payout_note_title'.tr,
                  style: AppText.base(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          6.verticalSpace,
          Text(
            'kyc.payout_note_body'.tr,
            style: AppText.base(
              fontSize: 13.sp,
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton
// ---------------------------------------------------------------------------
class _KycSkeleton extends StatelessWidget {
  const _KycSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerBox(height: 76.h, radius: 18.r),
          14.verticalSpace,
          ShimmerBox(height: 88.h, radius: 14.r),
          22.verticalSpace,
          ShimmerBox(width: 140.w, height: 18.h),
          Gap.vMd,
          ShimmerBox(height: 190.h, radius: 18.r),
          22.verticalSpace,
          ShimmerBox(width: 160.w, height: 18.h),
          Gap.vMd,
          ShimmerBox(height: 260.h, radius: 18.r),
          22.verticalSpace,
          ShimmerBox(width: 120.w, height: 18.h),
          Gap.vMd,
          ShimmerBox(height: 240.h, radius: 18.r),
        ],
      ),
    );
  }
}
