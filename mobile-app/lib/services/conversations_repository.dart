import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import 'supabase_service.dart';

/// Reads and writes `conversations`/`messages` rows in Supabase.
class ConversationsRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Conversation>> fetchAll() async {
    final rows = await _client.from('conversations').select('*, messages(*)');
    return (rows as List)
        .map((r) => _conversationFromRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Creates the conversation row if it doesn't already exist. A no-op when
  /// it does, so this is safe to call before every message send.
  static Future<void> ensureConversation({
    required String id,
    required String peerId,
    String? contextLabel,
  }) =>
      _client.from('conversations').upsert(
        {
          'id': id,
          'peer_id': peerId,
          'context_label': contextLabel,
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );

  static Future<void> insertMessage(
    String conversationId, {
    required String text,
    required bool fromMe,
  }) =>
      _client.from('messages').insert({
        'conversation_id': conversationId,
        'text': text,
        'from_me': fromMe,
        'is_read': false,
      });

  static Conversation _conversationFromRow(Map<String, dynamic> row) {
    final messageRows = ((row['messages'] as List?) ?? const [])
        .map((m) => (m as Map).cast<String, dynamic>())
        .toList()
      ..sort((a, b) =>
          (a['sent_at'] as String).compareTo(b['sent_at'] as String));

    return Conversation(
      id: row['id'] as String,
      peerId: row['peer_id'] as String,
      contextLabel: row['context_label'] as String?,
      hasUnread: (row['has_unread'] as bool?) ?? false,
      unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
      messages: messageRows
          .map((m) => Message(
                text: m['text'] as String,
                fromMe: m['from_me'] as bool,
                sentAt: DateTime.parse(m['sent_at'] as String),
                isRead: (m['is_read'] as bool?) ?? false,
              ))
          .toList(),
    );
  }
}
