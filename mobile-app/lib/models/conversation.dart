import 'user.dart';

/// A single chat message within a [Conversation].
class Message {
  final String text;
  final bool fromMe;
  final DateTime sentAt;
  final bool isRead;

  const Message({
    required this.text,
    required this.fromMe,
    required this.sentAt,
    this.isRead = false,
  });
}

/// A single 1:1 message thread, shared by the social messaging stack
/// (`/messages`) and the marketplace messaging stack (`/marketplace/messages`).
///
/// Most conversations are plain social threads (`contextLabel == null`).
/// A thread that originated from a marketplace listing/order instead carries
/// [contextLabel] (the listing title), which the shared UI renders as an
/// "About: `listing`" tag — this is the only real difference between the two
/// entry points, so it doesn't warrant a second parallel model/UI stack.
class Conversation {
  final String id;
  // peerId is the LitUser.id for real mock users, or the display name itself
  // for demo-only peers ('luna_reads', 'ink_and_fire') that have no backing
  // LitUser record.
  final String peerId;
  final List<Message> messages;
  final bool hasUnread;
  final int unreadCount;
  final String? contextLabel;

  const Conversation({
    required this.id,
    required this.peerId,
    required this.messages,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.contextLabel,
  });

  String get peerName => findUser(peerId)?.displayName ?? peerId;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;
}

/// Formats a timestamp as a short relative label for conversation list rows,
/// e.g. '2m', '1h', 'Yesterday', '2d'.
String formatConversationTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays}d';
}

