import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_sheet.dart';

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class SalesConversation {
  final String id;
  final String buyerName;
  final String listingTitle;
  final String lastMessage;
  final String time;
  final bool fromBuyer;
  final bool hasUnread;
  final List<ChatMsg> messages;

  const SalesConversation({
    required this.id,
    required this.buyerName,
    required this.listingTitle,
    required this.lastMessage,
    required this.time,
    required this.messages,
    this.fromBuyer = true,
    this.hasUnread = false,
  });
}

class ChatMsg {
  final String text;
  final bool fromBuyer;
  final String time;
  const ChatMsg(this.text, {required this.fromBuyer, required this.time});
}

final mockSalesConversations = <SalesConversation>[
  SalesConversation(
    id: 'sc1',
    buyerName: 'Priya Nair',
    listingTitle: 'The Glass House',
    lastMessage: 'Just received it — absolutely beautiful printing!',
    time: '5m',
    hasUnread: true,
    messages: const [
      ChatMsg('Hi! I just ordered The Glass House — can\'t wait!',
          fromBuyer: true, time: '2d'),
      ChatMsg('Thank you so much Priya, I hope you enjoy it!',
          fromBuyer: false, time: '2d'),
      ChatMsg('Just received it — absolutely beautiful printing!',
          fromBuyer: true, time: '5m'),
    ],
  ),
  SalesConversation(
    id: 'sc2',
    buyerName: 'luna_reads',
    listingTitle: 'Echoes in the Dark (Audio)',
    lastMessage: 'Does the audio include the author\'s commentary?',
    time: '1h',
    hasUnread: true,
    messages: const [
      ChatMsg('Does the audio include the author\'s commentary?',
          fromBuyer: true, time: '1h'),
    ],
  ),
  SalesConversation(
    id: 'sc3',
    buyerName: 'ink_and_fire',
    listingTitle: 'Salt & Smoke',
    lastMessage: 'Thanks for the quick shipping!',
    time: '3h',
    messages: const [
      ChatMsg('When will my order ship?', fromBuyer: true, time: '1d'),
      ChatMsg('Shipped this morning! Should arrive in 3–5 days.',
          fromBuyer: false, time: '1d'),
      ChatMsg('Thanks for the quick shipping!', fromBuyer: true, time: '3h'),
    ],
  ),
  SalesConversation(
    id: 'sc4',
    buyerName: 'Marcus Osei',
    listingTitle: 'The Glass House',
    lastMessage: 'Happy to help — enjoy the read!',
    time: 'Yesterday',
    fromBuyer: false,
    messages: const [
      ChatMsg('I had a question about the signed edition.',
          fromBuyer: true, time: '2d'),
      ChatMsg('Of course! All physical copies are signed.',
          fromBuyer: false, time: '2d'),
      ChatMsg('Perfect, I\'ll grab one!', fromBuyer: true, time: 'Yesterday'),
      ChatMsg('Happy to help — enjoy the read!',
          fromBuyer: false, time: 'Yesterday'),
    ],
  ),
  SalesConversation(
    id: 'sc5',
    buyerName: 'Javier Morales',
    listingTitle: 'Between the Lines (E-Book)',
    lastMessage: 'Is a signed copy available?',
    time: '2d',
    messages: const [
      ChatMsg('Is a signed copy available?', fromBuyer: true, time: '2d'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Conversation list screen
// ─────────────────────────────────────────────────────────────────────────────

class MktMessagesScreen extends StatelessWidget {
  const MktMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final cardBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;

    final unread =
        mockSalesConversations.where((c) => c.hasUnread).length;

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
            onPressed: () => _snack(
                context, 'Buyers message you about your listings — replies appear here.'),
          ),
        ],
      ),
      body: mockSalesConversations.isEmpty
          ? _EmptyMessages(isDark: isDark)
          : ListView.separated(
              itemCount: mockSalesConversations.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 72, color: divColor),
              itemBuilder: (context, i) {
                final conv = mockSalesConversations[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _SalesConversationScreen(
                        conv: conv,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      // Avatar
                      Stack(children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: cardBg,
                          child: Text(
                            conv.buyerName[0].toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent),
                          ),
                        ),
                        if (conv.hasUnread)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C7A5C),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: surfaceBg, width: 2),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(width: 12),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(conv.buyerName,
                                    style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: conv.hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: textColor)),
                              ),
                              Text(conv.time,
                                  style: GoogleFonts.lato(
                                      fontSize: 11,
                                      color: conv.hasUnread
                                          ? const Color(0xFF5C7A5C)
                                          : mutedColor,
                                      fontWeight: conv.hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.auto_stories_rounded,
                                  size: 11, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(conv.listingTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              if (!conv.fromBuyer)
                                Text('You: ',
                                    style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w600)),
                              Expanded(
                                child: Text(conv.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: conv.hasUnread
                                            ? textColor
                                            : mutedColor,
                                        fontWeight: conv.hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.w400)),
                              ),
                              if (conv.hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C7A5C),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text('New',
                                      style: GoogleFonts.lato(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual conversation (chat thread)
// ─────────────────────────────────────────────────────────────────────────────

class _SalesConversationScreen extends StatefulWidget {
  final SalesConversation conv;
  final bool isDark;
  const _SalesConversationScreen(
      {required this.conv, required this.isDark});

  @override
  State<_SalesConversationScreen> createState() =>
      _SalesConversationScreenState();
}

class _SalesConversationScreenState
    extends State<_SalesConversationScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMsg> _msgs = [];

  @override
  void initState() {
    super.initState();
    _msgs.addAll(widget.conv.messages);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(ChatMsg(text, fromBuyer: false, time: 'now'));
    });
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final inputBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conv.buyerName,
                style: Theme.of(context).appBarTheme.titleTextStyle),
            Row(children: [
              Icon(Icons.auto_stories_rounded,
                  size: 11, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(widget.conv.listingTitle,
                  style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => showActionSheet(
              context,
              title: widget.conv.buyerName,
              items: [
                ActionSheetItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Mark as resolved',
                    onTap: () => _snack(context, 'Marked as resolved')),
                ActionSheetItem(
                    icon: Icons.auto_stories_rounded,
                    label: 'View listing',
                    onTap: () =>
                        _snack(context, 'Opening ${widget.conv.listingTitle}…')),
                ActionSheetItem(
                    icon: Icons.block_rounded,
                    label: 'Block buyer',
                    destructive: true,
                    onTap: () => _snack(context, '${widget.conv.buyerName} blocked')),
              ],
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final msg = _msgs[i];
              final isMine = !msg.fromBuyer;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: isMine
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMine) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        child: Text(
                          widget.conv.buyerName[0].toUpperCase(),
                          style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.accent
                              : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.surfaceVariant),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMine ? 16 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(msg.text,
                                style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: isMine
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary))),
                            const SizedBox(height: 3),
                            Text(msg.time,
                                style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: isMine
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : mutedColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: surfaceBg,
            border: Border(top: BorderSide(color: divColor)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.lato(fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Reply…',
                    hintStyle: GoogleFonts.lato(
                        fontSize: 14, color: mutedColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _ctrl.text.trim().isNotEmpty ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ctrl.text.trim().isNotEmpty
                      ? AppColors.accent
                      : (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: _ctrl.text.trim().isNotEmpty
                      ? Colors.white
                      : mutedColor,
                ),
              ),
            ),
          ]),
        ),
      ]),
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
