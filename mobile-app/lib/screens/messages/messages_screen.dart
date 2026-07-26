import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../providers/conversations_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_sheet.dart';

void _showNewMessage(BuildContext context) {
  showActionSheet(
    context,
    title: 'New message',
    items: [
      for (final u in mockUsers.where((u) => u.id != 'u1'))
        ActionSheetItem(
          icon: Icons.person_outline_rounded,
          label: u.displayName,
          onTap: () =>
              context.push('/messages/${Uri.encodeComponent(u.id)}'),
        ),
    ],
  );
}

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversations = ref
        .watch(conversationsProvider)
        .where((c) => c.contextLabel == null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Messages', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showNewMessage(context)),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(isDark: isDark),
          Expanded(
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 72,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
              itemBuilder: (_, i) => ConversationTile(
                conversation: conversations[i],
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
        onPressed: () => _showNewMessage(context),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDark;
  const _SearchBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'Search messages',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation tile — shared by MessagesScreen (social) and MktMessagesScreen
// (marketplace) so the two entry points don't each reimplement their own row.
// ─────────────────────────────────────────────────────────────────────────────

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isDark;
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final name = conversation.peerName;
    final last = conversation.lastMessage;
    final time = last != null ? formatConversationTime(last.sentAt) : '';
    final hasUnread = conversation.hasUnread;

    return InkWell(
      onTap: () => context
          .push('/messages/${Uri.encodeComponent(conversation.id)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: hasUnread ? AppColors.accent : mutedColor,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  if (conversation.contextLabel != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            size: 11, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            conversation.contextLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last == null
                              ? ''
                              : '${last.fromMe ? 'You: ' : ''}${last.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: hasUnread ? textColor : mutedColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
