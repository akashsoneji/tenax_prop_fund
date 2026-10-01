import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../../../shared/theme/app_spacing.dart';

/// Password-confirmation dialog for account deletion.
///
/// The delete API is not wired yet, so on submit the session is cleared and the
/// user is returned to login — the same terminal state the real call produces.
Future<void> showDeleteAccountDialog() async {
  await Get.dialog<void>(
    const _DeleteAccountDialog(),
    barrierDismissible: false,
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_password.text.trim().isEmpty) {
      setState(() => _error = 'more.delete_account_password_required'.tr);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    await Get.find<AuthRepository>().logout();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppDialogFrame(
      title: 'more.delete_account'.tr,
      icon: Icons.delete_forever_rounded,
      destructive: true,
      message: Text(
        'more.delete_account_warning'.tr,
        textAlign: TextAlign.center,
        style: AppText.body(
          fontSize: 13.5.sp,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
      actions: AppDialogActions(
        confirmLabel: 'more.delete_account'.tr,
        destructive: true,
        loading: _submitting,
        onCancel: () => Get.back<void>(),
        onConfirm: _submit,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _password,
            label: 'more.delete_account_password'.tr,
            hint: 'more.delete_account_password'.tr,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20.w,
              ),
            ),
          ),
          if (_error != null) ...[
            Gap.vSm,
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14.w,
                  color: scheme.error,
                ),
                6.horizontalSpace,
                Expanded(
                  child: Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(fontSize: 12.sp, color: scheme.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
