import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio_post_card.dart';
import '../../widgets/post_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen — shown when tapping another user's name/avatar
// ─────────────────────────────────────────────────────────────────────────────

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        mockUsers.where((u) => u.id == widget.userId).firstOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPosts = ref.watch(postsNotifierProvider);
    final userPosts = allPosts.where((p) => p.author.id == user.id).toList();
    final audioPosts = userPosts.where((p) => p.audioUrl != null).toList();

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(user.displayName,
            style: Theme.of(context).appBarTheme.titleTextStyle),
      ),
      body: Column(
        children: [
          _UserHeader(
            user: user,
            isDark: isDark,
            postCount: userPosts.length,
            audioCount: audioPosts.length,
            tabs: _tabs,
          ),
          Divider(height: 1, color: divColor),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PostsTab(posts: userPosts, isDark: isDark),
                _AudioTab(posts: audioPosts, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _UserHeader extends ConsumerWidget {
  final LitUser user;
  final bool isDark;
  final int postCount;
  final int audioCount;
  final TabController tabs;

  const _UserHeader({
    required this.user,
    required this.isDark,
    required this.postCount,
    required this.audioCount,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover + avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
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
            ),
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
                    user.displayName[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Name / username / bio
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
                  Icon(Icons.verified_rounded,
                      size: 17, color: AppColors.accent),
                ],
              ]),
              const SizedBox(height: 2),
              Text('@${user.username}',
                  style: GoogleFonts.lato(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted)),
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(user.bio,
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stats row
        _StatsRow(user: user, isDark: isDark, postCount: postCount),

        const SizedBox(height: 12),

        // Follow / Message buttons
        _FollowButtons(user: user, isDark: isDark),

        const SizedBox(height: 12),

        // Tab bar
        TabBar(
          controller: tabs,
          indicatorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          indicatorWeight: 2,
          labelStyle:
              GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w500),
          labelColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          tabs: [
            Tab(text: 'Posts ($postCount)'),
            Tab(text: 'Audio ($audioCount)'),
          ],
        ),
        Divider(height: 1, color: divColor),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final LitUser user;
  final bool isDark;
  final int postCount;
  const _StatsRow(
      {required this.user, required this.isDark, required this.postCount});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _StatCell(label: 'Posts', value: '$postCount', isDark: isDark),
        Container(width: 1, height: 32, color: div),
        _StatCell(
            label: 'Followers',
            value: _fmt(user.followersCount),
            isDark: isDark),
        Container(width: 1, height: 32, color: div),
        _StatCell(
            label: 'Following',
            value: '${user.followingCount}',
            isDark: isDark),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _StatCell(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Follow / Message action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _FollowButtons extends ConsumerWidget {
  final LitUser user;
  final bool isDark;
  const _FollowButtons({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followNotifierProvider);
    final isFollowing = followed.contains(user.id);
    final side =
        BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: isFollowing
              ? OutlinedButton.icon(
                  onPressed: () => ref
                      .read(followNotifierProvider.notifier)
                      .unfollow(user.id),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: Text('Following',
                      style: GoogleFonts.lato(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                      side: side,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: shape),
                )
              : FilledButton.icon(
                  onPressed: () => ref
                      .read(followNotifierProvider.notifier)
                      .follow(user.id),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: Text('Follow',
                      style: GoogleFonts.lato(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: shape),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context
                .push('/messages/${Uri.encodeComponent(user.displayName)}'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: Text('Message',
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

class _PostsTab extends StatelessWidget {
  final List<Post> posts;
  final bool isDark;
  const _PostsTab({required this.posts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _EmptyTab(
          icon: Icons.auto_stories_outlined,
          label: 'No posts yet',
          isDark: isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(post: posts[i]),
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
