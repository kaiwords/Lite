import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

enum AlertType { like, comment, follow, tip, newPost }

class AlertItem {
  final AlertType type;
  final String actor;
  final String detail;
  final Duration ago;
  final bool isRead;
  final String? postId; // the post this alert is about, if any — see mockPosts

  const AlertItem({
    required this.type,
    required this.actor,
    required this.detail,
    required this.ago,
    this.isRead = false,
    this.postId,
  });

  AlertItem copyWith({bool? isRead}) => AlertItem(
    type: type,
    actor: actor,
    detail: detail,
    ago: ago,
    isRead: isRead ?? this.isRead,
    postId: postId,
  );
}

// No notifications backend exists yet (no Supabase table) — the app has no
// real data source for alerts, so this starts empty rather than fabricated.
// See demo_data/demo_alerts.dart for sample content, kept for reference/
// tests only.
const _alerts = <AlertItem>[];

// Which calendar week (0 = this week, 1 = last week, …) an alert falls in.
int _weeksAgo(Duration ago) => ago.inDays ~/ 7;

String _weekLabel(int weeksAgo) {
  if (weeksAgo <= 0) return 'This Week';
  if (weeksAgo == 1) return 'Last Week';
  return '$weeksAgo Weeks Ago';
}

// A row is either a week-group header or a reference (by index into
// _AlertsScreenState._items) to an alert — built once per build so the list
// can group consecutive same-week alerts under one header + divider.
sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  final int weeksAgo;
  const _HeaderRow(this.weeksAgo);
}

class _ItemRow extends _Row {
  final int index;
  const _ItemRow(this.index);
}

List<_Row> _buildRows(List<AlertItem> items) {
  final rows = <_Row>[];
  int? lastWeek;
  for (var i = 0; i < items.length; i++) {
    final week = _weeksAgo(items[i].ago);
    if (week != lastWeek) {
      rows.add(_HeaderRow(week));
      lastWeek = week;
    }
    rows.add(_ItemRow(i));
  }
  return rows;
}

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
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

  // Mirrors the home feed's tap behavior (see home_screen.dart/
  // profile_screen.dart's _openPost): the viewer reads from
  // filteredPostsProvider, so reset the category filter to All first to
  // guarantee the post we want is at the index we compute.
  void _openPost(String postId) {
    ref.read(feedCategoryProvider.notifier).state = FeedCategory.all;
    final all = ref.read(postsNotifierProvider);
    final idx = all.indexWhere((p) => p.id == postId);
    if (idx >= 0) context.push('/viewer/$idx');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _items.where((a) => !a.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppFonts.ui(
                  fontSize: 13,
                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                ),
              ),
            ),
        ],
      ),
      // Audio tab disabled — Alerts moved from index 3 to 2.
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 2),
      body: Builder(
        builder: (context) {
          if (_items.isEmpty) {
            final muted = isDark
                ? AppColors.darkTextMuted
                : AppColors.textMuted;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: AppFonts.ui(fontSize: 14, color: muted),
                  ),
                ],
              ),
            );
          }
          final rows = _buildRows(_items);
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, rowIndex) {
              final row = rows[rowIndex];
              if (row is _HeaderRow) {
                return _WeekHeader(
                  label: _weekLabel(row.weeksAgo),
                  isDark: isDark,
                );
              }
              final i = (row as _ItemRow).index;
              return _AlertTile(
                    alert: _items[i],
                    isDark: isDark,
                    onTap: () {
                      _markRead(i);
                      final postId = _items[i].postId;
                      if (postId != null) _openPost(postId);
                    },
                  )
                  .animate()
                  .fadeIn(duration: 260.ms, delay: 30.ms * (rowIndex % 8))
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 260.ms,
                    curve: Curves.easeOut,
                  );
            },
          );
        },
      ),
    );
  }
}

// Week-group header — a small caption label followed by a divider line,
// separating each week's worth of notifications from the next.
class _WeekHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _WeekHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.ui(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: divider),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  final bool isDark;
  final VoidCallback onTap;
  const _AlertTile({
    required this.alert,
    required this.isDark,
    required this.onTap,
  });

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
    final unreadBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
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
                          style: AppFonts.ui(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        TextSpan(
                          text: alert.detail,
                          style: AppFonts.ui(
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
                    style: AppFonts.ui(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              scale: alert.isRead ? 0.0 : 1.0,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
