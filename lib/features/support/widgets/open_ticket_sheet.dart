import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/support_controller.dart';

/// The "Open a ticket" bottom sheet: white rounded top with a red circular
/// close X, a Topic dropdown, an Account dropdown, a multiline Message field,
/// a light-purple rule-answer info box, and the Send CTA.
class OpenTicketSheet extends StatelessWidget {
  const OpenTicketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<SupportController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open a ticket',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    _CloseButton(onTap: Get.back),
                  ],
                ),
                SizedBox(height: 16.h),
                _Label('Topic'),
                _SheetDropdown(
                  options: c.topics,
                  value: c.selectedTopic,
                  onChanged: c.selectTopic,
                ),
                SizedBox(height: 14.h),
                _Label('Account'),
                _SheetDropdown(
                  options: c.accounts,
                  value: c.selectedAccount,
                  onChanged: c.selectAccount,
                ),
                SizedBox(height: 14.h),
                _Label('Message'),
                TextField(
                  minLines: 4,
                  maxLines: 6,
                  onChanged: c.setMessage,
                  style: GoogleFonts.beVietnamPro(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'support.ticket_hint'.tr,
                  ),
                ),
                SizedBox(height: 16.h),
                _RuleAnswerBox(),
                SizedBox(height: 18.h),
                AppGradientButton(
                  label: 'Send',
                  icon: Icons.send_rounded,
                  onPressed: Get.back,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SheetDropdown extends StatelessWidget {
  const _SheetDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final RxString value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: value.value,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12.r),
        style: GoogleFonts.beVietnamPro(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _RuleAnswerBox extends StatelessWidget {
  const _RuleAnswerBox();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: scheme.primary, size: 20.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A written rule answer binds us',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'If support tells you a strategy is allowed, that answer '
                  'stands for your account.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5.sp,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerBright,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 18.w),
        ),
      ),
    );
  }
}
