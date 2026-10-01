import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_spacing.dart';

/// Card that stacks security rows with hairline dividers between them. Mirrors
/// the theme/language option cards on the same screen.
class SecurityGroup extends StatelessWidget {
  const SecurityGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 56.w,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
      rows.add(children[i]);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: rows),
    );
  }
}

/// Leading tile + title + description, shared by both row kinds below.
class _RowBody extends StatelessWidget {
  const _RowBody({
    required this.icon,
    required this.title,
    required this.description,
    required this.active,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool active;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary.withValues(alpha: 0.16)
                  : scheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    fontSize: 14.sp,
                    color: scheme.onSurface,
                  ),
                ),
                Gap.vXxs,
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    fontSize: 11.sp,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          trailing,
        ],
      ),
    );
  }
}

/// A preference row whose trailing control is a switch.
class SecuritySwitchRow extends StatelessWidget {
  const SecuritySwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowBody(
      icon: icon,
      title: title,
      description: description,
      active: value,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

/// A row that opens a sheet, with an optional state pill on the right.
class SecurityActionRow extends StatelessWidget {
  const SecurityActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailingLabel,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? trailingLabel;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = trailingLabel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _RowBody(
        icon: icon,
        title: title,
        description: description,
        active: highlighted,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (highlighted ? scheme.primary : scheme.onSurface)
                      .withValues(alpha: highlighted ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  label,
                  style: AppText.label(
                    fontSize: 10.sp,
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            6.horizontalSpace,
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
