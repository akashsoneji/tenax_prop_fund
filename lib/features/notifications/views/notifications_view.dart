import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_choice_chip.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_models.dart';
import '../widgets/notification_row.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_card.dart';

/// Notifications screen. Rows are grouped under date-section headers, each
/// group rendered as one surface card with divider-separated rows. A
/// "Mark all read" action lives in the app bar and clears the unread flag on
/// [NotificationsController].
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240.h) {
            c.loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            PinnedGradientAppBar(
              title: 'notifications.title'.tr,
              actions: [
                IconButton(
                  onPressed: () => _openPreferences(context, c),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.white,
                    size: 22.w,
                  ),
                  tooltip: 'notifications.preferences'.tr,
                ),
                TextButton(
                  onPressed: c.markAllRead,
                  child: Text(
                    'common.mark_all_read'.tr,
                    style: AppText.base(
                      color: AppColors.white,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
                child: Obx(
                  () => DataStateBuilder<List<NotificationGroup>>(
                    state: c.state,
                    onRetry: c.load,
                    skeleton: const _NotificationsSkeleton(),
                    builder: (groups) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final g in groups) _GroupBlock(group: g)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreferences(BuildContext context, NotificationsController c) {
    c.loadPreferences();
    final scheme = Theme.of(context).colorScheme;
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: 0.82.sh),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'notifications.preferences'.tr,
                        style: AppText.base(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Obx(
                      () => TextButton(
                        onPressed: c.prefsSaving.value
                            ? null
                            : () async {
                                await c.savePreferences();
                                Get.back();
                              },
                        child: c.prefsSaving.value
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'common.save'.tr,
                                style: AppText.base(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Obx(() {
                  if (c.prefsLoading.value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final prefs = c.prefsState.value;
                  if (prefs == null || prefs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: Text(
                        'common.no_data'.tr,
                        style: AppText.base(
                          fontSize: 14.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                    itemCount: prefs.items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 18.h,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (_, i) {
                      final item = prefs.items[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: AppText.base(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            Gap.vXxs,
                            Text(
                              item.description,
                              style: AppText.base(
                                fontSize: 12.sp,
                                height: 1.3,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          Gap.vSm,
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _ChannelChip(
                                label: 'notifications.channel_push'.tr,
                                on: item.broadcast,
                                onChanged: (v) =>
                                    c.togglePref(item.key, broadcast: v),
                              ),
                              _ChannelChip(
                                label: 'notifications.channel_inapp'.tr,
                                on: item.database,
                                onChanged: (v) =>
                                    c.togglePref(item.key, database: v),
                              ),
                              _ChannelChip(
                                label: 'notifications.channel_email'.tr,
                                on: item.mail,
                                onChanged: (v) =>
                                    c.togglePref(item.key, mail: v),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// A small toggleable channel chip used in the preferences sheet.
class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppChoiceChip(
      label: label,
      selected: on,
      onTap: () => onChanged(!on),
      leading: Icon(
        on ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 15.w,
        color: on ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Shimmer skeleton matching the screen's shape: a section header line plus a
/// card of list rows, repeated.
class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShimmerBox(width: 120.w, height: 16.h),
        Gap.vMd,
        CardSkeleton(lines: 3, height: 130.h),
        18.verticalSpace,
        ShimmerBox(width: 120.w, height: 16.h),
        Gap.vMd,
        CardSkeleton(lines: 3, height: 130.h),
      ],
    );
  }
}

/// A date section — its label plus one surface card of divider-separated rows,
/// with the same subtle rise-in entrance used across the app.
class _GroupBlock extends StatelessWidget {
  const _GroupBlock({required this.group});
  final NotificationGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = group.items;
    final c = Get.find<NotificationsController>();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16.h),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
            child: Text(
              group.label.tr,
              style: AppText.base(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          AppCard(
            radius: 18,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
            margin: EdgeInsets.only(bottom: 18.h),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  NotificationRow(
                    notification: items[i],
                    onTap: () => c.markRead(items[i]),
                  ),
                  if (i != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
