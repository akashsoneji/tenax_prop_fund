/// The full payload the Support screen needs in one fetch, so the controller
/// holds a single `DataState<SupportData>` instead of several loosely-related
/// Rx lists. The contact card is static UI; the fetched [topics] feed the
/// "Open a ticket" form and [tickets] populate the list.
class SupportData {
  const SupportData({required this.topics, required this.tickets});

  final List<SupportTopic> topics;
  final List<SupportTicket> tickets;

  bool get isEmpty => tickets.isEmpty;
}

/// A ticket topic option `{value, label}` for the "Open a ticket" dropdown.
class SupportTopic {
  const SupportTopic({required this.value, required this.label});

  final String value;
  final String label;

  factory SupportTopic.fromJson(Map<String, dynamic> json) => SupportTopic(
        value: '${json['value'] ?? ''}',
        label: '${json['label'] ?? json['value'] ?? ''}',
      );
}

/// Status of a support ticket — drives the trailing pill colour in the list.
enum TicketStatus { open, inProgress, closed }

/// A single support ticket shown under "Your tickets".
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ref,
    required this.subject,
    required this.topic,
    required this.topicLabel,
    required this.status,
    required this.statusLabel,
    required this.opened,
    required this.lastReply,
    this.messages = const [],
  });

  final int id;
  final String ref;
  final String subject;
  final String topic;
  final String topicLabel;
  final TicketStatus status;
  final String statusLabel;
  final DateTime? opened;
  final DateTime? lastReply;
  final List<TicketMessage> messages;

  /// Title shown in the list row.
  String get title => subject;

  /// Muted subtitle: "#REF · Topic · MMM d".
  String get subtitle {
    final parts = <String>[
      if (ref.isNotEmpty) ref,
      if (topicLabel.isNotEmpty) topicLabel,
      if (opened != null) _shortDate(opened!),
    ];
    return parts.join(' · ');
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';

  static TicketStatus _statusFrom(String raw) {
    switch (raw) {
      case 'closed':
        return TicketStatus.closed;
      case 'in_progress':
        return TicketStatus.inProgress;
      default:
        return TicketStatus.open;
    }
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List?) ?? const [];
    return SupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ref: '${json['ref'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      topic: '${json['topic'] ?? ''}',
      topicLabel: '${json['topic_label'] ?? ''}',
      status: _statusFrom('${json['status'] ?? 'open'}'),
      statusLabel: '${json['status_label'] ?? ''}',
      opened: DateTime.tryParse('${json['opened'] ?? ''}')?.toLocal(),
      lastReply: DateTime.tryParse('${json['last_reply'] ?? ''}')?.toLocal(),
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(TicketMessage.fromJson)
          .toList(),
    );
  }
}

/// One message in a ticket thread.
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.body,
    required this.isStaff,
    required this.author,
    required this.createdAt,
  });

  final int id;
  final String body;
  final bool isStaff;
  final String author;
  final DateTime? createdAt;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        body: '${json['body'] ?? ''}',
        isStaff: json['is_staff'] as bool? ?? false,
        author: '${json['author'] ?? ''}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
      );
}
