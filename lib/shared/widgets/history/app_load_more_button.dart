import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_text.dart';

/// "Load more" link under a paginated list. Shows [loadingLabel] and is
/// disabled while the next page is loading.
class AppLoadMoreButton extends StatelessWidget {
  const AppLoadMoreButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
  });

  /// Already translated (e.g. `'rewards.load_more'.tr`).
  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: loading ? null : onPressed,
      child: Text(
        loading ? loadingLabel : label,
        style: AppText.base(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
