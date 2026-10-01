import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/support_controller.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

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
                        'support.open_ticket'.tr,
                        style: AppText.base(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    _CloseButton(onTap: Get.back),
                  ],
                ),
                Gap.vLg,
                _Label('support.field_topic'.tr),
                _TopicDropdown(c: c),
                14.verticalSpace,
                _Label('support.field_subject'.tr),
                TextField(
                  onChanged: c.setSubject,
                  style: AppText.base(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'support.subject_hint'.tr,
                  ),
                ),
                14.verticalSpace,
                _Label('support.field_message'.tr),
                TextField(
                  minLines: 4,
                  maxLines: 6,
                  onChanged: c.setMessage,
                  style: AppText.base(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'support.ticket_hint'.tr,
                  ),
                ),
                Gap.vLg,
                _RuleAnswerBox(),
                18.verticalSpace,
                Obx(
                  () => AppGradientButton(
                    label: 'support.send'.tr,
                    icon: Icons.send_rounded,
                    loading: c.submitting.value,
                    onPressed: () async {
                      final ok = await c.submitTicket();
                      if (ok) Get.back();
                    },
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
        style: AppText.base(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TopicDropdown extends StatelessWidget {
  const _TopicDropdown({required this.c});

  final SupportController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final topics = c.topics;
      final selected = c.selectedTopic.value.isEmpty
          ? null
          : c.selectedTopic.value;
      return DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        hint: Text('support.select_topic'.tr),
        borderRadius: BorderRadius.circular(12.r),
        style: AppText.base(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        items: [
          for (final t in topics)
            DropdownMenuItem(value: t.value, child: Text(t.label)),
        ],
        onChanged: (v) {
          if (v != null) c.selectTopic(v);
        },
      );
    });
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
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'support.rule_answer_title'.tr,
                  style: AppText.base(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                3.verticalSpace,
                Text(
                  'support.rule_answer_body'.tr,
                  style: AppText.base(
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
