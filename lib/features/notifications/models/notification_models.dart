/// The status flavour of a notification row — drives its leading icon + tint.
enum NotificationType { warning, info, success, gift }

/// A single notification row within a date group.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;

  /// Relative or short timestamp, e.g. '2h', '5h', 'Jul 30'.
  final String time;

  /// Server creation timestamp — used to group rows and derive [time].
  final DateTime createdAt;

  /// True once the notification has been read (`read_at` is non-null).
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        subtitle: subtitle,
        time: time,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  /// Builds a row from the live `/notifications` array element. `read_at` is
  /// null while unread and an ISO string once read; the leading icon flavour is
  /// derived from the `event_key`/`type` prefix (e.g. `security.*`, `order.*`).
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
            DateTime.now();
    final key = '${json['event_key'] ?? json['type'] ?? ''}';
    return AppNotification(
      id: '${json['id'] ?? ''}',
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
      case 'challenge':
        // Breaches/near-limit are cautionary; treat as warning.
        return NotificationType.warning;
      case 'account':
      case 'order':
      case 'payment':
      case 'payout':
        return NotificationType.success;
      case 'offer':
      case 'reward':
      case 'referral':
      case 'trial':
      case 'growth':
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

  /// Buckets a flat, newest-first notification list into 'Today' / 'Yesterday' /
  /// 'Earlier' sections, preserving order and dropping empty sections.
  static List<NotificationGroup> group(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlierItems = <AppNotification>[];

    for (final n in items) {
      final day = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      if (day == today) {
        todayItems.add(n);
      } else if (day == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty)
        NotificationGroup(label: 'Today', items: todayItems),
      if (yesterdayItems.isNotEmpty)
        NotificationGroup(label: 'Yesterday', items: yesterdayItems),
      if (earlierItems.isNotEmpty)
        NotificationGroup(label: 'Earlier', items: earlierItems),
    ];
  }
}

/// One catalog entry describing a notification channel preference group.
class NotificationPrefItem {
  const NotificationPrefItem({
    required this.key,
    required this.label,
    required this.description,
    required this.database,
    required this.broadcast,
    required this.mail,
  });

  final String key;
  final String label;
  final String description;
  final bool database;
  final bool broadcast;
  final bool mail;

  NotificationPrefItem copyWith({
    bool? database,
    bool? broadcast,
    bool? mail,
  }) =>
      NotificationPrefItem(
        key: key,
        label: label,
        description: description,
        database: database ?? this.database,
        broadcast: broadcast ?? this.broadcast,
        mail: mail ?? this.mail,
      );
}

/// The `/notifications/preferences` payload: a catalog joined to its current
/// per-channel toggles.
class NotificationPreferences {
  const NotificationPreferences({required this.items});

  final List<NotificationPrefItem> items;

  bool get isEmpty => items.isEmpty;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final catalog = (json['catalog'] as List?) ?? const [];
    final prefs = (json['preferences'] as Map?) ?? const {};
    final items = <NotificationPrefItem>[];
    for (final raw in catalog) {
      if (raw is! Map) continue;
      final key = '${raw['key'] ?? ''}';
      final channels = prefs[key];
      final chan = channels is Map ? channels : const {};
      items.add(
        NotificationPrefItem(
          key: key,
          label: '${raw['label'] ?? key}',
          description: '${raw['description'] ?? ''}',
          database: chan['database'] as bool? ?? true,
          broadcast: chan['broadcast'] as bool? ?? true,
          mail: chan['mail'] as bool? ?? true,
        ),
      );
    }
    return NotificationPreferences(items: items);
  }

  /// Serialises back to the `{key: {database, broadcast, mail}}` map the `PUT`
  /// endpoint expects.
  Map<String, dynamic> toPreferencesMap() => {
        for (final i in items)
          i.key: {
            'database': i.database,
            'broadcast': i.broadcast,
            'mail': i.mail,
          },
      };
}
