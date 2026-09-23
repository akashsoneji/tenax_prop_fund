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
import '../controllers/kyc_controller.dart';
import '../models/kyc_profile.dart';

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
              () => DataStateBuilder<KycProfile>(
                state: controller.state,
                onRetry: controller.load,
                skeleton: const _KycSkeleton(),
                builder: (profile) => _KycBody(profile: profile),
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
          // SizedBox(height: 14.h),
          // const _WarningBanner(),
          SizedBox(height: 22.h),
          _VerificationSection(profile: profile),
          SizedBox(height: 22.h),
          _PersonalDetailsSection(profile: profile),
          SizedBox(height: 14.h),
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
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 17.sp, fontWeight: FontWeight.w700)),
                SizedBox(height: 3.h),
                Text(profile.since,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13.sp,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
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
              style: GoogleFonts.beVietnamPro(
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
            alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18.w, color: AppTheme.accent),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('kyc.blocks_reward'.tr,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text('kyc.blocks_reward_body'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13.sp,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
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
              Text('kyc.verification'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 17.sp, fontWeight: FontWeight.w700)),
              Text('${profile.doneCount}/${profile.totalCount} ${'kyc.done'.tr}',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent.withValues(alpha: 1))),
            ],
          ),
        ),
        Container(
          decoration: AppTheme.surfaceCard(scheme, radius: 18),
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
                    Text(step.title.tr,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 15.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3.h),
                    Text(step.subtitle.tr,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5.sp,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Text(actionLabel,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: actionColor)),
              if (!locked)
                Icon(Icons.chevron_right_rounded,
                    size: 20.w, color: actionColor),
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
              Text('kyc.personal_details'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 17.sp, fontWeight: FontWeight.w700)),
              Text('kyc.edit'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
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
          Icon(row.icon, size: 18.w, color: AppColors.white.withValues(alpha: 0.85)),
          SizedBox(width: 12.w),
          Text(row.label.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14.sp,
                  color: AppColors.white.withValues(alpha: 0.9))),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white),
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
              Icon(Icons.info_outline_rounded, size: 18.w, color: scheme.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('kyc.payout_note_title'.tr,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text('kyc.payout_note_body'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13.sp,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
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
          SizedBox(height: 14.h),
          ShimmerBox(height: 88.h, radius: 14.r),
          SizedBox(height: 22.h),
          ShimmerBox(width: 140.w, height: 18.h),
          SizedBox(height: 12.h),
          ShimmerBox(height: 190.h, radius: 18.r),
          SizedBox(height: 22.h),
          ShimmerBox(width: 160.w, height: 18.h),
          SizedBox(height: 12.h),
          ShimmerBox(height: 260.h, radius: 18.r),
          SizedBox(height: 22.h),
          ShimmerBox(width: 120.w, height: 18.h),
          SizedBox(height: 12.h),
          ShimmerBox(height: 240.h, radius: 18.r),
        ],
      ),
    );
  }
}
