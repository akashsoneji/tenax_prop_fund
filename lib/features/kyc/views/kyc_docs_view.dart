import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_dashed.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/kyc_docs_controller.dart';
import '../models/kyc_status.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// KYC document upload screen. Two sections (Identity proof, Proof of address),
/// each with a Front + Back tile laid out to mirror the white_label reference:
/// a dashed 165h card with an icon box, title and an "Optional" chip on the
/// back slots. Tapping a tile opens a camera/gallery sheet; the picked image
/// previews inside the tile. The gradient Submit button posts every selected
/// file in one request.
class KycDocsView extends GetView<KycDocsController> {
  const KycDocsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'kyc.upload_documents'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'kyc.docs_subtitle'.tr,
                    style: AppText.base(
                      fontSize: 13.5.sp,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  22.verticalSpace,
                  _DocSection(
                    title: 'kyc.docs_id_proof'.tr,
                    front: KycDocSlot.idDocument,
                    back: KycDocSlot.idDocumentBack,
                    frontLabel: 'kyc.docs_front'.tr,
                    backLabel: 'kyc.docs_back'.tr,
                  ),
                  Gap.vXl,
                  _DocSection(
                    title: 'kyc.docs_address_proof'.tr,
                    front: KycDocSlot.proofOfAddress,
                    back: KycDocSlot.proofOfAddressBack,
                    frontLabel: 'kyc.docs_front'.tr,
                    backLabel: 'kyc.docs_back'.tr,
                  ),
                  28.verticalSpace,
                  Obx(
                    () => AppGradientButton(
                      label: 'kyc.docs_submit'.tr,
                      loading: controller.submitting.value,
                      onPressed: controller.hasSelection
                          ? controller.submit
                          : null,
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
// Section: a label over a Front + Back tile row.
// ---------------------------------------------------------------------------
class _DocSection extends StatelessWidget {
  const _DocSection({
    required this.title,
    required this.front,
    required this.back,
    required this.frontLabel,
    required this.backLabel,
  });

  final String title;
  final KycDocSlot front;
  final KycDocSlot back;
  final String frontLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
          child: Text(
            title,
            style: AppText.base(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _UploadTile(
                slot: front,
                label: frontLabel,
                optional: false,
              ),
            ),
            Gap.hLg,
            Expanded(
              child: _UploadTile(slot: back, label: backLabel, optional: true),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Upload tile: dashed placeholder (icon box + title + optional chip) or an
// image preview with a clear button. Mirrors the white_label 165h tile.
// ---------------------------------------------------------------------------
class _UploadTile extends GetView<KycDocsController> {
  const _UploadTile({
    required this.slot,
    required this.label,
    required this.optional,
  });

  final KycDocSlot slot;
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final file = controller.fileFor(slot);
      final selected = file != null;
      final accent = optional && !selected
          ? scheme.onSurface.withValues(alpha: 0.4)
          : scheme.primary;
      return GestureDetector(
        onTap: () => _openSourceSheet(context),
        child: Container(
          height: 165.h,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.success.withValues(alpha: 0.12)
                : accent.withValues(alpha: 0.12),
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
                    strokeWidth: 1.w,
                    dash: 6.w,
                    gap: 4.w,
                  ),
                ),
              if (selected)
                _Preview(
                  path: file.path,
                  onClear: () => controller.remove(slot),
                )
              else
                _Placeholder(label: label, accent: accent),
              if (selected) const _SelectedBadge(),
              if (!selected && optional) const _OptionalChip(),
            ],
          ),
        ),
      );
    });
  }

  void _openSourceSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 28.h),
        child: SafeArea(
          top: false,
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
                    child: Text(
                      'kyc.docs_choose_source'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.base(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back<void>(),
                    child: Icon(
                      Icons.close,
                      size: 22.w,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              22.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt,
                      label: 'kyc.docs_camera'.tr,
                      onTap: () {
                        Get.back<void>();
                        controller.pickFromCamera(slot);
                      },
                    ),
                  ),
                  Gap.hLg,
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library,
                      label: 'kyc.docs_gallery'.tr,
                      onTap: () {
                        Get.back<void>();
                        controller.pickFromGallery(slot);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.add, color: AppColors.white, size: 24.w),
          ),
          Gap.vSm,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.onClear});
  final String path;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          Positioned(
            top: 6.h,
            left: 6.w,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16.w,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          'kyc.docs_optional'.tr,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.base(fontSize: 12.sp, color: AppColors.white),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
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
      color: scheme.primary,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 20.w),
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
    );
  }
}
