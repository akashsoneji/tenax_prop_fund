/// The full payload the Support screen needs in one fetch, so the controller
/// holds a single `DataState<SupportData>` instead of several loosely-related
/// Rx lists. The contact card is static UI, so only the fetched [tickets] live
/// here.
class SupportData {
  const SupportData({required this.tickets});

  final List<SupportTicket> tickets;

  bool get isEmpty => tickets.isEmpty;
}

/// Status of a support ticket — drives the trailing pill colour in the list.
enum TicketStatus { open, closed }

/// A single support ticket row shown under "Your tickets".
class SupportTicket {
  const SupportTicket({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final TicketStatus status;
}
