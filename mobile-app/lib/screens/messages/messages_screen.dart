import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
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
              context.push('/messages/${Uri.encodeComponent(u.displayName)}'),
        ),
    ],
  );
}

class _Conversation {
  final String name;
  final String lastMessage;
  final String time;
  final bool hasUnread;
  final int unreadCount;

  const _Conversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.hasUnread = false,
    this.unreadCount = 0,
  });
}

const _conversations = [
  _Conversation(
    name: 'Priya Nair',
    lastMessage: 'Loved your latest poem! The imagery was stunning.',
    time: '2m',
    hasUnread: true,
    unreadCount: 2,
  ),
  _Conversation(
    name: 'Marcus Osei',
    lastMessage: 'Would you want to collaborate on a collection?',
    time: '1h',
    hasUnread: true,
    unreadCount: 1,
  ),
  _Conversation(
    name: 'Javier Morales',
    lastMessage: 'Thanks for the tip! Means a lot.',
    time: '3h',
  ),
  _Conversation(
    name: 'luna_reads',
    lastMessage: 'Your audio reading was so peaceful.',
    time: 'Yesterday',
  ),
  _Conversation(
    name: 'ink_and_fire',
    lastMessage: 'I shared your article with my book club.',
    time: '2d',
  ),
];

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              itemCount: _conversations.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 72,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
              itemBuilder: (_, i) => _ConversationTile(
                conversation: _conversations[i],
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
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

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final bool isDark;
  const _ConversationTile({required this.conversation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return InkWell(
      onTap: () => context.push(
          '/messages/${Uri.encodeComponent(conversation.name)}'),
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
                    conversation.name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                if (conversation.hasUnread)
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
                      Text(
                        conversation.name,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: conversation.hasUnread ? FontWeight.w700 : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      Text(
                        conversation.time,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: conversation.hasUnread ? AppColors.accent : mutedColor,
                          fontWeight: conversation.hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: conversation.hasUnread ? textColor : mutedColor,
                            fontWeight: conversation.hasUnread ? FontWeight.w500 : FontWeight.w400,
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
