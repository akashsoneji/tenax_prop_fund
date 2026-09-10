import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Two-column responsive grid
/// for the rewards stats block where the four tiles should fade-in one after
/// the other rather than all at once.
class StaggeredGrid extends StatelessWidget {
  const StaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.staggerMs = 90,
  });

  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// Delay (ms) added per child. Index 0 enters immediately.
  final int staggerMs;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final first = children[i];
      final second = i + 1 < children.length ? children[i + 1] : const SizedBox.shrink();
      rows.add(Row(
        children: [
          Expanded(child: first),
          SizedBox(width: crossAxisSpacing.w),
          Expanded(child: second),
        ],
      ));
      if (i + 2 < children.length) rows.add(SizedBox(height: mainAxisSpacing.h));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
