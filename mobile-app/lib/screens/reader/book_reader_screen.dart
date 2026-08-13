import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/cover_image.dart';
import '../../utils/post_paginator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Flattened page — one physical, non-scrolling screen. Cover/title/back-cover
// book pages map to exactly one; introduction/chapter/glossary/references
// pages that don't fit one screen are auto-split into several, swipeable
// like any other page (see _buildFlatPages below).
// ─────────────────────────────────────────────────────────────────────────────

class _FlatPage {
  final BookPage source;
  final int subIndex;
  final int subTotal;
  final String bodyText;

  const _FlatPage({
    required this.source,
    required this.subIndex,
    required this.subTotal,
    required this.bodyText,
  });
}

/// Splits [pages] into physical, non-scrolling screens sized to fit
/// [bodySize] (the reader's full available area). Text-bearing pages
/// (introduction/chapter/glossary/references) that don't fit one screen
/// become several consecutive [_FlatPage]s; everything else is one.
///
/// Every sub-page of a given source is paginated against the same, slightly
/// reduced box (sized for the heading that only the first sub-page actually
/// shows) rather than a bigger box for the headless continuation pages —
/// simpler than tracking two box sizes, and it trades a little unused space
/// on later pages for a guarantee that nothing overflows.
List<_FlatPage> _buildFlatPages(
  List<BookPage> pages,
  Size bodySize,
  EdgeInsets safePadding,
) {
  final result = <_FlatPage>[];
  final contentWidth = bodySize.width - 56; // 28 padding each side
  final fullContentHeight =
      bodySize.height - safePadding.top - safePadding.bottom - 80 - 100;

  for (final page in pages) {
    switch (page.type) {
      case BookPageType.cover:
      case BookPageType.titlePage:
      case BookPageType.backCover:
        result.add(
          _FlatPage(source: page, subIndex: 0, subTotal: 1, bodyText: page.content),
        );
        break;

      case BookPageType.introduction:
      case BookPageType.glossary:
      case BookPageType.references:
      case BookPageType.chapter:
        final isChapter = page.type == BookPageType.chapter;
        final heading = page.type == BookPageType.introduction
            ? 'Introduction'
            : (page.chapterTitle ?? '');
        final headingStyle = isChapter
            ? GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, height: 1.35)
            : GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700);
        final bodyStyle = isChapter
            ? GoogleFonts.lora(fontSize: 16, height: 1.85)
            : (page.type == BookPageType.introduction
                ? GoogleFonts.lora(fontSize: 15, fontStyle: FontStyle.italic, height: 1.8)
                : GoogleFonts.lora(fontSize: 15, height: 1.8));

        final headingTp = TextPainter(
          text: TextSpan(text: heading, style: headingStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: contentWidth > 0 ? contentWidth : 1);
        final headingSpacing = isChapter ? 28.0 : (8.0 + 2.0 + 24.0);

        var availableHeight = fullContentHeight - headingTp.height - headingSpacing;
        if (availableHeight < 80) availableHeight = 80;

        final subPages = paginateTextToFit(
          page.content,
          bodyStyle,
          Size(contentWidth, availableHeight),
        );
        for (var i = 0; i < subPages.length; i++) {
          result.add(_FlatPage(
            source: page,
            subIndex: i,
            subTotal: subPages.length,
            bodyText: subPages[i],
          ));
        }
        break;
    }
  }
  return result;
}

