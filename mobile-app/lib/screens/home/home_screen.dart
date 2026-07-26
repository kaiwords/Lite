import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/book.dart';
import '../../providers/feed_provider.dart';
import '../../screens/reader/book_reader_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed_filter_row.dart';
import '../../widgets/literature_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/bottom_nav_bar.dart';

const _kPageSize = 8;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  int _visibleCount = _kPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = ref.read(filteredPostsProvider).length;
    if (_visibleCount < total) {
      setState(
          () => _visibleCount = (_visibleCount + _kPageSize).clamp(0, total));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPosts = ref.watch(filteredPostsProvider);

    // Reset page when filter/category changes
    ref.listen(feedCategoryProvider, (prev, next) {
      if (prev != next) setState(() => _visibleCount = _kPageSize);
    });
    ref.listen(feedFilterProvider, (prev, next) {
      if (prev != next) setState(() => _visibleCount = _kPageSize);
    });

    final posts = allPosts.take(_visibleCount).toList();
    final hasMore = allPosts.length > _visibleCount;

    return Scaffold(
      appBar: const LiteratureAppBar(),
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _visibleCount = _kPageSize);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Following / Writers / hamburger + category chips ───────
            const SliverToBoxAdapter(child: FeedFilterRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // ── Posts ──────────────────────────────────────────────────
            if (posts.isEmpty)
              const SliverFillRemaining(child: _EmptyFeed())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final post = posts[i];
                    return PostCard(
                      post: post,
                      onContentTap: () {
                        if (post.bookId != null) {
                          final book = findBook(post.bookId!) ?? mockBooks.first;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => BookReaderScreen(book: book),
                          ));
                        } else {
                          context.push('/viewer/$i');
                        }
                      },
                    )
                        // Subtle fade+slide-in as cards enter — staggered by
                        // position (capped so it never feels sluggish on a
                        // long feed) rather than by global index.
                        .animate()
                        .fadeIn(
                          duration: 280.ms,
                          delay: 45.ms * (i % 6),
                        )
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOut,
                        );
                  },
                  childCount: posts.length,
                ),
              ),

            // ── Load-more / end indicator ──────────────────────────────
            SliverToBoxAdapter(
              child: hasMore
                  ? _LoadMoreButton(isDark: isDark, onTap: _loadMore)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '— end of feed —',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _LoadMoreButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Load more',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined,
              size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No posts in this category',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Try a different filter or follow more writers',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}
