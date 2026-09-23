import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../authentication/repositories/auth_repository.dart';

/// Password-confirmation dialog for account deletion.
///
/// The delete API is not wired yet, so on submit the session is cleared and the
/// user is returned to login — the same terminal state the real call produces.
Future<void> showDeleteAccountDialog() async {
  await Get.dialog<void>(const _DeleteAccountDialog(), barrierDismissible: false);
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
    return AlertDialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      contentPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
      title: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.delete_forever_rounded,
                size: 20.w, color: AppColors.danger),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'more.delete_account'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(fontSize: 16.sp, color: scheme.onSurface),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'more.delete_account_warning'.tr,
              style: AppText.body(
                fontSize: 13.sp,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 16.h),
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
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: AppText.label(
                    fontSize: 12.sp, color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Get.back<void>(),
          child: Text('common.cancel'.tr),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'common.submit'.tr,
                  style: AppText.subtitle(
                      fontSize: 14.sp, color: AppColors.danger),
                ),
        ),
      ],
    );
  }
}
