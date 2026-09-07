import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        style: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}