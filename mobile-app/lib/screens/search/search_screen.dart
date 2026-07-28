import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/sync_feedback.dart';
import '../../widgets/post_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPosts = ref.watch(postsNotifierProvider);
    final results = _query.isEmpty
        ? <Post>[]
        : allPosts
              .where(
                (p) =>
                    p.title.toLowerCase().contains(_query.toLowerCase()) ||
                    p.content.toLowerCase().contains(_query.toLowerCase()) ||
                    p.author.displayName.toLowerCase().contains(
                      _query.toLowerCase(),
                    ),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: GoogleFonts.lato(
            fontSize: 16,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search writers, posts, categories...',
            hintStyle: GoogleFonts.lato(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _SearchSuggestions(isDark: isDark)
          : results.isEmpty
          ? _NoResults(query: _query)
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                ...results.map((p) => PostCard(post: p)),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _SearchSuggestions extends ConsumerWidget {
  final bool isDark;
  const _SearchSuggestions({required this.isDark});

  static const _trending = [
    'Poems',
    'Dark fiction',
    'Haiku',
    'Personal essays',
    'Short stories',
    'Love poems',
    'Satire',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final chipBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final followed = ref.watch(followNotifierProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Trending', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trending
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.lato(fontSize: 13, color: textColor),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Writers to follow',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...mockUsers.map((u) {
          final isFollowing = followed.contains(u.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context.push('/user/${u.id}'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: chipBg,
                    child: Text(
                      u.displayName.isEmpty
                          ? '?'
                          : u.displayName[0].toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (u.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: AppColors.accent,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '@${u.username}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final notifier =
                          ref.read(followNotifierProvider.notifier);
                      final ok = isFollowing
                          ? await notifier.unfollow(u.id)
                          : await notifier.follow(u.id);
                      if (!ok && context.mounted) notifySyncFailure(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.transparent
                            : AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFollowing
                              ? (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.divider)
                              : AppColors.accent,
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFollowing
                              ? (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            'Try different keywords',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
