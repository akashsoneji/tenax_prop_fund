import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';

/// Two-column `label: value` grid used by the history, open-position and
/// close/modify details. Each record is `(labelKey, value, labelKey, value)`;
/// labels are translation keys, an empty value renders as `-`.
class TradeDetailGrid extends StatelessWidget {
  const TradeDetailGrid({super.key, required this.rows});

  final List<(String, String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (l1, v1, l2, v2) in rows)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: [
                Expanded(child: _DetailCell(label: l1.tr, value: v1)),
                SizedBox(width: 12.w),
                Expanded(child: _DetailCell(label: l2.tr, value: v2)),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: AppColors.alphaMuted);
    return Row(
      children: [
        Text('$label:', style: AppText.label(color: muted, fontSize: 11.sp)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppText.label(color: scheme.onSurface, fontSize: 11.sp),
          ),
        ),
      ],
    );
  }
}

/// Socket timestamps are ISO-8601 UTC (`2026-11-19T08:24:31Z`); show them in
/// device-local time as `2026.11.19 13:54`. Unparseable input is returned as-is.
String tradeTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('yyyy.MM.dd HH:mm').format(parsed.toLocal());
}

/// Human duration between [from] and [to] (`2d 3h`, `4h 12m`, `9m`), or `-`
/// when [from] can't be parsed.
String tradeDuration(String from, {DateTime? to}) {
  final open = DateTime.tryParse(from);
  if (open == null) return '-';
  final diff = (to ?? DateTime.now()).difference(open);
  if (diff.isNegative) return '-';
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
  if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
  return '${diff.inMinutes}m';
}
