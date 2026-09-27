import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/local_store.dart';
import '../../services/users_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio_post_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/edit_profile_sheet.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_sheet.dart';
import '../reader/book_reader_screen.dart';

// Picks an image and saves it as the signed-in user's avatar or cover photo.
// `path` is null on web (file_picker has no local filesystem there) — the
// pick is silently dropped rather than saving a URL-less reference, same
// graceful-degradation pattern PostScreen uses for its own file pickers.
Future<void> _pickProfileImage(
  BuildContext context,
  WidgetRef ref, {
  required bool isCover,
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: false,
  );
  if (!context.mounted || result == null || result.files.isEmpty) return;
  final path = result.files.single.path;
  if (path == null) return;

  final user = ref.read(currentUserProvider);
  if (user == null) return;
  final updated = isCover
      ? user.copyWith(coverImageUrl: path)
      : user.copyWith(avatarUrl: path);
  ref.read(currentUserProvider.notifier).state = updated;
  LocalStore.instance.saveCurrentUser(updated);

  final messenger = ScaffoldMessenger.of(context);
  try {
    await UsersRepository.updateProfile(updated);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Saved on this device. Couldn't sync to the server."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// A user-picked photo is always a local file path today (no upload backend
// yet — see database.md's "no file storage" note); `http`-prefixed values
// are handled too so this keeps working if that ever changes.
Widget? _profileImage(String? url, {required BoxFit fit}) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) {
    return Image.network(url, fit: fit);
  }
  if (kIsWeb) return null;
  return Image.file(File(url), fit: fit);
}

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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName,
                      style: AppFonts.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_rounded,
                      size: 17,
                      color: AppColors.accent,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: AppFonts.ui(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              // Skipped entirely when there's no bio — an empty Text still
              // reserves a line's height, which read as a gap before the
              // stats row.
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  user.bio,
                  style: AppFonts.reading(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Stats row
        _StatsRow(user: user, isDark: isDark),

        const SizedBox(height: 12),

        // Action buttons
        _ActionButtons(isDark: isDark),
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
            labelStyle: AppFonts.ui(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppFonts.ui(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            labelColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextMuted
                : AppColors.textMuted,
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

class _CoverWithAvatar extends ConsumerWidget {
  final LitUser user;
  final bool isDark;
  const _CoverWithAvatar({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverImage = _profileImage(user.coverImageUrl, fit: BoxFit.cover);
    final avatarImage = _profileImage(user.avatarUrl, fit: BoxFit.cover);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover — tap to replace with a picked photo, falls back to gradient
        GestureDetector(
          onTap: () => _pickProfileImage(context, ref, isCover: true),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: coverImage == null
                  ? LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.darkSurfaceVariant,
                              AppColors.darkBackground,
                            ]
                          : [AppColors.accentSoft, AppColors.surfaceVariant],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ?coverImage,
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✍️ Author',
                        style: AppFonts.ui(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                // Camera badge — signals the cover is tappable
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _CameraBadge(size: 26, iconSize: 13),
                ),
              ],
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
                child: const Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Avatar raised above cover bottom — tap to replace with a picked
        // photo, falls back to the initial-letter placeholder.
        Positioned(
          bottom: -28,
          left: 16,
          child: GestureDetector(
            onTap: () => _pickProfileImage(context, ref, isCover: false),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                  child: avatarImage != null
                      ? ClipOval(child: avatarImage)
                      : Center(
                          child: Text(
                            user.displayName.isEmpty
                                ? '?'
                                : user.displayName[0].toUpperCase(),
                            style: AppFonts.display(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                ),
                const Positioned(
                  bottom: -2,
                  right: -2,
                  child: _CameraBadge(size: 24, iconSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Small camera-icon badge overlaid on the cover/avatar to signal it's
// tappable to change the photo.
class _CameraBadge extends StatelessWidget {
  final double size;
  final double iconSize;
  const _CameraBadge({required this.size, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        size: iconSize,
        color: Colors.white,
      ),
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

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCell(
            label: 'Followers',
            value: _fmt(user.followersCount),
            isDark: isDark,
            onTap: () => context.push('/profile/followers'),
          ),
          Container(width: 1, height: 32, color: div),
          _StatCell(
            label: 'Following',
            value: '${user.followingCount}',
            isDark: isDark,
            onTap: () => context.push('/profile/following'),
          ),
          Container(width: 1, height: 32, color: div),
          _StatCell(
            label: 'Earned',
            value: '\$${user.earnings.toStringAsFixed(0)}',
            isDark: isDark,
            highlight: true,
            onTap: () => context.push('/profile/earnings'),
          ),
        ],
      ),
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
    final col = Column(
      children: [
        Text(
          value,
          style: AppFonts.ui(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: highlight
                ? AppColors.accent
                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
        Text(
          label,
          style: AppFonts.ui(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              // No top padding — that's what left a gap between the bio
              // above and the stats row; horizontal/bottom padding stays
              // for a comfortable tap target.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: col,
              ),
            )
          : col,
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
    final side = BorderSide(
      color: isDark ? AppColors.darkDivider : AppColors.divider,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showEditProfileSheet(context),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: Text(
                'Edit Profile',
                style: AppFonts.ui(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: side,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: shape,
              ),
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
                  link: 'https://literature.app/user/${user?.id ?? ''}',
                );
              },
              icon: const Icon(Icons.share_outlined, size: 15),
              label: Text(
                'Share',
                style: AppFonts.ui(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: side,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: shape,
              ),
            ),
          ),
        ],
      ),
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
        isDark: isDark,
      );
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
        isDark: isDark,
      );
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
        isDark: isDark,
      );
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
    final book = findBook(post.bookId!);
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This book is not available yet')),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)));
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
  const _EmptyTab({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // A brand-new account with zero posts/audio/saved lands here with very
    // little vertical room to work with (NestedScrollView's pinned tab bar
    // can leave the body just a few dozen pixels tall before any scrolling
    // happens) — SingleChildScrollView lets this degrade to a short scroll
    // instead of a RenderFlex overflow the way ListView-based tabs already
    // tolerate the same tight space.
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppFonts.ui(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
