import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
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
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: AppFonts.ui(
            fontSize: 16,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search writers, posts, categories...',
            hintStyle: AppFonts.ui(
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
              tooltip: 'Clear search',
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

class _SearchSuggestions extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final chipBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;

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
                    style: AppFonts.ui(fontSize: 13, color: textColor),
                  ),
                ),
              )
              .toList(),
        ),
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
