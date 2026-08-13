import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/book.dart';
import '../../models/post.dart';
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
  // Covers the whole top chrome now: the "Literature" bar (+ create/search/
  // message) and the Following/Writers + category chips row underneath.
  bool _showTopChrome = true;
  // Once the reader has opened any post, the chrome stays hidden until they
  // pull-to-refresh or scroll back to the very top — opening a post is
  // treated as "I'm reading now", not just a momentary scroll.
  bool _hasOpenedPost = false;

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
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }

    // Back at the top resets everything, including the "opened a post"
    // latch — same reset point as pull-to-refresh.
    if (pos.pixels <= 0) {
      if (_hasOpenedPost || !_showTopChrome) {
        setState(() {
          _hasOpenedPost = false;
          _showTopChrome = true;
        });
      }
      return;
    }

    // Any scroll away from the top hides the chrome — scrolling back up
    // doesn't bring it back, only reaching the very top (or refresh) does.
    if (_showTopChrome) setState(() => _showTopChrome = false);
  }

  void _loadMore() {
    final total = ref.read(filteredPostsProvider).length;
    if (_visibleCount < total) {
      setState(
          () => _visibleCount = (_visibleCount + _kPageSize).clamp(0, total));
    }
  }

  // Tapping the Home tab while already on Home scrolls back to the top and
  // refreshes the feed, same as pull-to-refresh — mirrors how most feed
  // apps treat a second tap on the current tab.
  Future<void> _refreshFromTop() async {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    setState(() {
      _visibleCount = _kPageSize;
      _hasOpenedPost = false;
      _showTopChrome = true;
    });
  }

  void _openPost(Post post, int index) {
    setState(() {
      _hasOpenedPost = true;
      _showTopChrome = false;
    });
    if (post.bookId != null) {
      final book = findBook(post.bookId!);
      if (book == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This book is not available yet')),
        );
        return;
      }
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)));
    } else {
      context.push('/viewer/$index');
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
      bottomNavigationBar: LiteratureBottomNavBar(
        currentIndex: 0,
        onSameTabTap: _refreshFromTop,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
          // ── Top chrome: app bar + Following/Writers + category chips ───
          // Lives outside the scroll view; collapses as one unit on
          // scroll-down and reappears on scroll-up (see _onScroll).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: !_showTopChrome
                ? const SizedBox.shrink()
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiteratureAppBar(),
                      FeedFilterRow(),
                    ],
                  ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _visibleCount = _kPageSize;
                  _hasOpenedPost = false;
                  _showTopChrome = true;
                });
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Posts ──────────────────────────────────────────────
                  if (posts.isEmpty)
                    const SliverFillRemaining(child: _EmptyFeed())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final post = posts[i];
                          return PostCard(
                            post: post,
                            onContentTap: () => _openPost(post, i),
                          )
                              // Subtle fade+slide-in as cards enter — staggered
                              // by position (capped so it never feels sluggish
                              // on a long feed) rather than by global index.
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

                  // ── Load-more / end indicator ─────────────────────────
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
