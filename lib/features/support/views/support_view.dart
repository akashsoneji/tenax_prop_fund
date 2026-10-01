import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/support_controller.dart';
import '../models/support_models.dart';
import '../widgets/open_ticket_sheet.dart';
import '../widgets/support_empty_state.dart';
import '../widgets/support_ticket_row.dart';
import '../widgets/ticket_detail_sheet.dart';
import '../../../shared/widgets/app_card.dart';

/// Full Support screen: the user's ticket list, with a "+" app-bar action that
/// launches the "Open a ticket" bottom sheet. Shows an empty state when the
/// user has no tickets.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<SupportController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(
            title: 'support.title'.tr,
            actions: [
              IconButton(
                onPressed: () => _openSheet(context),
                tooltip: 'support.open_ticket'.tr,
                icon: Icon(
                  Icons.add_rounded,
                  color: AppColors.white,
                  size: 26.w,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Obx(
                () => DataStateBuilder<SupportData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _SupportSkeleton(),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle('support.your_tickets'.tr),
                      10.verticalSpace,
                      _Enter(
                        child: data.tickets.isEmpty
                            ? SupportEmptyState(
                                onOpenTicket: () => _openSheet(context),
                              )
                            : _TicketsCard(tickets: data.tickets),
                      ),
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

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const OpenTicketSheet(),
    );
  }
}

class _TicketsCard extends StatelessWidget {
  const _TicketsCard({required this.tickets});
  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          for (var i = 0; i < tickets.length; i++)
            SupportTicketRow(
              ticket: tickets[i],
              showDivider: i != tickets.length - 1,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.transparent,
                builder: (_) => TicketDetailSheet(ticket: tickets[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton matching the screen's shape.
class _SupportSkeleton extends StatelessWidget {
  const _SupportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShimmerBox(width: 140.w, height: 16.h),
        10.verticalSpace,
        CardSkeleton(lines: 3, height: 140.h),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppText.title(fontSize: 16.sp, color: scheme.onSurface),
    );
  }
}

/// Subtle fade + rise entrance, mirrors rewards_view.dart.
class _Enter extends StatelessWidget {
  const _Enter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18.h),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
