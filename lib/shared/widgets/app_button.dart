import 'package:flutter/material.dart';

import 'app_gradient_button.dart';

/// Backwards-compatible alias so old call sites that used `AppButton` still
/// render the shared brand CTA (gradient purple → magenta, white text).
/// New code should import `AppGradientButton` directly.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => AppGradientButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
        icon: icon,
      );
}
