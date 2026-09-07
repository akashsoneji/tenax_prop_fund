/// The status flavour of a notification row — drives its leading icon + tint.
enum NotificationType { warning, info, success, gift }

/// A single notification row within a date group.
class AppNotification {
  const AppNotification({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.createdAt,
    this.read = false,
  });

  final NotificationType type;
  final String title;
  final String subtitle;

  /// Relative or short timestamp, e.g. '2h', '5h', 'Jul 30'.
  final String time;

  /// Server creation timestamp — used to group rows and derive [time].
  final DateTime createdAt;

  /// True once the notification has been read (`read_at` is non-null).
  final bool read;

  /// Builds a row from the live `/notifications` array element. `read_at` is
  /// null while unread and an ISO string once read; the leading icon flavour is
  /// derived from the `event_key`/`type` prefix (e.g. `security.*`, `order.*`).
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
            DateTime.now();
    final key = '${json['event_key'] ?? json['type'] ?? ''}';
    return AppNotification(
      type: _typeFor(key),
      title: '${json['title'] ?? ''}',
      subtitle: '${json['body'] ?? ''}',
      time: _relativeTime(created),
      createdAt: created,
      read: json['read_at'] != null,
    );
  }

  static NotificationType _typeFor(String eventKey) {
    final prefix = eventKey.split('.').first;
    switch (prefix) {
      case 'security':
        return NotificationType.warning;
      case 'account':
      case 'order':
        return NotificationType.success;
      case 'offer':
      case 'reward':
      case 'referral':
        return NotificationType.gift;
      default:
        return NotificationType.info;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Short timestamp: 'now' / 'Nm' / 'Nh' within a day, else 'MMM d'.
  static String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${_months[when.month - 1]} ${when.day}';
  }
}

/// A date-labelled group of notifications ('Today' / 'Yesterday' / 'Earlier').
class NotificationGroup {
  const NotificationGroup({required this.label, required this.items});

  final String label;
  final List<AppNotification> items;
}
