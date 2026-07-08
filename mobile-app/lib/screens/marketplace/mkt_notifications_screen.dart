import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum MktNotifType { sale, shipped, review, priceDrop, trending, purchase, refund }

class MktNotif {
  final String id;
  final MktNotifType type;
  final String title;
  final String body;
  final DateTime at;
  bool isRead;

  MktNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    this.isRead = false,
  });
}

final _now = DateTime.now();

final mockMktNotifs = <MktNotif>[
  MktNotif(id: 'n1', type: MktNotifType.sale, title: 'New Sale!',
      body: 'Priya Nair purchased "The Glass House" for \$14.99',
      at: _now.subtract(const Duration(minutes: 8))),
  MktNotif(id: 'n2', type: MktNotifType.sale, title: 'New Sale!',
      body: 'Anonymous purchased "Echoes in the Dark" for \$9.99',
      at: _now.subtract(const Duration(hours: 2))),
  MktNotif(id: 'n3', type: MktNotifType.shipped, title: 'Order Shipped',
      body: 'Your order #ORD-48291 is on its way — expected in 3–5 days',
      at: _now.subtract(const Duration(hours: 5))),
  MktNotif(id: 'n4', type: MktNotifType.review, title: 'New Review',
      body: 'Marcus Osei left ★★★★★ on "The Glass House"',
      at: _now.subtract(const Duration(hours: 7)), isRead: true),
  MktNotif(id: 'n5', type: MktNotifType.priceDrop, title: 'Price Drop Alert',
      body: '"Salt & Smoke" by Marcus Osei dropped to \$9.99',
      at: _now.subtract(const Duration(hours: 10)), isRead: true),
  MktNotif(id: 'n6', type: MktNotifType.trending, title: 'Trending Now',
      body: '"The Glass House" is in the top 10 this week',
      at: _now.subtract(const Duration(days: 1)), isRead: true),
  MktNotif(id: 'n7', type: MktNotifType.purchase, title: 'Purchase Confirmed',
      body: 'You purchased "Between the Lines" — check your Library',
      at: _now.subtract(const Duration(days: 2)), isRead: true),
  MktNotif(id: 'n8', type: MktNotifType.sale, title: 'New Sale!',
      body: 'luna_reads purchased "Midnight Verses" for \$11.99',
      at: _now.subtract(const Duration(days: 3)), isRead: true),
  MktNotif(id: 'n9', type: MktNotifType.refund, title: 'Refund Processed',
      body: 'Refund of \$6.99 for "Solitudes" has been issued',
      at: _now.subtract(const Duration(days: 4)), isRead: true),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MktNotificationsScreen extends StatefulWidget {
  const MktNotificationsScreen({super.key});

  @override
  State<MktNotificationsScreen> createState() => _MktNotificationsScreenState();
}

class _MktNotificationsScreenState extends State<MktNotificationsScreen> {
  final List<MktNotif> _notifs = List.from(mockMktNotifs);

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  void _markAll() => setState(() {
        for (final n in _notifs) { n.isRead = true; }
      });

  void _markOne(MktNotif n) => setState(() { n.isRead = true; });

  void _dismiss(MktNotif n) => setState(() => _notifs.remove(n));

  // Group into Today / Yesterday / Earlier
  Map<String, List<MktNotif>> get _grouped {
    final today = DateTime(
        _now.year, _now.month, _now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<MktNotif>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    for (final n in _notifs) {
      final d = DateTime(n.at.year, n.at.month, n.at.day);
      if (d == today) {
        map['Today']!.add(n);
      } else if (d == yesterday) {
        map['Yesterday']!.add(n);
      } else {
        map['Earlier']!.add(n);
      }
    }
    map.removeWhere((_, list) => list.isEmpty);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications',
                style: Theme.of(context).appBarTheme.titleTextStyle),
            if (_unreadCount > 0)
              Text('$_unreadCount unread',
                  style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAll,
              child: Text('Mark all read',
                  style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
            ),
        ],
      ),
      body: _notifs.isEmpty
          ? _EmptyNotifs(isDark: isDark)
          : ListView(
              children: grouped.entries.expand((entry) {
                final section = entry.key;
                final items = entry.value;
                return [
                  // Section header
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(section,
                        style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: mutedColor,
                            letterSpacing: 0.5)),
                  ),
                  ...items.map((n) => _NotifTile(
                        notif: n,
                        isDark: isDark,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        divColor: divColor,
                        onTap: () => _markOne(n),
                        onDismiss: () => _dismiss(n),
                      )),
                ];
              }).toList(),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile (swipe-to-dismiss)
// ─────────────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final MktNotif notif;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final Color divColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({
    required this.notif,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.divColor,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _icon(MktNotifType t) => switch (t) {
        MktNotifType.sale => Icons.monetization_on_rounded,
        MktNotifType.shipped => Icons.local_shipping_rounded,
        MktNotifType.review => Icons.star_rounded,
        MktNotifType.priceDrop => Icons.trending_down_rounded,
        MktNotifType.trending => Icons.trending_up_rounded,
        MktNotifType.purchase => Icons.shopping_bag_rounded,
        MktNotifType.refund => Icons.undo_rounded,
      };

  Color _color(MktNotifType t) => switch (t) {
        MktNotifType.sale => const Color(0xFF5C7A5C),
        MktNotifType.shipped => const Color(0xFF4A6FA5),
        MktNotifType.review => const Color(0xFFF4C430),
        MktNotifType.priceDrop => AppColors.accent,
        MktNotifType.trending => const Color(0xFF9B5C8A),
        MktNotifType.purchase => AppColors.accent,
        MktNotifType.refund => const Color(0xFF888888),
      };

  String _timeLabel(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(notif.type);
    final unreadBg =
        isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF7F4EF);
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notif.isRead ? surfaceBg : unreadBg,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(notif.type), size: 20, color: color),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor)),
                        ),
                        Text(_timeLabel(notif.at),
                            style: GoogleFonts.lato(
                                fontSize: 11, color: mutedColor)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(notif.body,
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            color: notif.isRead ? mutedColor : textColor,
                            height: 1.4)),
                  ],
                ),
              ),

              // Unread dot
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotifs extends StatelessWidget {
  final bool isDark;
  const _EmptyNotifs({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_none_rounded, size: 56, color: mutedColor),
        const SizedBox(height: 14),
        Text('No notifications',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Sales, reviews and updates\nwill appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
      ]),
    );
  }
}
