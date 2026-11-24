import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/trade/trade_ticket_panel.dart';
import '../controllers/chart_landscape_controller.dart';
import 'landscape_rail_header.dart';

/// The trade half of the landscape split view: the shared [TradeTicketPanel] in
/// its rail presentation, in a container that animates to zero width when the
/// user collapses it.
///
/// The panel itself is the exact widget the portrait Charts tab docks under the
/// chart — same controls, same live prices, same submit path — so the two
/// orientations can never offer different trading behaviour.
class LandscapeTradeRail extends GetView<ChartLandscapeController> {
  const LandscapeTradeRail({
    super.key,
    required this.symbols,
    required this.width,
  });

  /// Width of the collapse/expand handle that sits on the rail's edge.
  static const toggleWidth = 26.0;

  /// Preferred rail width for a viewport [maxWidth]: the design's 300pt on a
  /// standard phone, clamped so it never eats a small screen or looks lost on
  /// a tablet. Computed from the real viewport instead of ScreenUtil, whose
  /// global design size belongs to the portrait root.
  static double widthFor(double maxWidth) =>
      (maxWidth * 0.37).clamp(260.0, 360.0);

  /// Symbols offered by the rail's symbol picker.
  final List<String> symbols;

  /// Resolved rail width, passed in so the parent and the rail agree exactly.
  final double width;

  /// Symbol picker sized for landscape: capped in height because the viewport
  /// is only ~375pt tall, so a default sheet would cover the whole screen.
  Future<void> _pickSymbol(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: scheme.surface,
      constraints: const BoxConstraints(maxHeight: 240),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: symbols.length,
          itemBuilder: (_, i) {
            final s = symbols[i];
            return ListTile(
              dense: true,
              title: Text(
                s,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: scheme.onSurface),
              ),
              trailing: s == controller.symbol
                  ? Icon(Icons.check, size: 18, color: scheme.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(s),
            );
          },
        ),
      ),
    );
    if (selected != null) controller.selectSymbol(selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          // The free edge is on the RIGHT now that the rail overlays from the
          // left, so that is the edge that needs a border against the chart.
          border: Border(
            right:
                BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Obx(
          () => TradeTicketPanel(
            symbol: controller.symbol,
            layout: TradeTicketLayout.rail,
            onSubmit: controller.submitTicket,
            header: LandscapeRailHeader(
              symbol: controller.symbol,
              onTap: () => _pickSymbol(context),
            ),
          ),
        ),
      ),
    );
  }
}
