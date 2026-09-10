import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_gradient_button.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_models.dart';

/// Modal sheet shown when the user taps "Request a payout" on the Rewards
/// screen. Renders the KYC-name banner, account / amount / method fields
/// and a gradient CTA. Submit logic lives in [RewardsController.submitRequest].
class RequestPayoutSheet extends StatefulWidget {
  const RequestPayoutSheet({super.key});

  @override
  State<RequestPayoutSheet> createState() => _RequestPayoutSheetState();
}

class _RequestPayoutSheetState extends State<RequestPayoutSheet> {
  final _amountFocus = FocusNode();
  late final TextEditingController _amountText;

  @override
  void initState() {
    super.initState();
    _amountText = TextEditingController();
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _amountText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RewardsController>();
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final data = c.state.valueOrNull;
    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.dark
              ? AppColors.sheetDark
              : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 22.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              _SheetHeader(onClose: c.closePayoutSheet),
              SizedBox(height: 18.h),
              _NameMatchBanner(scheme: scheme),
              SizedBox(height: 18.h),
              _AccountPicker(controller: c, data: data),
              SizedBox(height: 14.h),
              _AmountField(
                controller: c,
                textController: _amountText,
                focusNode: _amountFocus,
                scheme: scheme,
              ),
              SizedBox(height: 14.h),
              _MethodPicker(controller: c, data: data),
              SizedBox(height: 22.h),
              _SubmitButton(controller: c, data: data, onSubmitted: () {
                _amountText.clear();
                c.setAmount('');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'rewards.request_payout'.tr,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _CloseButton(onTap: onClose),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.danger, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.close_rounded,
            size: 16.w, color: AppColors.danger),
      ),
    );
  }
}

class _NameMatchBanner extends StatelessWidget {
  const _NameMatchBanner({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.warningInk.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18.w, color: const Color(0xFFA36A00)),
              SizedBox(width: 8.w),
              Text(
                'rewards.name_match_id_short'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFA36A00),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'rewards.name_match_id_short_body'.tr,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5.sp,
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedAccount(data);
      return _SheetField(
        label: 'rewards.account'.tr,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected?.id,
            isExpanded: true,
            icon: const Icon(Icons.expand_more_rounded),
            items: [
              for (final a in data.accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(a.label,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
            ],
            onChanged: (v) {
              if (v != null) controller.selectAccount(v);
            },
          ),
        ),
      );
    });
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.textController,
    required this.focusNode,
    required this.scheme,
  });

  final RewardsController controller;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _SheetField(
      label: 'rewards.amount'.tr,
      child: TextField(
        controller: textController,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: controller.setAmount,
        style: GoogleFonts.beVietnamPro(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        decoration: const InputDecoration(
          hintText: '\$0.00',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return _SheetField(
        label: 'rewards.method'.tr,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedMethod.value,
            isExpanded: true,
            icon: const Icon(Icons.expand_more_rounded),
            items: [
              for (final m in data.payoutMethods)
                DropdownMenuItem(
                  value: m,
                  child: Text(m,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
            ],
            onChanged: (v) {
              if (v != null) controller.selectMethod(v);
            },
          ),
        ),
      );
    });
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.controller,
    required this.data,
    required this.onSubmitted,
  });
  final RewardsController controller;
  final RewardsData data;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppGradientButton(
      label: 'rewards.request_payout_button'.tr,
      icon: Icons.lock_open_rounded,
      onPressed: () {
        final result = controller.submitRequest(data);
        if (result.isSuccess) {
          Get.back();
          onSubmitted();
          Get.snackbar(
            'rewards.payout_requested'.tr,
            'rewards.payout_requested_body'.tr,
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.all(16.w),
            borderRadius: 14.r,
          );
        } else {
          Get.snackbar(
            'rewards.cannot_submit'.tr,
            result.message ?? 'rewards.cannot_submit_body'.tr,
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.all(16.w),
            borderRadius: 14.r,
          );
        }
      },
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: scheme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.track,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ],
    );
  }
}
