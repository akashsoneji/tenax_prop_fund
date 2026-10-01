import 'package:flutter/material.dart';

/// Overflow-safe text: one line with an ellipsis unless told otherwise.
///
/// Use it for any dynamic text that sits in a `Row` (names, amounts, symbols)
/// so a long value never throws "RenderFlex overflowed". Wrap it in `Expanded`
/// / `Flexible` when it shares the row with other widgets. Pass an already
/// translated string (`'x.y'.tr`) and a style from `AppText`.
class AppLabel extends StatelessWidget {
  const AppLabel(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        softWrap: softWrap,
      );
}
