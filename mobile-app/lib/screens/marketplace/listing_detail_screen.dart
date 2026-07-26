import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/book.dart';
import '../../models/marketplace.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/marketplace_lookup.dart';
import '../../utils/post_paginator.dart';
import '../../widgets/share_sheet.dart';
import '../audio/audiobook_player_screen.dart';
import '../reader/book_reader_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock reviews
// ─────────────────────────────────────────────────────────────────────────────

class _Review {
  final String reviewer;
  final double rating;
  final String body;
  final int daysAgo;
  const _Review(this.reviewer, this.rating, this.body, this.daysAgo);
}

const _mockReviews = [
  _Review(
    'luna_reads',
    5.0,
    'Absolutely stunning. Read it in one sitting and cried twice. The prose is unlike anything I\'ve encountered this year.',
    2,
  ),
  _Review(
    'ink_and_fire',
    4.0,
    'Beautifully written, though the pacing drags slightly in the middle. The final third more than makes up for it.',
    8,
  ),
  _Review(
    'priya_quill',
    5.0,
    'This is the kind of book that makes you want to write. Finished it and immediately started from page one again.',
    14,
  ),
  _Review(
    'sarah_bookclub',
    4.5,
    'Our book club picked this and it sparked the best discussion we\'ve had in years. Highly recommended for group reads.',
    21,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myListings = ref.watch(myListingsProvider);
    final purchases = ref.watch(purchasesProvider);
    // Watched (not just read) so this screen rebuilds — and stops 404ing —
    // once the live Supabase catalogue loads.
    final catalogue = ref.watch(marketplaceListingsProvider);

    // Resolve across the full browsable catalogue (seeded + user-created +
    // Supabase-loaded listings) and the user's purchase history.
    final listing = findListingById(ref, listingId);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inCart = ref.watch(cartProvider).any((l) => l.id == listing.id);
    final owned = purchases.any((p) => p.listing.id == listing.id);
    final isMine = myListings.any((l) => l.id == listing.id);
    final canAccess = owned || isMine;
    final byAuthor = catalogue
        .where((l) => l.authorName == listing.authorName && l.id != listing.id)
        .toList();

    void openRead() {
      if (listing.ebookChapters.isNotEmpty) {
        // Chapter-built books get proper chapter navigation by reusing the
        // same paginated reader as the curated catalogue's Book/BookPage model.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookReaderScreen(book: _bookFromListing(listing)),
          ),
        );
        return;
      }
      final content = listing.ebookContent;
      if (content != null && content.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                _EbookReadScreen(title: listing.title, content: content),
          ),
        );
      } else if (listing.pdfFileName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${listing.pdfFileName}…'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    void openListen() {
      if (listing.audioVolumes.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AudiobookPlayerScreen(listing: listing),
          ),
        );
      } else if (listing.linkedPostId != null) {
        context.push('/audio', extra: listing.linkedPostId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playback is coming soon.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero cover + app bar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => showShareSheet(
                  context,
                  title: listing.title,
                  link: 'https://literature.app/marketplace/${listing.id}',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _CoverHero(listing: listing),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + category badges
                  Row(
                    children: [
                      _Badge(
                        label: listing.type.label,
                        color: listing.type.badgeColor,
                      ),
                      if (listing.contentCategory != null) ...[
                        const SizedBox(width: 8),
                        _Badge(
                          label:
                              '${listing.contentCategory!.emoji} ${listing.contentCategory!.label}',
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    listing.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final userId = _authorId(listing.authorName);
                            if (userId != null) context.push('/user/$userId');
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.surfaceVariant,
                                child: Text(
                                  listing.authorName.isEmpty
                                      ? '?'
                                      : listing.authorName[0].toUpperCase(),
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  listing.authorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _AuthorFollowChip(
                        authorName: listing.authorName,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating row
                  _RatingRow(listing: listing, isDark: isDark),
                  const SizedBox(height: 20),

                  // Price + cart / Read·Listen
                  _PriceCartRow(
                    listing: listing,
                    inCart: inCart,
                    isDark: isDark,
                    canAccess: canAccess,
                    accessLabel: owned ? 'In your library' : 'Your listing',
                    onRead: openRead,
                    onListen: openListen,
                  ),
                  const SizedBox(height: 28),

                  // Divider
                  Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                  const SizedBox(height: 20),

                  // About
                  Text(
                    'About this book',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  if (listing.description.isNotEmpty)
                    Text(
                      listing.description,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        height: 1.75,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Contents — what the author uploaded / wrote
                  if (_hasUploadedContent(listing)) ...[
                    Text(
                      'Contents',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    _ContentInfo(listing: listing, isDark: isDark),
                    const SizedBox(height: 28),
                  ],

                  // Rating breakdown
                  Text(
                    'Ratings & Reviews',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _RatingBreakdown(listing: listing, isDark: isDark),
                  const SizedBox(height: 16),

                  // Reviews
                  ..._mockReviews.map(
                    (r) => _ReviewCard(review: r, isDark: isDark),
                  ),
                  const SizedBox(height: 28),

                  // More by author
                  if (byAuthor.isNotEmpty) ...[
                    Text(
                      'More by ${listing.authorName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      // A couple of extra pixels of headroom beyond the
                      // card's nominal content height (cover + 2-line title
                      // + price) — the two-line title was landing right at
                      // the edge of the old 160px budget and overflowing by
                      // a few pixels depending on font metrics.
                      height: 172,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: byAuthor.length,
                        separatorBuilder: (_, idx) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _AuthorListingCard(
                          listing: byAuthor[i],
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps known author names to user IDs for profile navigation.
  String? _authorId(String name) => const {
    'Eleanor Voss': 'u1',
    'Marcus Osei': 'u2',
    'Priya Nair': 'u3',
    'Javier Morales': 'u4',
  }[name];
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover hero
// ─────────────────────────────────────────────────────────────────────────────

class _CoverHero extends StatelessWidget {
  final MarketplaceListing listing;
  const _CoverHero({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            listing.type.badgeColor,
            listing.type.badgeColor.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern (subtle large initial)
          Positioned.fill(
            child: Center(
              child: Text(
                listing.title.isEmpty ? '?' : listing.title[0],
                style: GoogleFonts.playfairDisplay(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          // Type icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(listing.type.icon, size: 40, color: Colors.white),
            ),
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
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
// Rating row (stars + count)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _RatingRow({required this.listing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(
      children: [
        // Stars
        Row(
          children: List.generate(5, (i) {
            final full = i < listing.rating.floor();
            final half =
                !full && i < listing.rating && (listing.rating - i) >= 0.5;
            return Icon(
              full
                  ? Icons.star_rounded
                  : half
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
              size: 20,
              color: const Color(0xFFF4C430),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          listing.rating.toStringAsFixed(1),
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '(${listing.reviewCount} reviews)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price + cart button
// ─────────────────────────────────────────────────────────────────────────────

class _PriceCartRow extends ConsumerWidget {
  final MarketplaceListing listing;
  final bool inCart;
  final bool isDark;
  final bool canAccess;
  final String accessLabel;
  final VoidCallback onRead;
  final VoidCallback onListen;
  const _PriceCartRow({
    required this.listing,
    required this.inCart,
    required this.isDark,
    required this.canAccess,
    required this.accessLabel,
    required this.onRead,
    required this.onListen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Owned (purchased) or authored → Read / Listen instead of Add to Cart.
    if (canAccess) {
      final isEbook = listing.type == ListingType.ebook;
      final isAudio = listing.type == ListingType.audio;
      final readAvailable =
          (listing.ebookContent?.isNotEmpty ?? false) ||
          listing.ebookChapters.isNotEmpty ||
          listing.pdfFileName != null;
      final listenAvailable =
          listing.audioVolumes.isNotEmpty || listing.linkedPostId != null;

      Widget? action;
      if (isEbook) {
        action = _PrimaryAction(
          label: 'Read',
          icon: Icons.menu_book_rounded,
          onTap: onRead,
          isDark: isDark,
          // Content isn't actually wired up yet for this listing — show a
          // visibly muted "Soon" button instead of one that looks fully
          // functional but silently does nothing useful.
          comingSoon: !readAvailable,
        );
      } else if (isAudio) {
        action = _PrimaryAction(
          label: 'Listen',
          icon: Icons.headphones_rounded,
          onTap: onListen,
          isDark: isDark,
          comingSoon: !listenAvailable,
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      accessLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (action != null) Flexible(flex: 3, child: action),
        ],
      );
    }

    // accentOnFill (darker than accent) keeps the white label at WCAG AA
    // contrast for the solid "Add to Cart" / "Buy Now" fills.
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;
    final outline = isDark ? AppColors.darkAccent : AppColors.accent;

    void buyNow() {
      ref.read(purchasesProvider.notifier).buyNow(listing);
      // The listing is now owned — no need for it to linger in the cart too.
      if (inCart) ref.read(cartProvider.notifier).remove(listing.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${listing.title}" purchased! Check your Library.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.price,
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Add to cart / remove
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (inCart) {
                    ref.read(cartProvider.notifier).remove(listing.id);
                  } else {
                    ref.read(cartProvider.notifier).add(listing);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${listing.title}" added to cart'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: inCart ? Colors.transparent : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: outline, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inCart
                            ? Icons.check_rounded
                            : Icons.shopping_cart_outlined,
                        size: 18,
                        color: outline,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          inCart ? 'In Cart' : 'Add to Cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Buy Now — completes the purchase immediately, no cart required.
            Expanded(
              child: GestureDetector(
                onTap: buyNow,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'Buy Now',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool comingSoon;
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;
    final mutedBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final mutedFg = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: comingSoon ? mutedBg : fill,
          borderRadius: BorderRadius.circular(28),
          border: comingSoon ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: comingSoon ? mutedFg : Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: comingSoon ? mutedFg : Colors.white,
                ),
              ),
            ),
            if (comingSoon) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SOON',
                  style: GoogleFonts.lato(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: mutedFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contents — surfaces the uploaded PDF / written book / audio volumes
// ─────────────────────────────────────────────────────────────────────────────

bool _hasUploadedContent(MarketplaceListing l) =>
    l.pdfFileName != null ||
    (l.ebookContent?.isNotEmpty ?? false) ||
    l.ebookChapters.isNotEmpty ||
    l.audioVolumes.isNotEmpty;

/// Converts a chapter-built listing into a transient [Book] so it can be read
/// with [BookReaderScreen]'s proper chapter navigation/pagination instead of
/// building a separate reading UI just for marketplace listings.
Book _bookFromListing(MarketplaceListing listing) {
  final coverColor = listing.genre?.colors.first ?? listing.type.badgeColor;
  return Book(
    id: listing.id,
    title: listing.title,
    authorName: listing.authorName,
    coverColor: coverColor,
    coverTextColor: Colors.white,
    pages: [
      const BookPage(type: BookPageType.cover),
      BookPage(
        type: BookPageType.titlePage,
        content: '${listing.title}\n\n${listing.authorName}',
      ),
      for (final chapter in listing.ebookChapters)
        BookPage(
          type: BookPageType.chapter,
          chapterTitle: chapter.title,
          content: chapter.content,
        ),
    ],
  );
}

class _ContentInfo extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _ContentInfo({required this.listing, required this.isDark});

  int _wordCount(String s) {
    final t = s.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (listing.pdfFileName != null) {
      rows.add(
        _ContentRow(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: const Color(0xFFC0392B),
          title: 'PDF document',
          subtitle: listing.pdfFileName!,
          isDark: isDark,
        ),
      );
    }
    if (listing.ebookChapters.isNotEmpty) {
      // Chapters take precedence over the legacy flat blob — one row per
      // chapter, mirroring the audio-volume rows below.
      for (var i = 0; i < listing.ebookChapters.length; i++) {
        final chapter = listing.ebookChapters[i];
        final wc = _wordCount(chapter.content);
        rows.add(
          _ContentRow(
            icon: Icons.menu_book_rounded,
            iconColor: ListingType.ebook.badgeColor,
            title: chapter.title.isEmpty ? 'Chapter ${i + 1}' : chapter.title,
            subtitle: '$wc ${wc == 1 ? 'word' : 'words'}',
            isDark: isDark,
          ),
        );
      }
    } else if (listing.ebookContent?.isNotEmpty ?? false) {
      final wc = _wordCount(listing.ebookContent!);
      rows.add(
        _ContentRow(
          icon: Icons.menu_book_rounded,
          iconColor: ListingType.ebook.badgeColor,
          title: 'Readable e-book',
          subtitle: '$wc ${wc == 1 ? 'word' : 'words'}',
          isDark: isDark,
        ),
      );
    }
    for (var i = 0; i < listing.audioVolumes.length; i++) {
      final volume = listing.audioVolumes[i];
      rows.add(
        _ContentRow(
          icon: Icons.audiotrack_rounded,
          iconColor: ListingType.audio.badgeColor,
          title: volume.title.isEmpty ? 'Volume ${i + 1}' : volume.title,
          subtitle: volume.fileName,
          isDark: isDark,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  const _ContentRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reader for written e-books — paginated to fit the screen, markdown-rendered
// (**bold**, _italic_, <u>underline</u>, ~~strike~~, "# " heading, "- " bullet,
// "> " quote), swipe left/right to turn pages.
// ─────────────────────────────────────────────────────────────────────────────

class _EbookReadScreen extends StatefulWidget {
  final String title;
  final String content;
  const _EbookReadScreen({required this.title, required this.content});

  @override
  State<_EbookReadScreen> createState() => _EbookReadScreenState();
}

class _EbookReadScreenState extends State<_EbookReadScreen> {
  final PageController _controller = PageController();
  List<String> _pages = const [];
  Size? _size;
  int _index = 0;

  static const _hPad = 24.0;
  static const _vPad = 24.0;

  TextStyle get _baseStyle => GoogleFonts.lora(fontSize: 17, height: 1.7);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _paginate(Size size) {
    final pages = paginateTextToFit(widget.content, _baseStyle, size);
    if (!mounted) return;
    setState(() {
      _size = size;
      _pages = pages;
      if (_index >= pages.length) _index = pages.length - 1;
      if (_index < 0) _index = 0;
    });
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, _pages.length - 1);
    if (next == _index) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Inline markdown → spans ────────────────────────────────────────────────
  TextStyle _styleFor(String open, TextStyle base) {
    switch (open) {
      case '**':
        return base.copyWith(fontWeight: FontWeight.w700);
      case '~~':
        return base.copyWith(decoration: TextDecoration.lineThrough);
      case '<u>':
        return base.copyWith(decoration: TextDecoration.underline);
      case '_':
        return base.copyWith(fontStyle: FontStyle.italic);
      default:
        return base;
    }
  }

  List<InlineSpan> _parseInline(String s, TextStyle base) {
    if (s.isEmpty) return const [];
    const opens = ['**', '~~', '<u>', '_'];
    var bestPos = -1;
    String? bestOpen;
    for (final o in opens) {
      final p = s.indexOf(o);
      if (p != -1 && (bestPos == -1 || p < bestPos)) {
        bestPos = p;
        bestOpen = o;
      }
    }
    if (bestOpen == null) return [TextSpan(text: s, style: base)];

    final close = bestOpen == '<u>' ? '</u>' : bestOpen;
    final contentStart = bestPos + bestOpen.length;
    final closePos = s.indexOf(close, contentStart);
    final before = s.substring(0, bestPos);
    final styled = _styleFor(bestOpen, base);

    if (closePos == -1) {
      // No closing marker (e.g. a span split across a page) — style to the end.
      return [
        if (before.isNotEmpty) TextSpan(text: before, style: base),
        ..._parseInline(s.substring(contentStart), styled),
      ];
    }
    final inner = s.substring(contentStart, closePos);
    final rest = s.substring(closePos + close.length);
    return [
      if (before.isNotEmpty) TextSpan(text: before, style: base),
      ..._parseInline(inner, styled),
      ..._parseInline(rest, base),
    ];
  }

  InlineSpan _lineSpan(String line, TextStyle base, Color muted) {
    if (line.startsWith('# ')) {
      final h = base.copyWith(
        fontSize: (base.fontSize ?? 17) * 1.3,
        fontWeight: FontWeight.w700,
      );
      return TextSpan(children: _parseInline(line.substring(2), h));
    }
    if (line.startsWith('> ')) {
      final q = base.copyWith(fontStyle: FontStyle.italic, color: muted);
      return TextSpan(
        children: [
          TextSpan(text: '  ', style: q),
          ..._parseInline(line.substring(2), q),
        ],
      );
    }
    if (line.startsWith('- ')) {
      return TextSpan(
        children: [
          TextSpan(text: '•  ', style: base),
          ..._parseInline(line.substring(2), base),
        ],
      );
    }
    return TextSpan(children: _parseInline(line, base));
  }

  Widget _pageBody(String page, TextStyle base, Color muted) {
    final lines = page.split('\n');
    final children = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      children.add(_lineSpan(lines[i], base, muted));
      if (i < lines.length - 1) children.add(const TextSpan(text: '\n'));
    }
    return RichText(
      text: TextSpan(style: base, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final base = _baseStyle.copyWith(color: textColor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentSize = Size(
                  constraints.maxWidth - _hPad * 2,
                  constraints.maxHeight - _vPad * 2,
                );
                if (_size != contentSize &&
                    contentSize.width > 0 &&
                    contentSize.height > 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _paginate(contentSize);
                  });
                }
                if (_pages.isEmpty) {
                  return const SizedBox.shrink();
                }
                return PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _hPad,
                      vertical: _vPad,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _pageBody(_pages[i], base, muted),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_pages.length > 1) _footer(divColor, muted, textColor),
        ],
      ),
    );
  }

  Widget _footer(Color divColor, Color muted, Color textColor) {
    final total = _pages.length;
    final progress = total <= 1 ? 1.0 : (_index + 1) / total;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: divColor)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: divColor,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _index > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: textColor,
                disabledColor: muted.withValues(alpha: 0.4),
              ),
              Text(
                'Page ${_index + 1} of $total',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _index < total - 1 ? () => _go(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: textColor,
                disabledColor: muted.withValues(alpha: 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating breakdown bars
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBreakdown extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _RatingBreakdown({required this.listing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Mock distribution based on overall rating
    final r = listing.rating;
    final dist = [
      (5, (r >= 4.5 ? 0.65 : 0.45)),
      (4, (r >= 4.0 ? 0.25 : 0.30)),
      (3, 0.07),
      (2, 0.02),
      (1, 0.01),
    ];
    final trackColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big score
        Column(
          children: [
            Text(
              listing.rating.toStringAsFixed(1),
              style: GoogleFonts.lato(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < listing.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 14,
                  color: const Color(0xFFF4C430),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${listing.reviewCount}',
              style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
            ),
          ],
        ),
        const SizedBox(width: 20),

        // Bars
        Expanded(
          child: Column(
            children: dist.map((entry) {
              final stars = entry.$1;
              final frac = entry.$2;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '$stars',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: Color(0xFFF4C430),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 7,
                          backgroundColor: trackColor,
                          valueColor: AlwaysStoppedAnimation(
                            frac > 0.4
                                ? AppColors.accent
                                : trackColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${(frac * listing.reviewCount).round()}',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final _Review review;
  final bool isDark;
  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                child: Text(
                  review.reviewer[0].toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${review.daysAgo}d ago',
                      style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 13,
                    color: const Color(0xFFF4C430),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.body,
            style: GoogleFonts.lora(
              fontSize: 13,
              height: 1.65,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "More by author" horizontal card
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _AuthorListingCard({required this.listing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.8),
                      listing.type.badgeColor.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(listing.type.icon, size: 32, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.price,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge pill
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// Resolves the listing's author display name against [mockUsers]. Hides itself
// if the author can't be matched, or if they're the current user.
class _AuthorFollowChip extends ConsumerWidget {
  final String authorName;
  final bool isDark;
  const _AuthorFollowChip({required this.authorName, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = mockUsers.where((u) => u.displayName == authorName);
    if (matches.isEmpty) return const SizedBox.shrink();
    final author = matches.first;

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser?.id == author.id) return const SizedBox.shrink();

    final isFollowing = ref.watch(followNotifierProvider).contains(author.id);
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;

    return GestureDetector(
      onTap: () {
        final notifier = ref.read(followNotifierProvider.notifier);
        // Returned sync result deliberately ignored: follows apply locally
        // either way and a failed backend write is non-fatal here.
        if (isFollowing) {
          notifier.unfollow(author.id);
        } else {
          notifier.follow(author.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : accent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing ? accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
