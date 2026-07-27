import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Earnings — full screen: who tipped, how much, when
// ─────────────────────────────────────────────────────────────────────────────

class _Tip {
  final LitUser from;
  final double amount;
  final DateTime at;
  const _Tip({required this.from, required this.amount, required this.at});
}

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  List<_Tip> _mockTips(LitUser user) {
    final others = mockUsers.where((u) => u.id != user.id).toList();
    if (others.isEmpty) return const [];
    final now = DateTime.now();
    final tips = <_Tip>[
      _Tip(
        from: others[0],
        amount: 50,
        at: now.subtract(const Duration(hours: 3)),
      ),
      if (others.length > 1)
        _Tip(
          from: others[1],
          amount: 20,
          at: now.subtract(const Duration(days: 1)),
        ),
      if (others.length > 2)
        _Tip(
          from: others[2],
          amount: 100,
          at: now.subtract(const Duration(days: 2)),
        ),
      _Tip(
        from: others[0],
        amount: 10,
        at: now.subtract(const Duration(days: 4)),
      ),
      if (others.length > 1)
        _Tip(
          from: others[1],
          amount: 5,
          at: now.subtract(const Duration(days: 6)),
        ),
      if (others.length > 2)
        _Tip(
          from: others[2],
          amount: 25,
          at: now.subtract(const Duration(days: 9)),
        ),
      _Tip(
        from: others[0],
        amount: 15,
        at: now.subtract(const Duration(days: 12)),
      ),
    ];
    tips.sort((a, b) => b.at.compareTo(a.at));
    return tips;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final tips = _mockTips(user);
    final total = tips.fold<double>(0, (s, t) => s + t.amount);

    // Aggregate top tippers by total amount.
    final byUser = <String, double>{};
    final byUserCount = <String, int>{};
    final userOf = <String, LitUser>{};
    for (final t in tips) {
      byUser[t.from.id] = (byUser[t.from.id] ?? 0) + t.amount;
      byUserCount[t.from.id] = (byUserCount[t.from.id] ?? 0) + 1;
      userOf[t.from.id] = t.from;
    }
    final topTippers = byUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Total earned',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${tips.length} tip${tips.length == 1 ? '' : 's'} · ${topTippers.length} supporter${topTippers.length == 1 ? '' : 's'}',
                style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
              ),
            ),
          ),
          Divider(height: 1, color: div),
          if (topTippers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top supporters',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: topTippers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final entry = topTippers[i];
                  final u = userOf[entry.key]!;
                  return _TopTipperChip(
                    user: u,
                    total: entry.value,
                    count: byUserCount[entry.key] ?? 0,
                    isDark: isDark,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: div),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent tips',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: tips.isEmpty
                ? Center(
                    child: Text(
                      'No tips yet',
                      style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
                    ),
                  )
                : ListView.separated(
                    itemCount: tips.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: div),
                    itemBuilder: (_, i) =>
                        _TipRow(tip: tips[i], isDark: isDark),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopTipperChip extends ConsumerWidget {
  final LitUser user;
  final double total;
  final int count;
  final bool isDark;
  const _TopTipperChip({
    required this.user,
    required this.total,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return GestureDetector(
      onTap: () => context.push('/user/${user.id}'),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              child: Text(
                user.displayName.isEmpty
                    ? '?'
                    : user.displayName[0].toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            Text(
              '$count× · ${user.displayName.split(' ').first}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(fontSize: 10, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends ConsumerWidget {
  final _Tip tip;
  final bool isDark;
  const _TipRow({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.id == tip.from.id;
    final isFollowing = ref.watch(followNotifierProvider).contains(tip.from.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () => context.push('/user/${tip.from.id}'),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant,
        child: Text(
          tip.from.displayName.isEmpty
              ? '?'
              : tip.from.displayName[0].toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              tip.from.displayName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (tip.from.isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified_rounded, size: 13, color: AppColors.accent),
          ],
        ],
      ),
      subtitle: Text(
        '${_relative(tip.at)} · +\$${tip.amount.toStringAsFixed(2)}',
        style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
      ),
      trailing: isSelf
          ? null
          : _SmallFollowPill(
              isFollowing: isFollowing,
              isDark: isDark,
              onTap: () {
                final notifier = ref.read(followNotifierProvider.notifier);
                // Returned sync result deliberately ignored: follows apply
                // locally either way; a failed backend write is non-fatal.
                if (isFollowing) {
                  notifier.unfollow(tip.from.id);
                } else {
                  notifier.follow(tip.from.id);
                }
              },
            ),
    );
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}

class _SmallFollowPill extends StatelessWidget {
  final bool isFollowing;
  final bool isDark;
  final VoidCallback onTap;
  const _SmallFollowPill({
    required this.isFollowing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : accent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 1),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isFollowing ? accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
