import 'package:flutter/material.dart';

import '../../../shared/theme/app_text.dart';

/// Small section label used between blocks (e.g. "Requests").
class RewardsSectionTitle extends StatelessWidget {
  const RewardsSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text,
        style: AppText.heading(fontSize: 18, color: scheme.onSurface),
      ),
    );
  }
}