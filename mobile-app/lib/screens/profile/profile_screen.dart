import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio_post_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/edit_profile_sheet.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_sheet.dart';
import '../reader/book_reader_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPosts = ref.watch(postsNotifierProvider);
    final userPosts = allPosts.where((p) => p.author.id == user.id).toList();
    final audioPosts = userPosts.where((p) => p.audioUrl != null).toList();
    final savedPosts = allPosts.where((p) => p.isFavourited).toList();

    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 4),
      // NestedScrollView lets the header scroll away with the content while
      // the tab bar stays pinned — so scrolling moves everything, not just
      // the post list.
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              isDark: isDark,
              postCount: userPosts.length,
              audioCount: audioPosts.length,
              savedCount: savedPosts.length,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedTabBar(
              controller: _tabs,
              isDark: isDark,
              tabs: [
                Tab(text: 'Posts (${userPosts.length})'),
                Tab(text: 'Audio (${audioPosts.length})'),
                Tab(text: 'Saved (${savedPosts.length})'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _PostsTab(posts: userPosts, isDark: isDark),
            _AudioTab(posts: audioPosts, isDark: isDark),
            _SavedTab(posts: savedPosts, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header (cover, avatar, info, stats, buttons, tab bar)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final LitUser user;
  final bool isDark;
  final int postCount;
  final int audioCount;
  final int savedCount;

  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.postCount,
    required this.audioCount,
    required this.savedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover + avatar overlap
        _CoverWithAvatar(user: user, isDark: isDark),

        // Name, username, bio — top padding accounts for avatar extending below cover
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    user.displayName,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified_rounded, size: 17, color: AppColors.accent),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: GoogleFonts.lato(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Text(
                user.bio,
                style: GoogleFonts.lora(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stats row
        _StatsRow(user: user, isDark: isDark),

        const SizedBox(height: 12),

        // Action buttons
        _ActionButtons(isDark: isDark),

        const SizedBox(height: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned tab bar — stays at the top while the header above scrolls away
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final bool isDark;
  final List<Tab> tabs;

  const _PinnedTabBar({
    required this.controller,
    required this.isDark,
    required this.tabs,
  });

  @override
  double get minExtent => 49;
  @override
  double get maxExtent => 49;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: controller,
            indicatorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            indicatorWeight: 2,
            labelStyle:
                GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w500),
            labelColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            tabs: tabs,
          ),
          Divider(height: 1, color: divColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedTabBar oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.isDark != isDark ||
      oldDelegate.tabs != tabs;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover gradient + avatar overlapping its bottom edge
// ─────────────────────────────────────────────────────────────────────────────

class _CoverWithAvatar extends StatelessWidget {
  final LitUser user;
  final bool isDark;
  const _CoverWithAvatar({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient cover
        Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurfaceVariant, AppColors.darkBackground]
                  : [AppColors.accentSoft, AppColors.surfaceVariant],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('✍️ Author',
                    style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
            ),
          ),
        ),

        // Settings button — top right of cover
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ),

        // Avatar raised above cover bottom
        Positioned(
          bottom: -28,
          left: 16,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.background,
                width: 3,
              ),
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
            ),
            child: Center(
              child: Text(
                user.displayName.isEmpty
                    ? '?'
                    : user.displayName[0].toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — tappable Followers & Following open sheets
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final LitUser user;
  final bool isDark;
  const _StatsRow({required this.user, required this.isDark});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _StatCell(
          label: 'Followers',
          value: _fmt(user.followersCount),
          isDark: isDark,
          onTap: () => _showSheet(context, 'Followers',
              mockUsers.where((u) => u.id != user.id).toList()),
        ),
        Container(width: 1, height: 32, color: div),
        _StatCell(
          label: 'Following',
          value: '${user.followingCount}',
          isDark: isDark,
          onTap: () => _showSheet(
            context,
            'Following',
            mockUsers.where((u) => u.id != user.id).take(2).toList(),
          ),
        ),
        Container(width: 1, height: 32, color: div),
        _StatCell(
          label: 'Earned',
          value: '\$${user.earnings.toStringAsFixed(0)}',
          isDark: isDark,
          highlight: true,
          onTap: () => _showTippersSheet(context, user),
        ),
      ]),
    );
  }

  void _showTippersSheet(BuildContext context, LitUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TippersSheet(user: user, isDark: isDark),
    );
  }

  void _showSheet(BuildContext context, String title, List<LitUser> users) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _FollowListSheet(title: title, users: users, isDark: isDark),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  final VoidCallback? onTap;

  const _StatCell({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = Column(children: [
      Text(value,
          style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary))),
      Text(label,
          style: GoogleFonts.lato(
              fontSize: 11,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
    ]);

    return Expanded(
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(6), child: col))
          : col,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Followers / Following bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FollowListSheet extends ConsumerWidget {
  final String title;
  final List<LitUser> users;
  final bool isDark;
  const _FollowListSheet(
      {required this.title, required this.users, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final followed = ref.watch(followNotifierProvider);
    final div = isDark ? AppColors.darkDivider : AppColors.divider;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: div,
                    borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(children: [
              Text(title,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)),
              const SizedBox(width: 8),
              Text('${users.length}',
                  style: GoogleFonts.lato(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted)),
            ]),
          ),
          Divider(height: 1, color: div),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              itemCount: users.length,
              separatorBuilder: (_, idx) => Divider(height: 1, color: div),
              itemBuilder: (_, i) {
                final u = users[i];
                final isFollowing = followed.contains(u.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    child: Text(
                        u.displayName.isEmpty
                            ? '?'
                            : u.displayName[0].toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ),
                  title: Row(children: [
                    Text(u.displayName,
                        style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    if (u.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded,
                          size: 13, color: AppColors.accent),
                    ],
                  ]),
                  subtitle: Text('@${u.username}',
                      style: GoogleFonts.lato(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted)),
                  trailing: GestureDetector(
                    onTap: () {
                      // Returned sync result deliberately ignored: follows
                      // apply locally either way; a failed backend write is
                      // non-fatal.
                      if (isFollowing) {
                        ref
                            .read(followNotifierProvider.notifier)
                            .unfollow(u.id);
                      } else {
                        ref
                            .read(followNotifierProvider.notifier)
                            .follow(u.id);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.transparent
                            : AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFollowing ? div : AppColors.accent,
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFollowing
                              ? (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings breakdown sheet — who tipped, how much, when
// ─────────────────────────────────────────────────────────────────────────────

class _Tip {
  final LitUser from;
  final double amount;
  final DateTime at;
  const _Tip({required this.from, required this.amount, required this.at});
}

class _TippersSheet extends StatelessWidget {
  final LitUser user;
  final bool isDark;
  const _TippersSheet({required this.user, required this.isDark});

  List<_Tip> _mockTips() {
    final others = mockUsers.where((u) => u.id != user.id).toList();
    if (others.isEmpty) return const [];
    final now = DateTime.now();
    final tips = <_Tip>[
      _Tip(from: others[0], amount: 50, at: now.subtract(const Duration(hours: 3))),
      if (others.length > 1)
        _Tip(from: others[1], amount: 20, at: now.subtract(const Duration(days: 1))),
      if (others.length > 2)
        _Tip(from: others[2], amount: 100, at: now.subtract(const Duration(days: 2))),
      _Tip(from: others[0], amount: 10, at: now.subtract(const Duration(days: 4))),
      if (others.length > 1)
        _Tip(from: others[1], amount: 5, at: now.subtract(const Duration(days: 6))),
      if (others.length > 2)
        _Tip(from: others[2], amount: 25, at: now.subtract(const Duration(days: 9))),
      _Tip(from: others[0], amount: 15, at: now.subtract(const Duration(days: 12))),
    ];
    tips.sort((a, b) => b.at.compareTo(a.at));
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final tips = _mockTips();
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

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: div, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(children: [
              Text('Earnings',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ]),
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
                child: Text('Top supporters',
                    style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mutedColor,
                        letterSpacing: 0.5)),
              ),
            ),
            SizedBox(
              height: 88,
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
              child: Text('Recent tips',
                  style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                      letterSpacing: 0.5)),
            ),
          ),
          Expanded(
            child: tips.isEmpty
                ? Center(
                    child: Text('No tips yet',
                        style: GoogleFonts.lato(
                            fontSize: 13, color: mutedColor)),
                  )
                : ListView.separated(
                    controller: ctrl,
                    itemCount: tips.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: div),
                    itemBuilder: (_, i) => _TipRow(tip: tips[i], isDark: isDark),
                  ),
          ),
        ]),
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
      onTap: () {
        Navigator.of(context).pop();
        context.push('/user/${user.id}');
      },
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
                      color: AppColors.accent)),
            ),
            const SizedBox(height: 4),
            Text('\$${total.toStringAsFixed(0)}',
                style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
            Text('$count× · ${user.displayName.split(' ').first}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(fontSize: 10, color: mutedColor)),
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
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.id == tip.from.id;
    final isFollowing =
        ref.watch(followNotifierProvider).contains(tip.from.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () {
        Navigator.of(context).pop();
        context.push('/user/${tip.from.id}');
      },
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
                color: AppColors.accent)),
      ),
      title: Row(children: [
        Flexible(
          child: Text(tip.from.displayName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ),
        if (tip.from.isVerified) ...[
          const SizedBox(width: 4),
          Icon(Icons.verified_rounded, size: 13, color: AppColors.accent),
        ],
      ]),
      subtitle: Text(
          '${_relative(tip.at)} · +\$${tip.amount.toStringAsFixed(2)}',
          style: GoogleFonts.lato(fontSize: 12, color: mutedColor)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — Edit Profile, Share, Settings
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final bool isDark;
  const _ActionButtons({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final side =
        BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => showEditProfileSheet(context),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: Text('Edit Profile',
                style: GoogleFonts.lato(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
                side: side,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: shape),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              showShareSheet(
                context,
                title: user?.displayName ?? 'My profile',
                link:
                    'https://literature.app/u/${user?.username ?? 'me'}',
              );
            },
            icon: const Icon(Icons.share_outlined, size: 15),
            label: Text('Share',
                style: GoogleFonts.lato(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
                side: side,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: shape),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab contents
// ─────────────────────────────────────────────────────────────────────────────

class _PostsTab extends ConsumerWidget {
  final List<Post> posts;
  final bool isDark;
  const _PostsTab({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return _EmptyTab(
          icon: Icons.auto_stories_outlined,
          label: 'No posts yet',
          isDark: isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        onContentTap: () => _openPost(context, ref, posts[i]),
      ),
    );
  }
}

class _AudioTab extends StatelessWidget {
  final List<Post> posts;
  final bool isDark;
  const _AudioTab({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _EmptyTab(
          icon: Icons.headphones_rounded,
          label: 'No audio posts yet',
          isDark: isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (_, i) => AudioPostCard(post: posts[i]),
    );
  }
}

class _SavedTab extends ConsumerWidget {
  final List<Post> posts;
  final bool isDark;
  const _SavedTab({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return _EmptyTab(
          icon: Icons.bookmark_border_rounded,
          label: 'Nothing saved yet',
          isDark: isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        onContentTap: () => _openPost(context, ref, posts[i]),
      ),
    );
  }
}

// Mirrors the home feed's tap behavior: book posts open in the reader,
// everything else opens in the full-screen viewer. The viewer reads from
// [filteredPostsProvider], so reset the category filter to All first to
// guarantee the post we want is at the index we compute.
void _openPost(BuildContext context, WidgetRef ref, Post post) {
  if (post.bookId != null) {
    final book = findBook(post.bookId!) ?? mockBooks.first;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
    );
    return;
  }
  ref.read(feedCategoryProvider.notifier).state = FeedCategory.all;
  final all = ref.read(postsNotifierProvider);
  final idx = all.indexWhere((p) => p.id == post.id);
  if (idx >= 0) context.push('/viewer/$idx');
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _EmptyTab(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 48,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        const SizedBox(height: 12),
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 14,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
      ]),
    );
  }
}
