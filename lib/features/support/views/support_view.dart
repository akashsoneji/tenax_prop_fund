import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/support_controller.dart';
import '../models/support_models.dart';
import '../widgets/open_ticket_sheet.dart';
import '../widgets/support_contact_card.dart';
import '../widgets/support_ticket_row.dart';

/// Full Support screen. Composed of:
///
///  * Purple gradient contact card with a 2x2 grid (WhatsApp / Email / FAQ /
///    Rules).
///  * "Your tickets" surface card listing ticket rows.
///  * An outlined "Open a ticket" button that launches the bottom sheet.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<SupportController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'support.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Obx(
                () => DataStateBuilder<SupportData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _SupportSkeleton(),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Enter(child: SupportContactCard()),
                      const SizedBox(height: 26),
                      const _SectionTitle('Your tickets'),
                      const SizedBox(height: 10),
                      _Enter(delay: 0.15, child: _TicketsCard(data: data)),
                      const SizedBox(height: 18),
                      _Enter(
                        delay: 0.25,
                        child: OutlinedButton(
                          onPressed: () => _openSheet(context),
                          child: Text('support.open_ticket'.tr),
                        ),
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
  const _TicketsCard({required this.data});
  final SupportData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = data.tickets;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            SupportTicketRow(
              ticket: rows[i],
              showDivider: i != rows.length - 1,
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
      children: const [
        HeroSkeleton(height: 200),
        SizedBox(height: 26),
        ShimmerBox(width: 140, height: 16),
        SizedBox(height: 10),
        CardSkeleton(lines: 3, height: 140),
        SizedBox(height: 18),
        ShimmerBox(height: 48, radius: 14),
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
      style: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    );
  }
}

/// Subtle fade + rise entrance, mirrors rewards_view.dart.
class _Enter extends StatelessWidget {
  const _Enter({required this.child, this.delay = 0.0});
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Interval(delay, 1.0, curve: AppMotion.enter),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
