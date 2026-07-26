import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/conversations_provider.dart';
import '../../theme/app_theme.dart';
import '../messages/messages_screen.dart' show ConversationTile;

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Conversation list screen — a thin, buyer/seller-framed filter over the same
// [conversationsProvider] backing MessagesScreen. The actual chat thread UI lives
// in ConversationScreen (screens/messages/conversation_screen.dart), shared
// with the social messaging stack.
// ─────────────────────────────────────────────────────────────────────────────

class MktMessagesScreen extends ConsumerWidget {
  const MktMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;

    final salesConversations = ref
        .watch(conversationsProvider)
        .where((c) => c.contextLabel != null)
        .toList();
    final unread = salesConversations.where((c) => c.hasUnread).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Messages',
                style: Theme.of(context).appBarTheme.titleTextStyle),
            if (unread > 0)
              Text('$unread unread',
                  style: GoogleFonts.lato(
                      fontSize: 11,
                      color: const Color(0xFF5C7A5C),
                      fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _snack(context,
                'Buyers message you about your listings — replies appear here.'),
          ),
        ],
      ),
      body: salesConversations.isEmpty
          ? _EmptyMessages(isDark: isDark)
          : ListView.separated(
              itemCount: salesConversations.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 72, color: divColor),
              itemBuilder: (_, i) => ConversationTile(
                conversation: salesConversations[i],
                isDark: isDark,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMessages extends StatelessWidget {
  final bool isDark;
  const _EmptyMessages({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 56, color: mutedColor),
        const SizedBox(height: 14),
        Text('No messages yet',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Buyer messages about your\nlistings will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
      ]),
    );
  }
}
