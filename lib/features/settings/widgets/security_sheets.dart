import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/security_controller.dart';
import '../models/security_models.dart';
import 'security_sheet_scaffold.dart';

void showChangePasswordSheet() =>
    showSecuritySheet(const _ChangePasswordSheet());

void showBeneficiarySheet() => showSecuritySheet(const _BeneficiarySheet());

void showTwoFactorDisableSheet() =>
    showSecuritySheet(const _TwoFactorDisableSheet());

void showRecoveryCodesSheet() => showSecuritySheet(const _RecoveryCodesSheet());

/// Starts enrolment first — the sheet needs the server's secret/QR before it
/// has anything to show, so a failed enrol never opens an empty sheet.
Future<void> showTwoFactorEnrolSheet() async {
  final enrolment =
      await Get.find<SecurityController>().startTwoFactorEnrolment();
  if (enrolment == null) return;
  await showSecuritySheet(_TwoFactorEnrolSheet(enrolment: enrolment));
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _c = Get.find<SecurityController>();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _next.text.isEmpty) {
      AppToast.error('settings.security.fill_all_fields'.tr);
      return;
    }
    if (_next.text != _confirm.text) {
      AppToast.error('settings.security.password_mismatch'.tr);
      return;
    }
    final ok = await _c.changePassword(
      currentPassword: _current.text,
      password: _next.text,
      passwordConfirmation: _confirm.text,
    );
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return SecuritySheetScaffold(
      title: 'settings.security.change_password'.tr,
      subtitle: 'settings.security.change_password_sheet_desc'.tr,
      children: [
        AppTextField(
          controller: _current,
          label: 'settings.security.current_password'.tr,
          obscureText: true,
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _next,
          label: 'settings.security.new_password'.tr,
          obscureText: true,
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _confirm,
          label: 'settings.security.confirm_password'.tr,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => AppGradientButton(
            label: 'settings.security.update_password'.tr,
            loading: _c.savingPassword.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _BeneficiarySheet extends StatefulWidget {
  const _BeneficiarySheet();

  @override
  State<_BeneficiarySheet> createState() => _BeneficiarySheetState();
}

class _BeneficiarySheetState extends State<_BeneficiarySheet> {
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _c = Get.find<SecurityController>();

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty || _email.text.isEmpty) {
      AppToast.error('settings.security.fill_all_fields'.tr);
      return;
    }
    final ok = await _c.saveBeneficiary(
      fullName: _name.text.trim(),
      relationship: _relationship.text.trim(),
      email: _email.text.trim(),
      mobile: _mobile.text.trim(),
    );
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return SecuritySheetScaffold(
      title: 'settings.security.beneficiary'.tr,
      subtitle: 'settings.security.beneficiary_sheet_desc'.tr,
      children: [
        AppTextField(
          controller: _name,
          label: 'settings.security.full_name'.tr,
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _relationship,
          label: 'settings.security.relationship'.tr,
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _email,
          label: 'settings.security.email'.tr,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 12.h),
        AppTextField(
          controller: _mobile,
          label: 'settings.security.mobile'.tr,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => AppGradientButton(
            label: 'settings.security.save'.tr,
            loading: _c.savingBeneficiary.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _TwoFactorEnrolSheet extends StatefulWidget {
  const _TwoFactorEnrolSheet({required this.enrolment});

  final TwoFactorEnrolment enrolment;

  @override
  State<_TwoFactorEnrolSheet> createState() => _TwoFactorEnrolSheetState();
}

class _TwoFactorEnrolSheetState extends State<_TwoFactorEnrolSheet> {
  final _code = TextEditingController();
  final _c = Get.find<SecurityController>();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().length < 6) {
      AppToast.error('settings.security.enter_code'.tr);
      return;
    }
    final ok = await _c.confirmTwoFactor(
      secret: widget.enrolment.secret,
      code: _code.text.trim(),
    );
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return SecuritySheetScaffold(
      title: 'settings.security.enable_two_factor'.tr,
      subtitle: 'settings.security.enrol_sheet_desc'.tr,
      children: [
        _QrCard(data: widget.enrolment.otpauthUri),
        SizedBox(height: 12.h),
        _CopyField(
          label: 'settings.security.secret_key'.tr,
          value: widget.enrolment.secret,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          controller: _code,
          label: 'settings.security.auth_code'.tr,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => AppGradientButton(
            label: 'settings.security.confirm_enable'.tr,
            loading: _c.confirming2fa.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _TwoFactorDisableSheet extends StatefulWidget {
  const _TwoFactorDisableSheet();

  @override
  State<_TwoFactorDisableSheet> createState() => _TwoFactorDisableSheetState();
}

class _TwoFactorDisableSheetState extends State<_TwoFactorDisableSheet> {
  final _password = TextEditingController();
  final _c = Get.find<SecurityController>();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      AppToast.error('settings.security.fill_all_fields'.tr);
      return;
    }
    final ok = await _c.disableTwoFactor(_password.text);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return SecuritySheetScaffold(
      title: 'settings.security.disable_two_factor'.tr,
      subtitle: 'settings.security.disable_sheet_desc'.tr,
      children: [
        AppTextField(
          controller: _password,
          label: 'settings.security.current_password'.tr,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => AppGradientButton(
            label: 'settings.security.turn_off'.tr,
            loading: _c.disabling2fa.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _RecoveryCodesSheet extends StatefulWidget {
  const _RecoveryCodesSheet();

  @override
  State<_RecoveryCodesSheet> createState() => _RecoveryCodesSheetState();
}

class _RecoveryCodesSheetState extends State<_RecoveryCodesSheet> {
  final _password = TextEditingController();
  final _c = Get.find<SecurityController>();
  List<String> _codes = const [];

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      AppToast.error('settings.security.fill_all_fields'.tr);
      return;
    }
    final codes = await _c.recoveryCodes(_password.text);
    if (codes == null || !mounted) return;
    setState(() => _codes = codes);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_codes.isNotEmpty) {
      return SecuritySheetScaffold(
        title: 'settings.security.recovery_codes'.tr,
        subtitle: 'settings.security.recovery_codes_warning'.tr,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final code in _codes)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        fontSize: 13.sp,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          AppGradientButton(
            label: 'settings.security.copy_codes'.tr,
            icon: Icons.copy_rounded,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _codes.join('\n')));
              AppToast.success('settings.security.copied'.tr);
            },
          ),
        ],
      );
    }

    return SecuritySheetScaffold(
      title: 'settings.security.recovery_codes'.tr,
      subtitle: 'settings.security.recovery_sheet_desc'.tr,
      children: [
        AppTextField(
          controller: _password,
          label: 'settings.security.current_password'.tr,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: 20.h),
        Obx(
          () => AppGradientButton(
            label: 'settings.security.show_codes'.tr,
            loading: _c.loadingRecoveryCodes.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

/// The `otpauth://` URI as a scannable QR. Kept on a white plate in both themes
/// because scanners need the light-on-dark contrast the spec assumes.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: QrImageView(
            data: data,
            size: 180.w,
            version: QrVersions.auto,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: EdgeInsets.all(8.w),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'settings.security.scan_hint'.tr,
          textAlign: TextAlign.center,
          style: AppText.label(
            fontSize: 11.sp,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// A read-only value with a copy button — used for the 2FA secret so the user
/// can enrol by hand when scanning is not an option.
class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    fontSize: 10.sp,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    fontSize: 12.sp,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              AppToast.success('settings.security.copied'.tr);
            },
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.copy_rounded,
              size: 18.sp,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
