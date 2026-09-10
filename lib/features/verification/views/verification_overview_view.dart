import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';
import '../widgets/exit_verification_dialog.dart';
import '../widgets/verification_step_card.dart';

/// Entry screen of the verification journey: a shield header, a vertical
/// timeline of the three steps (dot + connector rail beside each card), and a
/// gradient CTA with a "secure & encrypted" note — mirroring white_label's
/// KYC intro screen.
class VerificationOverviewView extends GetView<VerificationController> {
  const VerificationOverviewView({super.key});

  Future<void> _confirmExit() async {
    if (await ExitVerificationDialog.show()) Get.back();
  }

  /// Jumps straight to the first incomplete full screen — Personal → Documents
  /// → Bank — mirroring white_label's intro navigation. Falls through to the
  /// Bank screen once the earlier steps are done.
  void _start() {
    final steps = controller.steps;
    if (!steps[0].status.isCompleted) {
      Get.toNamed(AppRoutes.verificationPersonal);
    } else if (!steps[1].status.isCompleted) {
      Get.toNamed(AppRoutes.verificationDocuments);
    } else {
      Get.toNamed(AppRoutes.addBank);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(
            title: 'verification.verify_account'.tr,
            actions: [
              IconButton(
                onPressed: _confirmExit,
                icon: const Icon(Icons.cancel_outlined, color: AppColors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _VerifyHeader(),
                  SizedBox(height: 28.h),
                  for (var i = 0; i < controller.steps.length; i++)
                    _TimelineStep(
                      step: controller.steps[i],
                      highlighted: i == 0,
                      isLast: i == controller.steps.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGradientButton(
              label: 'verification.start'.tr,
              onPressed: _start,
            ),
            SizedBox(height: 12.h),
            const _SecureNote(),
          ],
        ),
      ),
    );
  }
}

/// Shield badge + title + subtitle row.
class _VerifyHeader extends StatelessWidget {
  const _VerifyHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 88.w,
          width: 88.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Container(
            height: 60.w,
            width: 60.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: AppTheme.brandGradient(scheme),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.30),
                  blurRadius: 16.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: AppColors.white,
              size: 30.w,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'verification.header_title'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'verification.header_subtitle'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A thin left rail (status dot + connector line) beside one step card.
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.highlighted,
    required this.isLast,
  });

  final VerificationStep step;
  final bool highlighted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Column(
              children: [
                SizedBox(height: 22.h),
                _StatusDot(status: step.status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      margin: EdgeInsets.symmetric(vertical: 2.h),
                      color: scheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
              child: VerificationStepCard(
                step: step,
                highlighted: highlighted,
                showStepLabel: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status.isCompleted) {
      return Container(
        height: 16.w,
        width: 16.w,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
        ),
        child: Icon(Icons.check, color: AppColors.white, size: 11.w),
      );
    }
    return Container(
      height: 14.w,
      width: 14.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 3,
        ),
      ),
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grey = scheme.onSurface.withValues(alpha: 0.55);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14.w, color: grey),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            'verification.secure_note'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: grey,
            ),
          ),
        ),
      ],
    );
  }
}
