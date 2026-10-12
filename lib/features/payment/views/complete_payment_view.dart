import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/localization/backend_label_tr.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/complete_payment_controller.dart';
import '../models/order_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';

/// Manual "Complete payment" screen. Mirrors the web checkout: an amount-due
/// hero, the selected method's crypto/bank details and a proof-upload card.
/// After a successful proof upload the whole screen flips to an "under review"
/// confirmation.
class CompletePaymentView extends GetView<CompletePaymentController> {
  const CompletePaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'payment.title'.tr),
          SliverToBoxAdapter(
            child: Obx(() {
              return DataStateBuilder<OrderDetails>(
                state: controller.state.value,
                onRetry: controller.fetch,
                skeleton: const _PaymentSkeleton(),
                builder: (data) => _PaymentBody(data: data),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PaymentBody extends StatelessWidget {
  const _PaymentBody({required this.data});
  final OrderDetails data;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CompletePaymentController>();
    final order = data.order;
    final review = order.isUnderReview;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CheckoutHero(order: order),
          Gap.vLg,
          if (review)
            const _UnderReviewCard()
          else ...[
            if (data.instructions != null) ...[
              _MethodCard(instructions: data.instructions!),
              Gap.vLg,
            ],
            _UploadProofCard(controller: c),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amount-due hero
// ---------------------------------------------------------------------------

class _CheckoutHero extends StatelessWidget {
  const _CheckoutHero({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        // gradient: AppTheme.brandGradient(scheme),
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'payment.amount_due'.tr.toUpperCase(),
                  style: AppText.base(
                    color: AppColors.white.withValues(alpha: 0.72),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _StatusPill(status: order.status),
            ],
          ),
          Gap.vSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    order.total,
                    maxLines: 1,
                    style: AppText.base(
                      color: AppColors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Gap.hMd,
              Flexible(
                child: Text(
                  order.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (order.number.isNotEmpty) ...[
            10.verticalSpace,
            Text(
              'payment.order'.trParams({'number': order.number}),
              style: AppText.base(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: trBackend(status.replaceAll('_', ' ')),
      color: AppColors.white,
      bgAlpha: 0.20,
      fontSize: 11,
    );
  }
}

// ---------------------------------------------------------------------------
// Method details card
// ---------------------------------------------------------------------------

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.instructions});
  final PaymentInstructions instructions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 18.r,
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trBackend(instructions.name),
                  style: AppText.base(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (instructions.type.isNotEmpty)
                _TypeBadge(type: instructions.type),
            ],
          ),
          14.verticalSpace,
          for (final entry in instructions.fields.entries) ...[
            _DetailRow(label: entry.key, value: entry.value),
            Gap.vMd,
          ],
          if (instructions.instructionsText.isNotEmpty)
            _InstructionsNote(text: instructions.instructionsText),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPill(
      label: trBackend(type),
      color: scheme.primary,
      fontSize: 11,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    );
  }
}

/// A label + selectable value row. Long values (addresses) wrap and can be
/// copied via long-press through [SelectableText].
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trBackend(_humanize(label)),
          style: AppText.base(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        3.verticalSpace,
        SelectableText(
          value,
          style: AppText.base(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  static String _humanize(String key) {
    if (key.isEmpty) return key;
    final spaced = key.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _InstructionsNote extends StatelessWidget {
  const _InstructionsNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16.w, color: scheme.primary),
          Gap.hSm,
          Expanded(
            child: Text(
              trBackend(text),
              style: AppText.base(
                fontSize: 12.5.sp,
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload proof card
// ---------------------------------------------------------------------------

class _UploadProofCard extends StatelessWidget {
  const _UploadProofCard({required this.controller});
  final CompletePaymentController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 18.r,
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'payment.upload_title'.tr,
            style: AppText.base(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          14.verticalSpace,
          Text(
            'payment.reference_label'.tr,
            style: AppText.base(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Gap.vSm,
          TextField(
            onChanged: (v) => controller.reference.value = v,
            textInputAction: TextInputAction.done,
            style: AppText.base(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'payment.reference_hint'.tr,
              filled: true,
              fillColor: scheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Gap.vLg,
          Text(
            'payment.proof_label'.tr,
            style: AppText.base(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Gap.vSm,
          Obx(
            () => _ProofPicker(
              file: controller.proofFile.value,
              onPick: () => _pickProof(controller),
            ),
          ),
          Gap.vSm,
          Text(
            'payment.proof_hint'.tr,
            style: AppText.base(
              fontSize: 11.5.sp,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          18.verticalSpace,
          Obx(
            () => AppGradientButton(
              label: 'payment.submit'.tr,
              loading: controller.submitting.value,
              onPressed: controller.canSubmit ? controller.submitProof : null,
            ),
          ),
          Gap.vMd,
          Text(
            'payment.footer_note'.tr,
            textAlign: TextAlign.center,
            style: AppText.base(
              fontSize: 11.5.sp,
              color: scheme.onSurface.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProof(CompletePaymentController controller) {
    return controller.pickProof(() async {
      final picked = await FilePicker.pickFile(type: FileType.image);
      return picked?.path;
    });
  }
}

class _ProofPicker extends StatelessWidget {
  const _ProofPicker({required this.file, required this.onPick});
  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final has = file != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: has ? 160.h : 96.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: has
                ? AppColors.success.withValues(alpha: 0.6)
                : scheme.primary.withValues(alpha: 0.3),
            width: 1.4.w,
          ),
        ),
        child: has
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file!, fit: BoxFit.cover),
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16.w,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 28.w,
                    color: scheme.primary,
                  ),
                  6.verticalSpace,
                  Text(
                    'payment.choose_file'.tr,
                    style: AppText.base(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Under-review confirmation
// ---------------------------------------------------------------------------

class _UnderReviewCard extends StatelessWidget {
  const _UnderReviewCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: 18.r,
      padding: EdgeInsets.all(22.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 34.w,
              color: AppColors.success,
            ),
          ),
          Gap.vLg,
          Text(
            'payment.review_title'.tr,
            textAlign: TextAlign.center,
            style: AppText.base(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Gap.vSm,
          Text(
            'payment.review_message'.tr,
            textAlign: TextAlign.center,
            style: AppText.base(
              fontSize: 13.sp,
              color: scheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          20.verticalSpace,
          AppGradientButton(
            label: 'payment.done'.tr,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _PaymentSkeleton extends StatelessWidget {
  const _PaymentSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
      height: h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      child: AppShimmer(
        child: Column(children: [box(120.h), box(180.h), box(260.h)]),
      ),
    );
  }
}
