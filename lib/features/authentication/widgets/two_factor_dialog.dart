import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import 'animated_field.dart';

/// Two-factor authenticator-code entry, shown when `POST /auth/login` answers
/// `two_factor_required: true` with a `challenge_token`.
///
/// The 6 cells are PAINTED from a single hidden [TextField] rather than being
/// six real fields: typing and backspace then follow the platform's own text
/// editing (so add/remove never loses a digit), and there is no per-keystroke
/// focus hopping. The surface is a plain theme card — no backdrop blur and no
/// repeating animation — because a blurred, continuously-animating dialog drops
/// frames badly on mid-range devices while the keyboard is up.
///
/// [onVerify] performs the network call and returns `null` on success or an
/// error message to show inline. On success the dialog closes and returns the
/// submitted code; closing it returns `null`.
class TwoFactorDialog extends StatefulWidget {
  const TwoFactorDialog({super.key, required this.onVerify});

  final Future<String?> Function(String code) onVerify;

  static Future<String?> show({
    required Future<String?> Function(String code) onVerify,
  }) {
    return showGeneralDialog<String>(
      context: Get.context!,
      barrierDismissible: false,
      barrierLabel: 'two_factor',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.base,
      pageBuilder: (context, anim, sec) => TwoFactorDialog(onVerify: onVerify),
      transitionBuilder: (context, anim, sec, child) {
        final scaleAnim = CurvedAnimation(parent: anim, curve: AppMotion.enter);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: scaleAnim.drive(Tween<double>(begin: 0.94, end: 1.0)),
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

  final _ctrl = TextEditingController();
  final _node = FocusNode();
  final _shake = ShakeController();

  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCodeChanged);
    _ctrl.dispose();
    _node.dispose();
    super.dispose();
  }

  String get _code => _ctrl.text;

  void _onCodeChanged() {
    setState(() {
      if (_error != null) _error = null;
    });
    if (_code.length == _length) _verify();
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

    if (value.length != _length) {
      _fail('two_factor.invalid_code'.tr);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onVerify(value);
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22.r),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380.w),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _busy ? null : () => Get.back(),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 32.w,
                        height: 32.w,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20.w,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const _Header(),
                  SizedBox(height: 20.h),
                  ShakeWidget(
                    controller: _shake,
                    child: _CodeField(
                      controller: _ctrl,
                      focusNode: _node,
                      length: _length,
                      hasError: _error != null,
                      onSubmitted: _verify,
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
                  SizedBox(height: 18.h),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
          'two_factor.subtitle'.tr,
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

/// One real (invisible) [TextField] stacked under [length] painted cells. The
/// field owns the text, so typing, backspace, paste and autofill all behave
/// exactly like a normal input; the cells are just a read-only rendering of it.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _Cells(
          controller: controller,
          focusNode: focusNode,
          length: length,
          hasError: hasError,
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              autofillHints: const [AutofillHints.oneTimeCode],
              enableInteractiveSelection: false,
              showCursor: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(length),
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final code = controller.text;
        final cursor = code.length.clamp(0, length - 1);
        return Row(
          children: List.generate(length, (i) {
            final filled = i < code.length;
            final active = focusNode.hasFocus && i == cursor;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: hasError
                            ? scheme.error
                            : (active
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.20)),
                        width: 1.6.w,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filled ? code[i] : '',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