/// Roman/arabic folio label per flattened page — every sub-page of a given
/// source shares that source's single label (a chapter split across three
/// screens is still "page 2", not three different numbers).
List<String?> _buildFlatLabels(List<_FlatPage> flat) {
  final labels = <String?>[];
  var introCount = 0;
  var arabicCount = 0;
  BookPage? lastSource;
  String? lastLabel;

  for (final fp in flat) {
    if (!identical(fp.source, lastSource)) {
      switch (fp.source.type) {
        case BookPageType.introduction:
          introCount++;
          lastLabel = fp.source.type.pageLabel(introIndex: introCount);
          break;
        case BookPageType.chapter:
        case BookPageType.glossary:
        case BookPageType.references:
          arabicCount++;
          lastLabel = fp.source.type.pageLabel(arabicIndex: arabicCount);
          break;
        default:
          lastLabel = null;
      }
      lastSource = fp.source;
    }
    labels.add(lastLabel);
  }
  return labels;
}

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _barsVisible = true;

  // Bookmarked indices into the flattened, auto-paginated page list —
  // persisted per-book on device.
  late Set<int> _bookmarks;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bookmarks = LocalStore.instance.loadBookBookmarks(widget.book.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferResume());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// If this book was previously left partway through, asks whether to pick
  /// up from there or start over — rather than silently jumping, which
  /// could be disorienting on a book the reader doesn't remember opening.
  Future<void> _maybeOfferResume() async {
    final saved = LocalStore.instance.loadBookLastPosition(widget.book.id);
    if (saved == null || saved <= 0 || !mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Continue reading?'),
        content: const Text(
          "You've already started this book. Pick up where you left off, or start from the beginning?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Start Over'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (resume == true && mounted && _pageController.hasClients) {
      _pageController.jumpToPage(saved);
      setState(() => _currentIndex = saved);
    }
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleBookmark(int currentIndex) {
    setState(() {
      if (!_bookmarks.remove(currentIndex)) {
        _bookmarks.add(currentIndex);
      }
    });
    LocalStore.instance.saveBookBookmarks(
      widget.book.id,
      _bookmarks.toList()..sort(),
    );
  }

  void _openBookmarks(List<_FlatPage> flat, List<String?> labels) {
    final sorted = _bookmarks.where((i) => i < flat.length).toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BookmarksSheet(
        flat: flat,
        labels: labels,
        indices: sorted,
        onJump: (i) {
          Navigator.pop(ctx);
          _goTo(i);
        },
        onRemove: (i) {
          setState(() => _bookmarks.remove(i));
          LocalStore.instance.saveBookBookmarks(
            widget.book.id,
            _bookmarks.toList()..sort(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0A06)
            : const Color(0xFFFAF7F2),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bodySize = Size(constraints.maxWidth, constraints.maxHeight);
            final safePadding = MediaQuery.of(context).padding;
            final flat = _buildFlatPages(widget.book.pages, bodySize, safePadding);
            final labels = _buildFlatLabels(flat);
            final total = flat.length;
            final currentIndex = _currentIndex.clamp(0, total - 1);
            final pageLabel = labels[currentIndex];
            final bookmarkCount = _bookmarks.where((i) => i < total).length;

            return GestureDetector(
              onTap: _toggleBars,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  // ── Page content ─────────────────────────────────────────
                  PageView.builder(
                    controller: _pageController,
                    itemCount: total,
                    onPageChanged: (i) {
                      setState(() => _currentIndex = i);
                      LocalStore.instance.saveBookLastPosition(
                        widget.book.id,
                        i,
                      );
                    },
                    itemBuilder: (ctx, i) => _buildFlatPage(flat[i], isDark),
                  ),

                  // ── Top bar ──────────────────────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    top: _barsVisible ? 0 : -100,
                    left: 0,
                    right: 0,
                    child: _TopBar(
                      title: widget.book.title,
                      isDark: isDark,
                      isBookmarked: _bookmarks.contains(currentIndex),
                      bookmarkCount: bookmarkCount,
                      onBack: () => Navigator.pop(context),
                      onToggleBookmark: () => _toggleBookmark(currentIndex),
                      onShowBookmarks: () => _openBookmarks(flat, labels),
                    ),
                  ),

                  // ── Page label — pinned bottom-left, over the page itself
                  // (not a separate bar below it). Shown while the bars are
                  // hidden (immersive reading).
                  if (pageLabel != null)
                    Positioned(
                      left: 16,
                      bottom: safePadding.bottom + 10,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _barsVisible ? 0 : 1,
                          child: _PageNumberBadge(label: pageLabel, isDark: isDark),
                        ),
                      ),
                    ),

                  // ── Page count — pinned bottom-right, always over the
                  // page itself rather than in a separate bar below it.
                  Positioned(
                    right: 16,
                    bottom: safePadding.bottom + 10,
                    child: IgnorePointer(
                      child: _PageNumberBadge(
                        label: '${currentIndex + 1} / $total',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlatPage(_FlatPage fp, bool isDark) {
    final page = fp.source;
    switch (page.type) {
      case BookPageType.cover:
        return _CoverPage(book: widget.book);
      case BookPageType.titlePage:
        return _TitlePage(book: widget.book, isDark: isDark);
      case BookPageType.backCover:
        return _BackCoverPage(book: widget.book, content: page.content);
      case BookPageType.introduction:
      case BookPageType.glossary:
      case BookPageType.references:
        return _TextPage(
          heading: fp.subIndex == 0
              ? (page.type == BookPageType.introduction
                  ? 'Introduction'
                  : (page.chapterTitle ?? ''))
              : null,
          content: fp.bodyText,
          isDark: isDark,
          isIntro: page.type == BookPageType.introduction,
        );
      case BookPageType.chapter:
        return _ChapterPage(
          chapterTitle: fp.subIndex == 0 ? (page.chapterTitle ?? '') : null,
          content: fp.bodyText,
          isDark: isDark,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final bool isBookmarked;
  final int bookmarkCount;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShowBookmarks;

  const _TopBar({
    required this.title,
    required this.isDark,
    required this.isBookmarked,
    required this.bookmarkCount,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onShowBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.surface.withValues(alpha: 0.95);
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      color: bg,
      padding: EdgeInsets.only(top: top, left: 4, right: 8, bottom: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: text),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ),
          // List saved bookmarks for this book.
          IconButton(
            tooltip: 'Bookmarks',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.bookmarks_outlined, size: 21, color: muted),
                if (bookmarkCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 14),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '$bookmarkCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onShowBookmarks,
          ),
          // Bookmark / unbookmark the current page.
          IconButton(
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this page',
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 22,
              color: isBookmarked ? accent : muted,
            ),
            onPressed: onToggleBookmark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page number badge — pinned to the bottom corners, always visible
// (independent of the top bar) like a printed book's folio.
// ─────────────────────────────────────────────────────────────────────────────

class _PageNumberBadge extends StatelessWidget {
  final String label;
  final bool isDark;

  const _PageNumberBadge({required this.label, required this.isDark});

  static bool _isRoman(String s) => RegExp(r'^[ivxlcdm]+$').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.55);
    final text = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
          fontStyle: _isRoman(label) ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bookmarks sheet — lists saved pages for this book
// ─────────────────────────────────────────────────────────────────────────────

class _BookmarksSheet extends StatelessWidget {
  final List<_FlatPage> flat;
  final List<String?> labels;
  final List<int> indices;
  final ValueChanged<int> onJump;
  final ValueChanged<int> onRemove;

  const _BookmarksSheet({
    required this.flat,
    required this.labels,
    required this.indices,
    required this.onJump,
    required this.onRemove,
  });

  String _sectionLabel(BookPage page) => switch (page.type) {
    BookPageType.cover => 'Cover',
    BookPageType.titlePage => 'Title Page',
    BookPageType.introduction => 'Introduction',
    BookPageType.chapter => page.chapterTitle ?? 'Chapter',
    BookPageType.glossary => 'Glossary',
    BookPageType.references => 'References',
    BookPageType.backCover => 'Back Cover',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.bookmarks_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Bookmarks',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ],
              ),
            ),
            if (indices.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Text(
                  'No bookmarks yet. Tap the bookmark icon while reading to save a page.',
                  style: GoogleFonts.lato(fontSize: 13, color: muted),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: indices.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                  itemBuilder: (ctx, i) {
                    final flatIndex = indices[i];
                    final fp = flat[flatIndex];
                    final label = labels[flatIndex];
                    final sectionText = fp.subTotal > 1
                        ? '${_sectionLabel(fp.source)} (${fp.subIndex + 1}/${fp.subTotal})'
                        : _sectionLabel(fp.source);
                    return ListTile(
                      onTap: () => onJump(flatIndex),
                      leading: Icon(
                        Icons.bookmark_rounded,
                        color: accent,
                        size: 20,
                      ),
                      title: Text(
                        sectionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                      subtitle: label != null
                          ? Text(
                              'Page $label',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: muted,
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: muted),
                        onPressed: () => onRemove(flatIndex),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover page
// ─────────────────────────────────────────────────────────────────────────────

class _CoverPage extends StatelessWidget {
  final Book book;
  const _CoverPage({required this.book});

  @override
  Widget build(BuildContext context) {
    final coverImage = coverImageFile(book.coverImagePath);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            book.coverColor,
            Color.lerp(book.coverColor, Colors.black, 0.5)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Seller-picked cover photo, if any, full-bleed behind the text.
          if (coverImage != null)
            Positioned.fill(child: Image.file(coverImage, fit: BoxFit.cover)),
          // Scrim so the title/author stay legible over a photo — a plain
          // gradient background needs no extra darkening, so this is a no-op
          // (transparent) when there's no photo.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: coverImage != null
                      ? [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.65),
                        ]
                      : [Colors.transparent, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          _coverContent(context),
        ],
      ),
    );
  }

  Widget _coverContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Decorative line
            Container(
              height: 2,
              color: book.coverTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 28),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: book.coverTextColor,
                height: 1.25,
                letterSpacing: 0.5,
              ),
            ),
            if (book.subtitle.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                book.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: book.coverTextColor.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              height: 2,
              color: book.coverTextColor.withValues(alpha: 0.5),
            ),
            const Spacer(flex: 2),
            Text(
              book.authorName,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: book.coverTextColor.withValues(alpha: 0.85),
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // Swipe hint
            Column(
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: book.coverTextColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  'swipe to open',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: book.coverTextColor.withValues(alpha: 0.4),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title page
// ─────────────────────────────────────────────────────────────────────────────

class _TitlePage extends StatelessWidget {
  final Book book;
  final bool isDark;
  const _TitlePage({required this.book, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.3,
              ),
            ),
            if (book.subtitle.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                book.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: muted,
                  height: 1.5,
                ),
              ),
            ],
            const Spacer(flex: 2),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 20),
            Text(
              book.authorName,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: text,
                letterSpacing: 1,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Introduction / Glossary / References — a single, non-scrolling screen
// ─────────────────────────────────────────────────────────────────────────────

class _TextPage extends StatelessWidget {
  final String? heading;
  final String content;
  final bool isDark;
  final bool isIntro;

  const _TextPage({
    required this.heading,
    required this.content,
    required this.isDark,
    this.isIntro = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final body = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(
                heading!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 40, height: 2, color: accent),
              const SizedBox(height: 24),
            ],
            Text(
              content,
              style: isIntro
                  ? GoogleFonts.lora(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: body,
                      height: 1.8,
                    )
                  : GoogleFonts.lora(fontSize: 15, color: body, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter page — a single, non-scrolling screen
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterPage extends StatelessWidget {
  final String? chapterTitle;
  final String content;
  final bool isDark;

  const _ChapterPage({
    required this.chapterTitle,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final body = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chapterTitle != null) ...[
              Text(
                chapterTitle!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: text,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
            ],
            Text(
              content,
              style: GoogleFonts.lora(fontSize: 16, color: body, height: 1.85),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back cover page
// ─────────────────────────────────────────────────────────────────────────────

class _BackCoverPage extends StatelessWidget {
  final Book book;
  final String content;
  const _BackCoverPage({required this.book, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(book.coverColor, Colors.black, 0.5)!,
            book.coverColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 80, 36, 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                content,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: book.coverTextColor.withValues(alpha: 0.85),
                  height: 1.7,
                ),
              ),
              const Spacer(flex: 3),
              Text(
                book.authorName,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: book.coverTextColor.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
