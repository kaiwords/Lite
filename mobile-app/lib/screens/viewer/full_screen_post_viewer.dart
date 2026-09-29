import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_paginator.dart';
import '../../utils/rich_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen — immersive, chrome-free reading view, book-style: no scrolling and
// no swiping vertically at all — only a static, page-by-page horizontal
// swipe through this one post's own content (see _PostFullPage below). No
// back button, no author row, no engagement footer beyond a bookmark
// toggle — the rest lives on the post card back on Home. A single tap
// anywhere closes the viewer and returns to Home; to read a different post,
// close and tap it from there.
// ─────────────────────────────────────────────────────────────────────────────

class FullScreenPostViewer extends ConsumerWidget {
  final int initialIndex;
  const FullScreenPostViewer({super.key, required this.initialIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(filteredPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0A07) : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: (initialIndex < 0 || initialIndex >= posts.length)
            ? const _EmptyState()
            : _PostFullPage(post: posts[initialIndex], isDark: isDark),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No posts in this category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One post — title + horizontal, static page swiper (book-style: no
// scrolling, each swipe snaps to a whole page). Tap anywhere closes the
// viewer. The last page you were on is remembered per post and silently
// restored as the starting page next time you open it — swiping back to
// page one is one gesture away if you'd rather start over.
// ─────────────────────────────────────────────────────────────────────────────

class _PostFullPage extends ConsumerStatefulWidget {
  final Post post;
  final bool isDark;

  const _PostFullPage({required this.post, required this.isDark});

  @override
  ConsumerState<_PostFullPage> createState() => _PostFullPageState();
}

/// One page of the reading view: its running-header title, body text, and
/// (when the writer turned page numbers on) the printed number at the foot
/// of the page. The contents page has no text of its own — it lists the
/// other pages instead.
class _ViewerPage {
  final String? title;
  final String text;
  final int? number;
  final bool isContents;
  const _ViewerPage({
    required this.title,
    this.text = '',
    this.number,
    this.isContents = false,
  });
}

/// Vertical space reserved at the foot of a page for its printed number.
const double _pageNumberFooterHeight = 26;

class _PostFullPageState extends ConsumerState<_PostFullPage> {
  final PageController _hController = PageController();
  late int _pageIndex;
  List<_ViewerPage> _pages = const [];
  Size? _bodySize;
  Size? _pendingSize;
  Timer? _reflowTimer;

  bool get _isPoetic =>
      widget.post.category == ContentCategory.poem ||
      widget.post.category == ContentCategory.haiku;

  TextStyle get _bodyStyle => _isPoetic
      ? AppFonts.reading(fontSize: 18, fontStyle: FontStyle.italic, height: 2.0)
      : AppFonts.reading(fontSize: 16, height: 1.85);

  @override
  void initState() {
    super.initState();
    _pageIndex = LocalStore.instance.loadPostLastPageIndex(widget.post.id) ?? 0;
  }

  @override
  void dispose() {
    _reflowTimer?.cancel();
    _hController.dispose();
    super.dispose();
  }

  List<_ViewerPage> _computePages(Size bodySize) {
    final post = widget.post;
    final numbered = post.showPageNumbers;

    List<String> texts;
    List<String?> titles;
    // Author-defined pages (added while writing) are shown as-is, one per
    // swipe, ahead of any auto-pagination of a single long page. Page one
    // carries the post's main title; each authored page carries its own
    // (which may be null if the writer chose to hide it).
    if (post.pages.isNotEmpty) {
      texts = [post.content, ...post.pages.map((p) => p.content)];
      titles = [post.title, ...post.pages.map((p) => p.title)];
    } else if (post.category == ContentCategory.joke) {
      texts = [post.content.trim()];
      titles = [post.title];
    } else if (_isPoetic) {
      texts = paginatePost(post); // one stanza per page
      titles = List.filled(texts.length, post.title);
    } else {
      // Printed page numbers take a strip at the foot of each page, so the
      // text is flowed into a correspondingly shorter page.
      final fitSize = numbered
          ? Size(bodySize.width, bodySize.height - _pageNumberFooterHeight)
          : bodySize;
      texts = paginateTextToFit(post.content, _bodyStyle, fitSize);
      titles = List.filled(texts.length, post.title);
    }

    final pages = [
      // Numbering is automatic: page one is 1, and every page after is one
      // higher than the page before it.
      for (var i = 0; i < texts.length; i++)
        _ViewerPage(
          title: titles[i],
          text: texts[i],
          number: numbered ? i + 1 : null,
        ),
    ];
    if (post.showTableOfContents && post.pages.isNotEmpty) {
      pages.insert(0, const _ViewerPage(title: 'Contents', isContents: true));
    }
    return pages;
  }

  /// The title to show for the page currently in view.
  String? get _currentPageTitle {
    if (_pages.isEmpty) return widget.post.title;
    return _pages[_pageIndex.clamp(0, _pages.length - 1)].title;
  }

  /// From the contents page: turn to the given page of the post's text
  /// (0-based over the text pages, which sit after the contents page).
  void _openFromContents(int textPageIndex) {
    _hController.animateToPage(
      textPageIndex + 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _applyPages(Size size) {
    final newPages = _computePages(size);
    final idx = _pageIndex.clamp(0, newPages.length - 1);
    setState(() {
      _bodySize = size;
      _pages = newPages;
      _pageIndex = idx;
    });
    if (_hController.hasClients && (_hController.page ?? 0).round() != idx) {
      _hController.jumpToPage(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor = widget.isDark
        ? AppColors.darkTextMuted
        : AppColors.textMuted;
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.pop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title — _PostHeader itself caps at 2 lines with an ellipsis,
              // so a long title never needs to scroll or overflow.
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 44, 8),
                child: _PostHeader(
                  title: _currentPageTitle,
                  isDark: widget.isDark,
                ),
              ),

              // Paged body — measured so overflow flows to the next page
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth - 52, // 26 padding each side
                      constraints.maxHeight - 36, // 20 top + 16 bottom
                    );
                    if (_bodySize != size) {
                      if (_bodySize == null) {
                        // First layout → paginate immediately.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _applyPages(size);
                        });
                      } else {
                        // Size changed (e.g. rotation) → debounce so we only
                        // re-paginate once it settles.
                        _pendingSize = size;
                        _reflowTimer?.cancel();
                        _reflowTimer = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            if (mounted) _applyPages(_pendingSize!);
                          },
                        );
                      }
                    }
                    if (_pages.isEmpty) return const SizedBox.shrink();
                    return BookPageView(
                      controller: _hController,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        setState(() => _pageIndex = i);
                        LocalStore.instance.savePostLastPageIndex(
                          widget.post.id,
                          i,
                        );
                      },
                      itemBuilder: (_, i) {
                        final page = _pages[i];
                        if (page.isContents) {
                          return _ContentsPage(
                            post: widget.post,
                            isDark: widget.isDark,
                            onEntryTap: _openFromContents,
                          );
                        }
                        return _BodyPage(
                          text: page.text,
                          pageNumber: page.number,
                          isPoetic: _isPoetic,
                          isDark: widget.isDark,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Bookmark toggle — the same favourite/bookmark feature already on
        // the feed's post card (post.isFavourited / toggleFavourite), also
        // reachable from this immersive reading view.
        Positioned(
          top: 4,
          right: 4,
          child: SafeArea(
            bottom: false,
            child: IconButton(
              tooltip: widget.post.isFavourited
                  ? 'Remove bookmark'
                  : 'Bookmark this post',
              icon: Icon(
                widget.post.isFavourited
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: widget.post.isFavourited
                    ? AppColors.bookmark
                    : mutedColor,
              ),
              onPressed: () => ref
                  .read(postsNotifierProvider.notifier)
                  .toggleFavourite(widget.post.id),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Running header — just the title
// ─────────────────────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  final String? title;
  final bool isDark;

  const _PostHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Text(
      title!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.display(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: titleColor,
        height: 1.25,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body page — the text for one horizontal page
// ─────────────────────────────────────────────────────────────────────────────

class _BodyPage extends StatelessWidget {
  final String text;
  final int? pageNumber;
  final bool isPoetic;
  final bool isDark;

  const _BodyPage({
    required this.text,
    required this.pageNumber,
    required this.isPoetic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final bodyStyle = isPoetic
        ? AppFonts.reading(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            height: 2.0,
            color: bodyColor,
          )
        : AppFonts.reading(fontSize: 16, height: 1.85, color: bodyColor);

    final body = Text.rich(
      TextSpan(
        children: buildFormattedSpans(
          text,
          bodyStyle,
          accent: isDark ? AppColors.darkAccent : AppColors.accent,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      child: pageNumber == null
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: body),
                // The folio: the page's printed number, centered at the foot
                // of the page like a printed book's.
                SizedBox(
                  height: _pageNumberFooterHeight,
                  child: Center(
                    child: Text(
                      '$pageNumber',
                      style: AppFonts.ui(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contents page — lists every page of the post; tapping an entry turns
// straight to that page.
// ─────────────────────────────────────────────────────────────────────────────

class _ContentsPage extends StatelessWidget {
  final Post post;
  final bool isDark;
  final void Function(int textPageIndex) onEntryTap;

  const _ContentsPage({
    required this.post,
    required this.isDark,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    // Entry k is text page k: the post's main title/content first, then
    // each authored page (falling back to its book-style number when the
    // writer hid its title).
    final labels = [
      post.title,
      for (var i = 0; i < post.pages.length; i++)
        post.pages[i].title ?? 'Page ${i + 2}',
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      itemCount: labels.length,
      itemBuilder: (context, i) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onEntryTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  labels[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.reading(
                    fontSize: 16,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (post.showPageNumbers)
                Text(
                  '${i + 1}',
                  style: AppFonts.ui(fontSize: 13, color: mutedColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
