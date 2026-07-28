import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../services/conversations_repository.dart';

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  ConversationsNotifier(super.initial);

  Future<void> loadFromSupabase() async {
    try {
      final remote = await ConversationsRepository.fetchAll();
      if (remote.isNotEmpty) state = remote;
    } catch (_) {
      // Offline or request failed — keep the mock conversations already shown.
    }
  }

  Conversation? find(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Sends a message in conversation [id], creating the conversation first
  /// (with [peerId] as the peer) if this is a brand-new thread. The message
  /// stays visible locally either way; the returned bool reports whether it
  /// also synced, so the UI can tell the user when it didn't.
  Future<bool> sendMessage(
    String id, {
    required String text,
    required String peerId,
    String? contextLabel,
  }) async {
    final message = Message(text: text, fromMe: true, sentAt: DateTime.now());
    final existing = find(id);
    state = existing == null
        ? [
            Conversation(
              id: id,
              peerId: peerId,
              messages: [message],
              contextLabel: contextLabel,
            ),
            ...state,
          ]
        : [
            for (final c in state)
              if (c.id == id) _appendMessage(c, message) else c,
          ];

    try {
      await ConversationsRepository.ensureConversation(
        id: id,
        peerId: peerId,
        contextLabel: contextLabel,
      );
      await ConversationsRepository.insertMessage(id, text: text, fromMe: true);
      return true;
    } catch (_) {
      // Offline — message stays visible locally but won't sync until next load.
      return false;
    }
  }

  Conversation _appendMessage(Conversation c, Message m) => Conversation(
        id: c.id,
        peerId: c.peerId,
        messages: [...c.messages, m],
        hasUnread: c.hasUnread,
        unreadCount: c.unreadCount,
        contextLabel: c.contextLabel,
      );
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  final notifier = ConversationsNotifier(List<Conversation>.from(mockConversations));
  notifier.loadFromSupabase();
  return notifier;
});
