import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Standard confirmation dialog: title + ✕, divider, message, divider, then
/// Cancel / confirm actions on a tinted footer (mirrors the web modal).
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
  });

  final String title;

  /// Rich text so callers can bold the subject (e.g. the method name).
  final InlineSpan message;
  final String confirmLabel;
  final String? cancelLabel;

  /// Red confirm button for irreversible / removing actions.
  final bool destructive;

  static Future<bool> show({
    required String title,
    required InlineSpan message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final divider = Divider(height: 1.h, thickness: 1, color: scheme.outlineVariant);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 8.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(result: false),
                  icon: Icon(Icons.close_rounded,
                      size: 20.w, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          divider,
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Text.rich(
              message,
              style: text.bodyMedium?.copyWith(
                fontSize: 14.sp,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          divider,
          Container(
            color: scheme.surfaceContainerLow,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(44.h),
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: scheme.outlineVariant),
                      textStyle: text.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(cancelLabel ?? 'common.cancel'.tr),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Get.back(result: true),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(44.h),
                      backgroundColor:
                          destructive ? scheme.error : scheme.primary,
                      foregroundColor:
                          destructive ? scheme.onError : scheme.onPrimary,
                      textStyle: text.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
