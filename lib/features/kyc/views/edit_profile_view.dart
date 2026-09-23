import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // const _AvatarHero(),
                  // SizedBox(height: 22.h),
                  AppLabeledField(
                    controller: controller.fullName,
                    label: 'edit_profile.full_name'.tr,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12.h),
                  AppLabeledField(
                    controller: controller.email,
                    label: 'edit_profile.email'.tr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12.h),
                  AppLabeledField(
                    controller: controller.mobile,
                    label: 'edit_profile.mobile'.tr,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12.h),
                  AppLabeledField(
                    controller: controller.country,
                    label: 'edit_profile.country'.tr,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 24.h),
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
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 12.w, 22.h),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
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
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34.r,
        backgroundColor: AppColors.white.withValues(alpha: 0.16),
                child: Icon(Icons.person_rounded,
                    size: 34.w, color: AppColors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 1.5.w),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 13.w, color: scheme.primary),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit_profile.hero_title'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'edit_profile.hero_subtitle'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
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
