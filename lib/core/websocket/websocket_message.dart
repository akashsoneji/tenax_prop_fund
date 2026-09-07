enum WsConnectionState { disconnected, connecting, connected, reconnecting }

/// A parsed inbound message: [topic] identifies the stream (e.g. a symbol),
/// [data] is the decoded payload.
class WsMessage {
  final String topic;
  final Map<String, dynamic> data;

  const WsMessage({required this.topic, required this.data});
}
