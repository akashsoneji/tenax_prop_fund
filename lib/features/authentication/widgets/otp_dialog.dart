import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import 'animated_field.dart';
import 'glass_card.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// 6-cell OTP entry. Each cell accepts one digit; auto-advances focus on
/// input, backspace moves focus back, paste from SMS is auto-split.
/// On submit, returns the full code via `Get.back(result:)` or null on cancel.
class OtpDialog extends StatefulWidget {
  const OtpDialog({
    super.key,
    required this.target,
    this.onVerify,
    this.onResend,
  });

  final String target;

  /// Verifies the entered [code]; returns null on success or an error message
  /// to show inline. When null the dialog just returns the code (no API call).
  final Future<String?> Function(String code)? onVerify;

  /// Re-sends the OTP; returns null on success or an error message. When null
  /// the resend button is hidden.
  final Future<String?> Function()? onResend;

  static Future<String?> show({
    required String target,
    Future<String?> Function(String code)? onVerify,
    Future<String?> Function()? onResend,
  }) {
    return showGeneralDialog<String>(
      context: Get.context!,
      barrierDismissible: false,
      barrierLabel: 'otp',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.base,
      pageBuilder: (context, anim, sec) =>
          OtpDialog(target: target, onVerify: onVerify, onResend: onResend),
      transitionBuilder: (context, anim, sec, child) {
        final scaleAnim = CurvedAnimation(parent: anim, curve: AppMotion.enter);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: scaleAnim.drive(Tween<double>(begin: 0.92, end: 1.0)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  static const _length = 6;
  final List<TextEditingController> _ctrls = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());
  final _shake = ShakeController();
  String? _error;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.onResend != null) _startResendTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendIn = 60;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _resendIn -= 1;
        if (_resendIn <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    final onResend = widget.onResend;
    if (onResend == null || _busy || _resendIn > 0) return;
    setState(() => _busy = true);
    final error = await onResend();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) _startResendTimer();
  }

  void _onChanged(int i, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var k = 0; k < _length; k++) {
        final ch = k < digits.length ? digits[k] : '';
        _ctrls[k].text = ch;
        _ctrls[k].selection = TextSelection.collapsed(offset: ch.length);
      }
      _focus(_length - 1);
      return;
    }
    if (value.isNotEmpty && i < _length - 1) {
      _focus(i + 1);
    }
    if (_error != null && _code.isNotEmpty) {
      setState(() => _error = null);
    }
  }

  void _onBackspace(int i) {
    if (_ctrls[i].text.isEmpty && i > 0) {
      _focus(i - 1);
    }
  }

  void _focus(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[i].requestFocus();
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_busy) return;
    final value = _code;
    if (value.length != _length || int.tryParse(value) == null) {
      setState(() => _error = 'otp.invalid_code'.tr);
      _shake.shake();
      HapticFeedback.mediumImpact();
      return;
    }

    final onVerify = widget.onVerify;
    if (onVerify == null) {
      Get.back(result: value);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await onVerify(value);
    if (!mounted) return;
    if (error == null) {
      Get.back(result: value);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
    _shake.shake();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: AppColors.transparent,
        child: GlassCard(
          radius: 24.r,
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'otp.title'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                6.verticalSpace,
                Text(
                  '${'otp.subtitle'.tr}\n${widget.target}',
                  textAlign: TextAlign.center,
                  style: AppText.base(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 13.sp,
                  ),
                ),
                20.verticalSpace,
                ShakeWidget(
                  controller: _shake,
                  child: Row(
                    children: List.generate(_length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: _PinCell(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            onChanged: (v) => _onChanged(i, v),
                            onBackspace: () => _onBackspace(i),
                            hasError: _error != null,
                            onSubmitted: i == _length - 1 ? _verify : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_error != null) ...[
                  10.verticalSpace,
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.base(
                      color: scheme.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (widget.onResend != null) ...[
                  14.verticalSpace,
                  Center(
                    child: TextButton(
                      onPressed: (_busy || _resendIn > 0) ? null : _resend,
                      child: Text(
                        _resendIn > 0
                            ? '${'common.resend'.tr} ${'otp.resend_in'.tr} ${_resendIn}s'
                            : 'common.resend'.tr,
                        style: AppText.base(
                          color: (_busy || _resendIn > 0)
                              ? scheme.onSurface.withValues(alpha: 0.5)
                              : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                18.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => Get.back(),
                      child: Text('common.cancel'.tr),
                    ),
                    Gap.hSm,
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 22.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: _busy ? null : _verify,
                      child: _busy
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2.w,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text('common.verify'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinCell extends StatelessWidget {
  const _PinCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.hasError,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool hasError;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasError
                ? scheme.error
                : (focusNode.hasFocus
                      ? scheme.primary
                      : scheme.outline.withValues(alpha: 0.20)),
            width: 1.6.w,
          ),
        ),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (v) {
              onChanged(v);
              if (v.isEmpty) onBackspace();
            },
            onSubmitted: (_) => onSubmitted?.call(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            autofocus: true,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: AppText.base(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
