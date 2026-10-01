import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_dashed.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';
import '../widgets/exit_verification_dialog.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Full-screen ID/address document upload, mirroring white_label's KYC docs
/// screen: two sections (ID Proof, Address Proof) each with a front + back
/// dashed upload tile, and a Camera/Gallery bottom sheet on tap.
class VerificationDocumentsView extends GetView<VerificationController> {
  const VerificationDocumentsView({super.key});

  Future<void> _confirmExit() async {
    if (await ExitVerificationDialog.show()) Get.back();
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'verification.docs_subtitle'.tr,
                    style: AppText.base(
                      fontSize: 13.5.sp,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  22.verticalSpace,
                  _ProofSection(
                    title: 'verification.id_proof'.tr,
                    front: controller.idFront,
                    back: controller.idBack,
                    onFront: () => _pickSheet(context, ProofKind.idFront),
                    onBack: () => _pickSheet(context, ProofKind.idBack),
                  ),
                  26.verticalSpace,
                  _ProofSection(
                    title: 'verification.address_proof'.tr,
                    front: controller.addressFront,
                    back: controller.addressBack,
                    onFront: () => _pickSheet(context, ProofKind.addressFront),
                    onBack: () => _pickSheet(context, ProofKind.addressBack),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Obx(
          () => AppGradientButton(
            label: 'verification.save'.tr,
            loading: controller.uploadingDocs.value,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  /// Camera/Gallery chooser bottom sheet. Both entries feed the single
  /// [VerificationController.pickProof] method (the controller owns the picker).
  void _pickSheet(BuildContext context, ProofKind kind) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              22.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: _SheetAction(
                      icon: Icons.camera_alt_rounded,
                      label: 'verification.camera'.tr,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        controller.pickProof(kind);
                      },
                    ),
                  ),
                  14.horizontalSpace,
                  Expanded(
                    child: _SheetAction(
                      icon: Icons.photo_library_rounded,
                      label: 'verification.gallery'.tr,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        controller.pickProof(kind);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Uploads the proofs and, on success, marks the ID step done and moves
  /// forward to the Bank screen.
  Future<void> _save() async {
    final ok = await controller.uploadDocuments();
    if (!ok) return;
    controller.steps[1] = controller.steps[1].copyWith(
      status: VerificationStatus.completed,
    );
    controller.steps.refresh();
    Get.offNamed(AppRoutes.addBank);
  }
}

/// One proof section: a title and a Row of front + back dashed upload tiles.
class _ProofSection extends StatelessWidget {
  const _ProofSection({
    required this.title,
    required this.front,
    required this.back,
    required this.onFront,
    required this.onBack,
  });

  final String title;
  final Rx<ProofSlot> front;
  final Rx<ProofSlot> back;
  final VoidCallback onFront;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.base(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        Gap.vMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(
                () => _UploadTile(
                  label: 'verification.front'.tr,
                  slot: front.value,
                  onTap: onFront,
                  optional: false,
                ),
              ),
            ),
            14.horizontalSpace,
            Expanded(
              child: Obx(
                () => _UploadTile(
                  label: 'verification.back'.tr,
                  slot: back.value,
                  onTap: onBack,
                  optional: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A dashed-border upload tile: shows a "+" (or a check once filled) inside a
/// rounded gradient square, with a label underneath. Filled slots switch to a
/// success-tinted card with a green check badge; back slots show an
/// "Optional" chip when empty.
class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.slot,
    required this.onTap,
    required this.optional,
  });

  final String label;
  final ProofSlot slot;
  final VoidCallback onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = slot.filePath != null;
    final accent = optional && !selected
        ? scheme.onSurface.withValues(alpha: 0.4)
        : scheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165.h,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.success.withValues(alpha: 0.12)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: selected
              ? Border.all(color: AppColors.success, width: 2.w)
              : null,
        ),
        child: Stack(
          children: [
            if (!selected)
              CustomPaint(
                size: Size.infinite,
                painter: AppDashedBorderPainter(
                  color: accent,
                  radius: 12.r,
                  strokeWidth: 1,
                  dash: 6,
                  gap: 4,
                ),
              ),
            if (selected)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(slot.filePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            else
              _Placeholder(label: label, accent: accent),
            if (selected) const _SelectedBadge(),
            if (!selected && optional) const _OptionalChip(),
          ],
        ),
      ),
    );
  }
}

/// Empty-state contents of an upload tile: a gradient "+" box and a label.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.add_rounded, color: AppColors.white, size: 22.w),
          ),
          Gap.vSm,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.base(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green check badge shown in the corner of a filled tile.
class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8.h,
      right: 8.w,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.check, color: AppColors.white, size: 16.w),
      ),
    );
  }
}

/// Muted "Optional" chip pinned to the bottom of an empty back-side tile.
class _OptionalChip extends StatelessWidget {
  const _OptionalChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 8.h,
      left: 8.w,
      right: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'verification.optional'.tr,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.base(fontSize: 12.sp, color: AppColors.white),
        ),
      ),
    );
  }
}

/// A Camera / Gallery action button used inside the picker bottom sheet.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient(scheme),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 18.w),
                Gap.hSm,
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.base(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
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
