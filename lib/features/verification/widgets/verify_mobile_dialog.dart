import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_gradient_button.dart';

/// "Verify Mobile Number" dialog from the KYC design: a white card with four
/// OTP cells and a gradient Verify button. Returns the entered code via
/// `Get.back(result:)`, or null when dismissed.
class VerifyMobileDialog extends StatefulWidget {
  const VerifyMobileDialog({super.key, required this.phone, this.verifying});

  final String phone;

  /// Optional reactive flag from the controller to show the button spinner.
  final RxBool? verifying;

  static Future<String?> show({required String phone, RxBool? verifying}) {
    return Get.dialog<String>(
      VerifyMobileDialog(phone: phone, verifying: verifying),
      barrierDismissible: false,
    );
  }

  @override
  State<VerifyMobileDialog> createState() => _VerifyMobileDialogState();
}

class _VerifyMobileDialogState extends State<VerifyMobileDialog> {
  static const _length = 4;
  final _ctrls = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

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

  String get _code => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String value) {
    if (value.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'verification.verify_mobile'.tr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(Icons.cancel_outlined,
                      color: scheme.error, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'verification.otp_body'.trParams({'phone': widget.phone}),
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _length; i++)
                  _OtpCell(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    onChanged: (v) => _onChanged(i, v),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            widget.verifying == null
                ? AppGradientButton(
                    label: 'common.verify'.tr,
                    onPressed:
                        _code.length == _length ? () => Get.back(result: _code) : null,
                  )
                : Obx(
                    () => AppGradientButton(
                      label: 'common.verify'.tr,
                      loading: widget.verifying!.value,
                      onPressed: _code.length == _length
                          ? () => Get.back(result: _code)
                          : null,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 62,
      height: 62,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: false,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: scheme.onSurface.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
