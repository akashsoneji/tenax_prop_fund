import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_labeled_field.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/edit_profile_controller.dart';

/// Edit Profile screen: a gradient avatar hero (with the app's asymmetric
/// half-circle pill radius) over a card of editable personal-detail fields and
/// a gradient Save CTA.
class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          PinnedGradientAppBar(title: 'edit_profile.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AvatarHero(),
                  const SizedBox(height: 22),
                  AppLabeledField(
                    controller: controller.fullName,
                    label: 'edit_profile.full_name'.tr,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    controller: controller.email,
                    label: 'edit_profile.email'.tr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    controller: controller.mobile,
                    label: 'edit_profile.mobile'.tr,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    controller: controller.dateOfBirth,
                    label: 'edit_profile.date_of_birth'.tr,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    controller: controller.country,
                    label: 'edit_profile.country'.tr,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => AppGradientButton(
                      label: 'edit_profile.save'.tr,
                      loading: controller.saving.value,
                      onPressed: controller.save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar hero — gradient pill with the app's asymmetric half-circle corner.
// ---------------------------------------------------------------------------
class _AvatarHero extends StatelessWidget {
  const _AvatarHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 22),
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
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
        backgroundColor: AppColors.white.withValues(alpha: 0.16),
                child: const Icon(Icons.person_rounded,
                    size: 34, color: AppColors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 1.5),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 13, color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit_profile.hero_title'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'edit_profile.hero_subtitle'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.3,
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
