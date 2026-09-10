import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileChip(profile: profile),
          const SizedBox(height: 14),
          const _WarningBanner(),
          const SizedBox(height: 22),
          _VerificationSection(profile: profile),
          const SizedBox(height: 22),
          _PersonalDetailsSection(profile: profile),
          const SizedBox(height: 14),
          const _PayoutNote(),
          const SizedBox(height: 22),
          _NewsAlertsSection(profile: profile),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.white.withValues(alpha: 0.05)
        : AppColors.track,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            backgroundImage: NetworkImage(profile.avatarUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(profile.since,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('kyc.blocks_reward'.tr,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('kyc.blocks_reward_body'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
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
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('kyc.verification'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              Text('${profile.doneCount}/${profile.totalCount} ${'kyc.done'.tr}',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
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
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
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
    const green = AppColors.success;
    final actionColor = step.isDone ? green : scheme.error;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.verification),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(step.subtitle,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Text(step.isDone ? 'kyc.status_done'.tr : 'kyc.status_upload'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: actionColor)),
              Icon(Icons.chevron_right_rounded, size: 20, color: actionColor),
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
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('kyc.personal_details'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              Text('kyc.edit'.tr,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient(scheme),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < profile.details.length; i++) ...[
                _DetailRow(row: profile.details[i]),
                if (i < profile.details.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(row.icon, size: 18, color: AppColors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Text(row.label,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.9))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('kyc.payout_note_title'.tr,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('kyc.payout_note_body'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// News alerts
// ---------------------------------------------------------------------------
class _NewsAlertsSection extends StatelessWidget {
  const _NewsAlertsSection({required this.profile});
  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('kyc.news_alerts'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: AppTheme.surfaceCard(scheme, radius: 18),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < profile.alerts.length; i++) ...[
                _AlertRow(row: profile.alerts[i]),
                if (i < profile.alerts.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.row});
  final KycAlertRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(row.label,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.75))),
              const Spacer(),
              Text(row.value,
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ShimmerBox(height: 76, radius: 18),
          SizedBox(height: 14),
          ShimmerBox(height: 88, radius: 14),
          SizedBox(height: 22),
          ShimmerBox(width: 140, height: 18),
          SizedBox(height: 12),
          ShimmerBox(height: 190, radius: 18),
          SizedBox(height: 22),
          ShimmerBox(width: 160, height: 18),
          SizedBox(height: 12),
          ShimmerBox(height: 260, radius: 18),
          SizedBox(height: 22),
          ShimmerBox(width: 120, height: 18),
          SizedBox(height: 12),
          ShimmerBox(height: 240, radius: 18),
        ],
      ),
    );
  }
}
