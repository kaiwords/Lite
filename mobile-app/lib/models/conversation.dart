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

Conversation? findConversation(String id) {
  try {
    return mockConversations.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

final mockConversations = <Conversation>[
  // ── Social conversations ──────────────────────────────────────────────
  Conversation(
    id: 'u3',
    peerId: 'u3',
    hasUnread: true,
    unreadCount: 2,
    messages: [
      Message(
        text: 'Hey! Just finished reading "Between the Lines" 😭',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      Message(
        text: 'The last stanza made me tear up honestly',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 17)),
      ),
      Message(
        text: 'That means so much, thank you Priya 🙏',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: true,
      ),
      Message(
        text:
            'I wrote it during a really quiet Sunday — everything just poured out',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(minutes: 14)),
        isRead: true,
      ),
      Message(
        text: 'You can really feel that. The pacing is so deliberate',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      Message(
        text: 'Loved your latest poem! The imagery was stunning.',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
  ),
  Conversation(
    id: 'u2',
    peerId: 'u2',
    hasUnread: true,
    unreadCount: 1,
    messages: [
      Message(
        text: 'I\'ve been following your work for months now',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        text:
            'Your voice is so distinct. The way you use white space is incredible',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        text: 'That\'s incredibly kind, I really appreciate it',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        isRead: true,
      ),
      Message(
        text: 'Would you want to collaborate on a collection?',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  ),
  Conversation(
    id: 'u4',
    peerId: 'u4',
    messages: [
      Message(
        text: 'Your comment on my piece yesterday really pushed me',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Message(
        text: 'I rewrote the ending three times because of it',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Message(
        text: 'That\'s exactly what good feedback should do! So glad it helped',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      Message(
        text: 'Thanks for the tip! Means a lot.',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  ),
  Conversation(
    id: 'luna_reads',
    peerId: 'luna_reads',
    messages: [
      Message(
        text: 'I listen to your audio readings when I can\'t sleep',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        text: 'They\'re so calming 🌙',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        text: 'That\'s such a lovely thing to say ✨',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
      ),
      Message(
        text: 'Your audio reading was so peaceful.',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  Conversation(
    id: 'ink_and_fire',
    peerId: 'ink_and_fire',
    messages: [
      Message(
        text: 'My book club is doing a "discover indie writers" month',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      Message(
        text: 'I nominated your article on grief and syntax',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      Message(
        text: 'Wow, that\'s honestly humbling. Thank you so much!',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
        isRead: true,
      ),
      Message(
        text: 'I shared your article with my book club.',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
  ),

  // ── Marketplace conversations (buyer/seller, about a specific listing) ──
  Conversation(
    id: 'sc1',
    peerId: 'u3',
    contextLabel: 'The Glass House',
    hasUnread: true,
    unreadCount: 1,
    messages: [
      Message(
        text: 'Hi! I just ordered The Glass House — can\'t wait!',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Message(
        text: 'Thank you so much Priya, I hope you enjoy it!',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
        isRead: true,
      ),
      Message(
        text: 'Just received it — absolutely beautiful printing!',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ],
  ),
  Conversation(
    id: 'sc2',
    peerId: 'luna_reads',
    contextLabel: 'Echoes in the Dark (Audio)',
    hasUnread: true,
    unreadCount: 1,
    messages: [
      Message(
        text: 'Does the audio include the author\'s commentary?',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  ),
  Conversation(
    id: 'sc3',
    peerId: 'ink_and_fire',
    contextLabel: 'Salt & Smoke',
    messages: [
      Message(
        text: 'When will my order ship?',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        text: 'Shipped this morning! Should arrive in 3–5 days.',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
      ),
      Message(
        text: 'Thanks for the quick shipping!',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  ),
  Conversation(
    id: 'sc4',
    peerId: 'u2',
    contextLabel: 'The Glass House',
    messages: [
      Message(
        text: 'I had a question about the signed edition.',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Message(
        text: 'Of course! All physical copies are signed.',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
        isRead: true,
      ),
      Message(
        text: 'Perfect, I\'ll grab one!',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        text: 'Happy to help — enjoy the read!',
        fromMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
      ),
    ],
  ),
  Conversation(
    id: 'sc5',
    peerId: 'u4',
    contextLabel: 'Between the Lines (E-Book)',
    messages: [
      Message(
        text: 'Is a signed copy available?',
        fromMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
  ),
];
