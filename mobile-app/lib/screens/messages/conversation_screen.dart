import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_sheet.dart';

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _Message {
  final String text;
  final bool fromMe;
  final DateTime sentAt;
  final bool isRead;

  const _Message({
    required this.text,
    required this.fromMe,
    required this.sentAt,
    this.isRead = false,
  });
}

final _mockThreads = <String, List<_Message>>{
  'Priya Nair': [
    _Message(
      text: 'Hey! Just finished reading "Between the Lines" 😭',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    _Message(
      text: 'The last stanza made me tear up honestly',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 17)),
    ),
    _Message(
      text: 'That means so much, thank you Priya 🙏',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: true,
    ),
    _Message(
      text:
          'I wrote it during a really quiet Sunday — everything just poured out',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(minutes: 14)),
      isRead: true,
    ),
    _Message(
      text: 'You can really feel that. The pacing is so deliberate',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    _Message(
      text: 'Loved your latest poem! The imagery was stunning.',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ],
  'Marcus Osei': [
    _Message(
      text: 'I\'ve been following your work for months now',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    _Message(
      text:
          'Your voice is so distinct. The way you use white space is incredible',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    _Message(
      text: 'That\'s incredibly kind, I really appreciate it',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      isRead: true,
    ),
    _Message(
      text: 'Would you want to collaborate on a collection?',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  'Javier Morales': [
    _Message(
      text: 'Your comment on my piece yesterday really pushed me',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _Message(
      text: 'I rewrote the ending three times because of it',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _Message(
      text: 'That\'s exactly what good feedback should do! So glad it helped',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
    ),
    _Message(
      text: 'Thanks for the tip! Means a lot.',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ],
  'luna_reads': [
    _Message(
      text: 'I listen to your audio readings when I can\'t sleep',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    _Message(
      text: 'They\'re so calming 🌙',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    _Message(
      text: 'That\'s such a lovely thing to say ✨',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      isRead: true,
    ),
    _Message(
      text: 'Your audio reading was so peaceful.',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
  'ink_and_fire': [
    _Message(
      text: 'My book club is doing a "discover indie writers" month',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    _Message(
      text: 'I nominated your article on grief and syntax',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    _Message(
      text: 'Wow, that\'s honestly humbling. Thank you so much!',
      fromMe: true,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      isRead: true,
    ),
    _Message(
      text: 'I shared your article with my book club.',
      fromMe: false,
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ConversationScreen extends StatefulWidget {
  final String peerName;
  const ConversationScreen({super.key, required this.peerName});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final List<_Message> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(
      _mockThreads[widget.peerName] ??
          [
            _Message(
              text: 'Hi there! 👋',
              fromMe: false,
              sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ],
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, fromMe: true, sentAt: DateTime.now()));
      _textCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          Expanded(
            child: _MessageList(
              messages: _messages,
              peerName: widget.peerName,
              isDark: isDark,
              scrollCtrl: _scrollCtrl,
            ),
          ),
          _InputBar(controller: _textCtrl, isDark: isDark, onSend: _send),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
    final initial = widget.peerName.isNotEmpty
        ? widget.peerName[0].toUpperCase()
        : '?';

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            child: Text(
              initial,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.peerName,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                'Active now',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: const Color(0xFF5C7A5C),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => showActionSheet(
            context,
            title: widget.peerName,
            items: [
              ActionSheetItem(
                icon: Icons.notifications_off_outlined,
                label: 'Mute notifications',
                onTap: () => _snack(context, 'Notifications muted'),
              ),
              ActionSheetItem(
                icon: Icons.push_pin_outlined,
                label: 'Pin conversation',
                onTap: () => _snack(context, 'Conversation pinned'),
              ),
              ActionSheetItem(
                icon: Icons.block_rounded,
                label: 'Block ${widget.peerName}',
                destructive: true,
                onTap: () => _snack(context, '${widget.peerName} blocked'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message list
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<_Message> messages;
  final String peerName;
  final bool isDark;
  final ScrollController scrollCtrl;

  const _MessageList({
    required this.messages,
    required this.peerName,
    required this.isDark,
    required this.scrollCtrl,
  });

  bool _showTimestamp(int i) {
    if (i == 0) return true;
    final prev = messages[i - 1].sentAt;
    final curr = messages[i].sentAt;
    return curr.difference(prev).inMinutes > 15;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return Column(
          children: [
            if (_showTimestamp(i))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _formatTime(msg.sentAt),
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ),
            _Bubble(
              message: msg,
              peerName: peerName,
              isDark: isDark,
              showAvatar:
                  !msg.fromMe &&
                  (i == messages.length - 1 || messages[i + 1].fromMe),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _Message message;
  final String peerName;
  final bool isDark;
  final bool showAvatar;

  const _Bubble({
    required this.message,
    required this.peerName,
    required this.isDark,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final fromMe = message.fromMe;

    final bubbleBg = fromMe
        ? AppColors.accent
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final textColor = fromMe
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final initial = peerName.isNotEmpty ? peerName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: fromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Peer avatar (only on last consecutive peer message)
          if (!fromMe) ...[
            SizedBox(
              width: 30,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
                      child: Text(
                        initial,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(
                    fromMe ? 18 : (showAvatar ? 4 : 18),
                  ),
                  bottomRight: Radius.circular(fromMe ? 4 : 18),
                ),
                border: fromMe ? null : Border.all(color: borderColor),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ),
          ),

          // Read receipt on last sent message
          if (fromMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
              size: 14,
              color: message.isRead
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fieldBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            10,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 24,
              color: mutedColor,
            ),
            onPressed: () => showActionSheet(
              context,
              title: 'Attach',
              items: [
                ActionSheetItem(
                  icon: Icons.photo_outlined,
                  label: 'Photo',
                  onTap: () => _snack(context, 'Photo attached'),
                ),
                ActionSheetItem(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'Document',
                  onTap: () => _snack(context, 'Document attached'),
                ),
                ActionSheetItem(
                  icon: Icons.mic_none_rounded,
                  label: 'Voice clip',
                  onTap: () => _snack(context, 'Recording…'),
                ),
              ],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 6),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.lato(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: GoogleFonts.lato(fontSize: 14, color: mutedColor),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, _) {
              final hasText = val.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText ? onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.accent
                        : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: hasText ? Colors.white : mutedColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
