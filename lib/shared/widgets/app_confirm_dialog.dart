import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_text.dart';
import 'app_gradient_button.dart';

/// Standard confirmation dialog: tinted icon badge, centered title + message,
/// then Cancel / confirm pill buttons.
///
/// Returns `true` when confirmed, `false`/`null` otherwise:
/// ```dart
/// final ok = await AppConfirmDialog.show(
///   title: 'Remove payout method',
///   message: TextSpan(text: 'Remove Test r?'),
///   confirmLabel: 'Remove',
///   destructive: true,
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.destructive = false,
    this.icon,
  });

  final String title;

  /// Rich text so callers can bold the subject (e.g. the method name).
  final InlineSpan message;
  final String confirmLabel;
  final String? cancelLabel;

  /// Red confirm button for irreversible / removing actions.
  final bool destructive;

  /// Badge icon; defaults to a warning (destructive) or help glyph.
  final IconData? icon;

  static Future<bool> show({
    required String title,
    required InlineSpan message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await Get.dialog<bool>(
      AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppDialogFrame(
      title: title,
      icon: icon ??
          (destructive
              ? Icons.warning_amber_rounded
              : Icons.help_outline_rounded),
      destructive: destructive,
      message: Text.rich(
        message,
        textAlign: TextAlign.center,
        style: AppText.body(
          fontSize: 13.5.sp,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
      actions: AppDialogActions(
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onCancel: () => Get.back(result: false),
        onConfirm: () => Get.back(result: true),
      ),
    );
  }
}

/// Shared modal card: icon badge, centered title, message, optional extra
/// content (e.g. a form field) and the action row. Scrolls when the keyboard
/// squeezes it.
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.actions,
    this.message,
    this.child,
    this.destructive = false,
  });

  final String title;
  final IconData icon;
  final Widget actions;
  final Widget? message;
  final Widget? child;

  /// Tints the badge with the error color instead of primary.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = destructive ? scheme.error : scheme.primary;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _IconBadge(icon: icon, tone: tone)),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(fontSize: 18.sp, color: scheme.onSurface),
            ),
            if (message != null) ...[
              SizedBox(height: 8.h),
              message!,
            ],
            if (child != null) ...[
              SizedBox(height: 18.h),
              child!,
            ],
            SizedBox(height: 22.h),
            actions,
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.w,
      height: 64.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24.w, color: tone),
      ),
    );
  }
}

/// Cancel (soft tonal) + confirm pill buttons for [AppDialogFrame]. The
/// confirm uses the brand [AppGradientButton], or a solid error button when
/// [destructive]. [loading] disables both and spins the confirm button.
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel,
    this.destructive = false,
    this.loading = false,
  });

  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? cancelLabel;
  final bool destructive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = 46.h;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14.r),
    );
    final labelStyle = AppText.subtitle(fontSize: 14.sp);

    final cancel = TextButton(
      onPressed: loading ? null : onCancel,
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
        foregroundColor: scheme.onSurface,
        textStyle: labelStyle,
        shape: shape,
      ),
      child: Text(
        cancelLabel ?? 'common.cancel'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final Widget confirm = destructive
        ? FilledButton(
            onPressed: loading ? null : onConfirm,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(height),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              disabledBackgroundColor: scheme.error.withValues(alpha: 0.7),
              disabledForegroundColor: scheme.onError,
              elevation: 0,
              textStyle: labelStyle,
              shape: shape,
            ),
            child: loading
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onError,
                    ),
                  )
                : Text(
                    confirmLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          )
        : AppGradientButton(
            label: confirmLabel,
            height: height,
            loading: loading,
            onPressed: onConfirm,
          );

    return Row(
      children: [
        Expanded(child: cancel),
        SizedBox(width: 10.w),
        Expanded(child: confirm),
      ],
    );
  }
}
