import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_models.dart';
import '../widgets/notification_row.dart';

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(
            title: 'notifications.title'.tr,
            actions: [
              TextButton(
                onPressed: c.markAllRead,
                child: Text(
                  'common.mark_all_read'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Obx(
                () => DataStateBuilder<List<NotificationGroup>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _NotificationsSkeleton(),
                  builder: (groups) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final g in groups) _GroupBlock(group: g),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
      children: const [
        ShimmerBox(width: 120, height: 16),
        SizedBox(height: 12),
        CardSkeleton(lines: 3, height: 130),
        SizedBox(height: 18),
        ShimmerBox(width: 120, height: 16),
        SizedBox(height: 12),
        CardSkeleton(lines: 3, height: 130),
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              group.label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: AppTheme.surfaceCard(scheme, radius: 18),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  NotificationRow(notification: items[i]),
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
