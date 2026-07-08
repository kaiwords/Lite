import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

enum AlertType { like, comment, follow, tip, newPost }

class AlertItem {
  final AlertType type;
  final String actor;
  final String detail;
  final Duration ago;
  final bool isRead;

  const AlertItem({
    required this.type,
    required this.actor,
    required this.detail,
    required this.ago,
    this.isRead = false,
  });

  AlertItem copyWith({bool? isRead}) => AlertItem(
        type: type,
        actor: actor,
        detail: detail,
        ago: ago,
        isRead: isRead ?? this.isRead,
      );
}

const _alerts = [
  AlertItem(type: AlertType.tip, actor: 'Priya Nair', detail: 'sent you a \$5 tip on "Between the Lines"', ago: Duration(minutes: 12)),
  AlertItem(type: AlertType.like, actor: 'Marcus Osei', detail: 'liked your poem "Between the Lines"', ago: Duration(hours: 1)),
  AlertItem(type: AlertType.comment, actor: 'Javier Morales', detail: 'commented: "This moved me deeply."', ago: Duration(hours: 2)),
  AlertItem(type: AlertType.follow, actor: 'luna_reads', detail: 'started following you', ago: Duration(hours: 3), isRead: true),
  AlertItem(type: AlertType.newPost, actor: 'Priya Nair', detail: 'published a new article: "On Solitude and the Creative Mind"', ago: Duration(hours: 5), isRead: true),
  AlertItem(type: AlertType.like, actor: 'sarah_bookclub', detail: 'liked your poem "Morning Without You"', ago: Duration(hours: 7), isRead: true),
  AlertItem(type: AlertType.tip, actor: 'Anonymous', detail: 'sent you a \$2 tip on "The Glass House"', ago: Duration(days: 1), isRead: true),
  AlertItem(type: AlertType.comment, actor: 'Eleanor Voss', detail: 'replied to your comment', ago: Duration(days: 1), isRead: true),
  AlertItem(type: AlertType.follow, actor: 'ink_and_fire', detail: 'started following you', ago: Duration(days: 2), isRead: true),
];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late List<AlertItem> _items = List.of(_alerts);

  void _markAllRead() {
    setState(() {
      _items = [for (final a in _items) a.copyWith(isRead: true)];
    });
  }

  void _markRead(int i) {
    if (_items[i].isRead) return;
    setState(() => _items[i] = _items[i].copyWith(isRead: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _items.where((a) => !a.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: isDark ? AppColors.darkAccent : AppColors.accent,
                  )),
            ),
        ],
      ),
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 3),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
        itemBuilder: (context, i) => _AlertTile(
          alert: _items[i],
          isDark: isDark,
          onTap: () => _markRead(i),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  final bool isDark;
  final VoidCallback onTap;
  const _AlertTile(
      {required this.alert, required this.isDark, required this.onTap});

  IconData get _icon => switch (alert.type) {
    AlertType.like => Icons.favorite_rounded,
    AlertType.comment => Icons.chat_bubble_rounded,
    AlertType.follow => Icons.person_add_rounded,
    AlertType.tip => Icons.monetization_on_rounded,
    AlertType.newPost => Icons.auto_stories_rounded,
  };

  Color get _iconColor => switch (alert.type) {
    AlertType.like => AppColors.like,
    AlertType.comment => Colors.blue,
    AlertType.follow => Colors.green,
    AlertType.tip => AppColors.accent,
    AlertType.newPost => Colors.purple,
  };

  String _timeAgo(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final unreadBg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
      color: alert.isRead ? bg : unreadBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${alert.actor} ',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      TextSpan(
                        text: alert.detail,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(alert.ago),
                  style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, left: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      ),
    );
  }
}
