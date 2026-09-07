import 'package:flutter/material.dart';

/// Bottom-sheet notifications panel opened from the floating trade ticket.
/// Spans the full device width. Intentionally blank for now — the
/// notifications list will be built here.
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 320,
        ),
      ),
    );
  }
}
