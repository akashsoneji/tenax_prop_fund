import 'package:flutter/material.dart';

/// A small row of page dots. The active dot is filled with the deep brand
/// primary; inactive dots are a faint wash. Used under the stepper card.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 11 : 9,
            height: i == active ? 11 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == active
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}
