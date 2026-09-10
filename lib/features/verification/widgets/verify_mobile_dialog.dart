import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
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
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Icon(Icons.cancel_outlined,
                      color: scheme.error, size: 24.w),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              'verification.otp_body'.trParams({'phone': widget.phone}),
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.sp,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 22.h),
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
            SizedBox(height: 22.h),
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
      width: 62.w,
      height: 62.w,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.beVietnamPro(
          fontSize: 24.sp,
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
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                BorderSide(color: scheme.onSurface.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
