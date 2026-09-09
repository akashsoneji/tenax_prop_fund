import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
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
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.track,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : scheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              backgroundImage: NetworkImage(profile.avatarUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(color: scheme.onSurface, fontSize: 16)),
                const SizedBox(height: 4),
                Text(profile.since,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12)),
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
                    style: AppText.subtitle(
                        color: scheme.onSurface, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('kyc.blocks_reward_body'.tr,
              style: AppText.body(
                  fontSize: 12,
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
                  style: AppText.title(color: scheme.onSurface, fontSize: 16)),
              Text('${profile.doneCount}/${profile.totalCount} ${'kyc.done'.tr}',
                  style: AppText.subtitle(color: AppTheme.accent, fontSize: 12)),
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
                        style: AppText.title(
                            color: scheme.onSurface, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(step.subtitle,
                        style: AppText.label(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontSize: 12)),
                  ],
                ),
              ),
              Text(step.isDone ? 'kyc.status_done'.tr : 'kyc.status_upload'.tr,
                  style: AppText.subtitle(color: actionColor, fontSize: 14)),
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
                  style: AppText.title(color: scheme.onSurface, fontSize: 16)),
              Text('kyc.edit'.tr,
                  style: AppText.subtitle(color: scheme.primary, fontSize: 14)),
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
      color: AppColors.brandPurpleLight.withValues(alpha: 0.35),
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
              style: AppText.subtitle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.subtitle(color: AppColors.white, fontSize: 14),
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
                    style: AppText.subtitle(color: scheme.primary, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('kyc.payout_note_body'.tr,
              style: AppText.body(
                  fontSize: 12,
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
              style: AppText.title(color: scheme.onSurface, fontSize: 16)),
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
                  style: AppText.subtitle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontSize: 14)),
              const Spacer(),
              Text(row.value,
                  style: AppText.subtitle(
                      color: scheme.onSurface, fontSize: 14)),
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
