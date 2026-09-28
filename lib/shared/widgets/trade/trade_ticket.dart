/// Value types shared by every surface that hosts the trade ticket
/// (`TradeTicketPanel`): the portrait Charts tab, the landscape split view, and
/// anything added later. Kept separate from the widget so a caller can type an
/// `onSubmit` callback without importing the whole panel.
library;

/// Immutable snapshot of what the user configured before hitting Buy/Sell.
class TradeTicket {
  const TradeTicket({
    required this.symbol,
    required this.side,
    required this.volume,
    this.takeProfit,
    this.stopLoss,
  });

  final String symbol;
  final TradeSide side;
  final double volume;

  /// Optional TP/SL prices; null when the TP/SL toggle is off or left unset.
  final double? takeProfit;
  final double? stopLoss;
}

enum TradeSide { buy, sell }

/// How the ticket is presented. This is PURELY visual — padding, which edge
/// carries the divider, and the height of the Buy/Sell buttons. The controls,
/// state and submit behaviour are identical for both, so no caller ever needs a
/// second ticket widget or a second controller.
enum TradeTicketLayout {
  /// Docked under the chart in portrait, divider along the top edge.
  docked,

  /// Vertical rail beside the chart in landscape, divider along the left edge
  /// and slightly tighter vertically because the viewport is only ~375pt tall.
  rail,
}
