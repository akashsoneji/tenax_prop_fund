/// Tracks which topics are currently subscribed so the manager can resubscribe
/// them all after a reconnect. Ref-counts topics so overlapping screens don't
/// unsubscribe a stream another screen still needs.
class SubscriptionManager {
  final Map<String, int> _refCounts = {};

  Set<String> get activeTopics => _refCounts.keys.toSet();

  /// Returns true if this is the first subscriber for [topic] (caller should
  /// send the subscribe frame).
  bool add(String topic) {
    final count = _refCounts[topic] ?? 0;
    _refCounts[topic] = count + 1;
    return count == 0;
  }

  /// Returns true if this was the last subscriber (caller should send the
  /// unsubscribe frame).
  bool remove(String topic) {
    final count = _refCounts[topic] ?? 0;
    if (count <= 1) {
      _refCounts.remove(topic);
      return count == 1;
    }
    _refCounts[topic] = count - 1;
    return false;
  }

  void clear() => _refCounts.clear();
}
