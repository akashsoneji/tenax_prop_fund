import 'package:flutter/material.dart';

import '../../../shared/widgets/app_bottom_sheet.dart';

/// The security bottom sheets: the standard [AppBottomSheet] with a title,
/// subtitle and a taller floor so the form fills the space above the keyboard.
class SecuritySheetScaffold extends StatelessWidget {
  const SecuritySheetScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: title,
    subtitle: subtitle,
    minHeightFactor: 0.6,
    children: children,
  );
}

/// Opens [child] as the app's standard security sheet.
Future<T?> showSecuritySheet<T>(Widget child) => AppBottomSheet.show<T>(child);
