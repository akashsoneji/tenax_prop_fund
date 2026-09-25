import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import 'animated_field.dart';
import 'glass_card.dart';

/// Two-factor authenticator-code entry, shown when `POST /auth/login` answers
/// `two_factor_required: true` with a `challenge_token`.
///
/// 6-cell code entry: each cell takes one digit, focus auto-advances, backspace
/// steps back and a pasted code is split across the cells. Also accepts an
/// 8-character recovery code through the "use a recovery code" toggle.
///
/// [onVerify] performs the network call and returns `null` on success or an
/// error message to show inline. On success the dialog closes and returns the
/// submitted code; cancelling returns `null`.
class TwoFactorDialog extends StatefulWidget {
  const TwoFactorDialog({
    super.key,
    required this.onVerify,
    this.allowRecoveryCode = true,
  });

  final Future<String?> Function(String code, {required bool isRecoveryCode})
      onVerify;

  /// Shows the "use a recovery code" toggle. Off when the backend has no
  /// recovery-code fallback for this account.
  final bool allowRecoveryCode;

  static Future<String?> show({
    required Future<String?> Function(String code, {required bool isRecoveryCode})
        onVerify,
    bool allowRecoveryCode = true,
  }) {
    return showGeneralDialog<String>(
      context: Get.context!,
      barrierDismissible: false,
      barrierLabel: 'two_factor',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.base,
      pageBuilder: (context, anim, sec) => TwoFactorDialog(
        onVerify: onVerify,
        allowRecoveryCode: allowRecoveryCode,
      ),
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
  State<TwoFactorDialog> createState() => _TwoFactorDialogState();
}

class _TwoFactorDialogState extends State<TwoFactorDialog> {
  static const _length = 6;

  final List<TextEditingController> _ctrls = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());
  final _recoveryCtrl = TextEditingController();
  final _shake = ShakeController();

  String? _error;
  bool _busy = false;
  bool _useRecovery = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _recoveryCtrl.dispose();
    super.dispose();
  }

  String get _code =>
      _useRecovery ? _recoveryCtrl.text.trim() : _ctrls.map((c) => c.text).join();

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
    if (value.isNotEmpty && i < _length - 1) _focus(i + 1);
    if (_error != null) setState(() => _error = null);
  }

  void _onBackspace(int i) {
    if (_ctrls[i].text.isEmpty && i > 0) _focus(i - 1);
  }

  void _focus(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[i].requestFocus();
    });
  }

  void _toggleRecovery() {
    setState(() {
      _useRecovery = !_useRecovery;
      _error = null;
      _recoveryCtrl.clear();
      for (final c in _ctrls) {
        c.clear();
      }
    });
  }

  void _fail(String message) {
    setState(() {
      _busy = false;
      _error = message;
    });
    _shake.shake();
    HapticFeedback.mediumImpact();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final value = _code;

    if (_useRecovery) {
      if (value.isEmpty) {
        _fail('two_factor.recovery_required'.tr);
        return;
      }
    } else if (value.length != _length || int.tryParse(value) == null) {
      _fail('two_factor.invalid_code'.tr);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onVerify(value, isRecoveryCode: _useRecovery);
    if (!mounted) return;
    if (error == null) {
      Get.back(result: value);
      return;
    }
    _fail(error);
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(useRecovery: _useRecovery),
                  SizedBox(height: 20.h),
                  ShakeWidget(
                    controller: _shake,
                    child: _useRecovery
                        ? _RecoveryField(
                            controller: _recoveryCtrl,
                            hasError: _error != null,
                            onSubmitted: _verify,
                          )
                        : Row(
                            children: List.generate(_length, (i) {
                              return Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 4.w),
                                  child: _PinCell(
                                    controller: _ctrls[i],
                                    focusNode: _nodes[i],
                                    onChanged: (v) => _onChanged(i, v),
                                    onBackspace: () => _onBackspace(i),
                                    hasError: _error != null,
                                    autofocus: i == 0,
                                    onSubmitted:
                                        i == _length - 1 ? _verify : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (widget.allowRecoveryCode) ...[
                    SizedBox(height: 10.h),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _toggleRecovery,
                        child: Text(
                          _useRecovery
                              ? 'two_factor.use_auth_code'.tr
                              : 'two_factor.use_recovery_code'.tr,
                          style: TextStyle(
                            color: _busy
                                ? scheme.onSurface.withValues(alpha: 0.5)
                                : scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => Get.back(),
                        child: Text('common.cancel'.tr),
                      ),
                      SizedBox(width: 8.w),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.useRecovery});

  final bool useRecovery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shield_outlined,
            size: 26.w,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'two_factor.title'.tr,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          useRecovery
              ? 'two_factor.recovery_subtitle'.tr
              : 'two_factor.subtitle'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.65),
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

class _RecoveryField extends StatelessWidget {
  const _RecoveryField({
    required this.controller,
    required this.hasError,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool hasError;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasError ? scheme.error : scheme.outline.withValues(alpha: 0.20),
          width: 1.6.w,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: TextField(
        controller: controller,
        autofocus: true,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => onSubmitted(),
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'two_factor.recovery_hint'.tr,
          hintStyle: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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
    required this.autofocus,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool hasError;
  final bool autofocus;
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
            autofocus: autofocus,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: TextStyle(
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
