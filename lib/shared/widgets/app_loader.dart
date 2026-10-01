import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Lightweight themed loader
/// blocking operation; colors come from the active theme so dark mode
/// works automatically.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            Gap.vMd,
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}