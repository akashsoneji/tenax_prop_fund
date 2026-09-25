import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_models.dart';

/// "Request a payout" sheet — mirrors the web form: withdrawable strip,
/// Amount*, Payout method*, Trading account (optional), Notes (optional) and
/// password confirmation, with Cancel / Submit. Submit logic lives in
/// [RewardsController.submitRequest].
class RequestPayoutSheet extends StatefulWidget {
  const RequestPayoutSheet({super.key});

  @override
  State<RequestPayoutSheet> createState() => _RequestPayoutSheetState();
}

class _RequestPayoutSheetState extends State<RequestPayoutSheet> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _password = TextEditingController();
  final _obscure = true.obs;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RewardsController>();
    final scheme = Theme.of(context).colorScheme;
    final data = c.state.valueOrNull;
    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onClose: () => _close(c)),
              Divider(height: 1.h, color: scheme.outlineVariant),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BalanceStrip(data: data),
                      SizedBox(height: 12.h),
                      _Field(
                        label: 'rewards.amount_usd'.tr,
                        required: true,
                        child: _Input(
                          controller: _amount,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: c.setAmount,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _Field(
                        label: 'rewards.payout_method'.tr,
                        required: true,
                        child: Obx(() => _Dropdown<String?>(
                              value: c.selectedMethod.value,
                              items: <String?, String>{
                                for (final m in data.payoutMethods) m.id: m.label,
                              },
                              onChanged: (v) {
                                if (v != null) c.selectMethod(v);
                              },
                            )),
                      ),
                      SizedBox(height: 10.h),
                      _Field(
                        label: 'rewards.trading_account_optional'.tr,
                        child: Obx(() => _Dropdown<String?>(
                              value: c.selectedAccountId.value,
                              items: {
                                null: 'rewards.none'.tr,
                                for (final a in data.accounts) a.id: a.label,
                              },
                              onChanged: c.selectAccount,
                            )),
                      ),
                      SizedBox(height: 10.h),
                      _Field(
                        label: 'rewards.notes_optional'.tr,
                        child: _Input(controller: _notes, maxLines: 2),
                      ),
                      SizedBox(height: 10.h),
                      _Field(
                        label: 'rewards.password_confirm'.tr,
                        helper: 'rewards.password_helper'.tr,
                        child: Obx(() => _Input(
                              controller: _password,
                              obscure: _obscure.value,
                              suffix: IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _obscure.toggle(),
                                icon: Icon(
                                  _obscure.value
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18.w,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1.h, color: scheme.outlineVariant),
              _Actions(
                submitting: c.isSubmitting,
                onCancel: () => _close(c),
                onSubmit: () => _submit(c, data),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✕ / Cancel: discard everything so the next open starts blank.
  void _close(RewardsController c) {
    _resetForm(c);
    Navigator.of(context).pop();
  }

  Future<void> _submit(RewardsController c, RewardsData data) async {
    final result = await c.submitRequest(
      data,
      notes: _notes.text,
      password: _password.text,
    );
    if (!mounted) return;

    // Local validation (bad amount / no method) → keep the sheet open so the
    // user can fix it; show the reason in the top toast.
    if (result.isLocalValidation) {
      if (result.message != null) AppToast.error(result.message!);
      return;
    }

    // Server answered (success or e.g. 422 "No open payout cycle…"): close and
    // reset. On failure ApiEnvelope.guard has already shown the server message
    // as a top toast, so we don't show it twice.
    _resetForm(c);
    Navigator.of(context).pop();
    if (result.isSuccess) {
      AppToast.success(
        'rewards.payout_requested_body'.tr,
        title: 'rewards.payout_requested'.tr,
      );
    }
  }

  void _resetForm(RewardsController c) {
    _amount.clear();
    _notes.clear();
    _password.clear();
    _obscure.value = true;
    c.setAmount('');
    c.selectAccount(null);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 6.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'rewards.request_payout'.tr,
              style: text.titleMedium?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 20.w),
          ),
        ],
      ),
    );
  }
}

/// "Withdrawable: $2.50 · Minimum $1" — straight from the rewards API.
class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.data});
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12.5.sp,
          color: scheme.onSurfaceVariant,
        );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: '${'rewards.withdrawable'.tr}: '),
            TextSpan(
              text: data.withdrawable.amountUsd,
              style: base?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            TextSpan(text: ' · ${'rewards.minimum'.tr} ${data.minPayout}'),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
            ],
          ),
          style: text.labelLarge?.copyWith(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 5.h),
        child,
        if (helper != null) ...[
          SizedBox(height: 4.h),
          Text(
            helper!,
            style: text.bodySmall?.copyWith(
              fontSize: 11.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration _decoration(BuildContext context, {String? hint, Widget? suffix}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.4),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      minLines: 1,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
      decoration: _decoration(context, hint: hint, suffix: suffix),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: items.containsKey(value) ? value : null,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, size: 20.w),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
      decoration: _decoration(context),
      items: [
        for (final e in items.entries)
          DropdownMenuItem<T>(
            value: e.key,
            child: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final RxBool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text('rewards.cancel_no'.tr),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Obx(() => AppGradientButton(
                  label: 'rewards.submit_request'.tr,
                  height: 44.h,
                  loading: submitting.value,
                  onPressed: submitting.value ? null : onSubmit,
                )),
          ),
        ],
      ),
    );
  }
}
