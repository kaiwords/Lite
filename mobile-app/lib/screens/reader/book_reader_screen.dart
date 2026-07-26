import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book.dart';
import '../../theme/app_theme.dart';

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

  // Pre-computed page labels
  late final List<String?> _labels;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _labels = _buildLabels(widget.book.pages);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Walk through pages and assign sequential counters per type
  static List<String?> _buildLabels(List<BookPage> pages) {
    int introCount = 0;
    int arabicCount = 0;
    return pages.map((p) {
      switch (p.type) {
        case BookPageType.introduction:
          introCount++;
          return p.type.pageLabel(introIndex: introCount);
        case BookPageType.chapter:
        case BookPageType.glossary:
        case BookPageType.references:
          arabicCount++;
          return p.type.pageLabel(arabicIndex: arabicCount);
        default:
          return null;
      }
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = widget.book.pages;
    final total = pages.length;
    final pageLabel = _labels[_currentIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0A06)
            : const Color(0xFFFAF7F2),
        body: GestureDetector(
          onTap: _toggleBars,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // ── Page content ─────────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (ctx, i) => _buildPage(ctx, pages[i], isDark),
              ),

              // ── Top bar ──────────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                top: _barsVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: _TopBar(
                  title: widget.book.title,
                  isDark: isDark,
                  onBack: () => Navigator.pop(context),
                ),
              ),

              // ── Bottom bar ───────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                bottom: _barsVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: _BottomBar(
                  currentIndex: _currentIndex,
                  total: total,
                  pageLabel: pageLabel,
                  isDark: isDark,
                  pages: pages,
                  onJump: _goTo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, BookPage page, bool isDark) {
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
          heading: page.type == BookPageType.introduction
              ? 'Introduction'
              : (page.chapterTitle ?? ''),
          content: page.content,
          isDark: isDark,
          isIntro: page.type == BookPageType.introduction,
        );
      case BookPageType.chapter:
        return _ChapterPage(
          chapterTitle: page.chapterTitle ?? '',
          content: page.content,
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
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.surface.withValues(alpha: 0.95);
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      color: bg,
      padding: EdgeInsets.only(top: top, left: 4, right: 16, bottom: 8),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar (page nav)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final String? pageLabel;
  final bool isDark;
  final List<BookPage> pages;
  final ValueChanged<int> onJump;

  const _BottomBar({
    required this.currentIndex,
    required this.total,
    required this.pageLabel,
    required this.isDark,
    required this.pages,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.surface.withValues(alpha: 0.95);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: bg,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: accent,
              inactiveTrackColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (total - 1).toDouble(),
              onChanged: (v) => onJump(v.round()),
            ),
          ),

          // Page label row
          Row(
            children: [
              // Section name — chapter titles are user-authored (via the
              // sell-flow chapter editor) and unbounded in length, so this
              // must ellipsize instead of forcing the row to overflow.
              Expanded(
                child: Text(
                  _sectionLabel(pages[currentIndex]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 11, color: muted),
                ),
              ),

              // Page number
              if (pageLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  pageLabel!,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: muted,
                    fontStyle: _isRoman(pageLabel!)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],

              // Chapter count indicator
              const SizedBox(width: 8),
              Text(
                '${currentIndex + 1} / $total',
                style: GoogleFonts.lato(fontSize: 11, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isRoman(String s) => RegExp(r'^[ivxlcdm]+$').hasMatch(s);

  String _sectionLabel(BookPage page) => switch (page.type) {
    BookPageType.cover => 'Cover',
    BookPageType.titlePage => 'Title Page',
    BookPageType.introduction => 'Introduction',
    BookPageType.chapter => page.chapterTitle ?? 'Chapter',
    BookPageType.glossary => 'Glossary',
    BookPageType.references => 'References',
    BookPageType.backCover => 'Back Cover',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover page
// ─────────────────────────────────────────────────────────────────────────────

class _CoverPage extends StatelessWidget {
  final Book book;
  const _CoverPage({required this.book});

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(
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
// Introduction / Glossary / References — scrollable text page
// ─────────────────────────────────────────────────────────────────────────────

class _TextPage extends StatelessWidget {
  final String heading;
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 40, height: 2, color: accent),
            const SizedBox(height: 24),
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
// Chapter page — scrollable prose
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterPage extends StatelessWidget {
  final String chapterTitle;
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapterTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
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
