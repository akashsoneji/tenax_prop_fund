import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import 'animated_field.dart';
import 'glass_card.dart';

/// 6-cell OTP entry. Each cell accepts one digit; auto-advances focus on
/// input, backspace moves focus back, paste from SMS is auto-split.
/// On submit, returns the full code via `Get.back(result:)` or null on cancel.
class OtpDialog extends StatefulWidget {
  const OtpDialog({super.key, required this.target});

  final String target;

  static Future<String?> show({required String target}) {
    return showGeneralDialog<String>(
      context: Get.context!,
      barrierDismissible: false,
      barrierLabel: 'otp',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.base,
      pageBuilder: (context, anim, sec) => OtpDialog(target: target),
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

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
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

  void _verify() {
    final value = _code;
    if (value.length != _length || int.tryParse(value) == null) {
      setState(() => _error = 'otp.invalid_code'.tr);
      _shake.shake();
      HapticFeedback.mediumImpact();
      return;
    }
    Get.back(result: value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: AppColors.transparent,
        child: GlassCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'otp.title'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${'otp.subtitle'.tr}\n${widget.target}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ShakeWidget(
                  controller: _shake,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_length, (i) {
                      return _PinCell(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        onChanged: (v) => _onChanged(i, v),
                        onBackspace: () => _onBackspace(i),
                        hasError: _error != null,
                        onSubmitted: i == _length - 1 ? _verify : null,
                      );
                    }),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('common.cancel'.tr),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _verify,
                      child: Text('common.verify'.tr),
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
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError
              ? scheme.error
              : (focusNode.hasFocus ? scheme.primary : AppColors.transparent),
          width: 1.6,
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}