import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/marketplace_listing_card.dart';
import 'cart_tab.dart';
import 'library_tab.dart';
import 'my_listings_tab.dart';
import 'sales_tab.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Marketplace landing — section tiles only.
// Tapping a section opens a screen showing that section's content:
// Books · Cart · My Library · My Listings · Sales
// ═════════════════════════════════════════════════════════════════════════════

class MarketplaceScreen extends ConsumerWidget {
  final String? initialListingId;
  const MarketplaceScreen({super.key, this.initialListingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final cart = ref.watch(cartProvider);
    final purchases = ref.watch(purchasesProvider);
    final myListings = ref.watch(myListingsProvider);
    final sales = ref.watch(salesProvider);
    final allListings = ref.watch(marketplaceListingsProvider);

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    final sections = [
      _SectionTileData(
        label: 'Books',
        subtitle: '${allListings.length} titles to explore',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF6B4EAA),
        onTap: () => open(const _BooksSectionScreen()),
      ),
      _SectionTileData(
        label: 'Cart',
        subtitle: cart.isEmpty
            ? 'Nothing here yet'
            : '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.accent,
        badge: cart.isEmpty ? null : '${cart.length}',
        onTap: () => open(_CartSectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'My Library',
        subtitle: purchases.isEmpty
            ? 'No purchases yet'
            : '${purchases.length} ${purchases.length == 1 ? 'title' : 'titles'}',
        icon: Icons.library_books_outlined,
        color: const Color(0xFF4A6FA5),
        onTap: () => open(_LibrarySectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'My Listings',
        subtitle: myListings.isEmpty
            ? 'Nothing listed yet'
            : '${myListings.length} active',
        icon: Icons.storefront_outlined,
        color: const Color(0xFF5C7A5C),
        onTap: () => open(_MyListingsSectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'Sales',
        subtitle: sales.isEmpty
            ? 'No sales yet'
            : '${sales.length} ${sales.length == 1 ? 'sale' : 'sales'}',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF9B5C8A),
        onTap: () => open(_SalesSectionScreen(isDark: isDark)),
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Marketplace',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          _MktNotifButton(isDark: isDark),
          _MktMessageButton(isDark: isDark),
        ],
      ),
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to do?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Browse books, manage your cart, library, listings and sales',
              style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              // A fixed `mainAxisExtent` (rather than `childAspectRatio`)
              // keeps each tile's height constant regardless of screen
              // width — with an aspect ratio, tiles get shorter as the
              // screen narrows even though their content (icon + label +
              // subtitle + "View") doesn't, which overflowed on narrow
              // phones.
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 168,
                ),
                itemCount: sections.length,
                itemBuilder: (_, i) =>
                    _SectionTile(data: sections[i], isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section tile
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTileData {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _SectionTileData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class _SectionTile extends StatelessWidget {
  final _SectionTileData data;
  final bool isDark;
  const _SectionTile({required this.data, required this.isDark});

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

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            // Colored top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
              ),
            ),

            // Badge
            if (data.badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.badge!,
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, size: 19, color: data.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  // A plain Icon (rather than a "→" glyph in the string)
                  // avoids depending on the active font having that glyph —
                  // a missing glyph can render as a much taller fallback
                  // box and blow out this tile's tight fixed height.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: data.color,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: data.color,
                      ),
                    ],
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

// ═════════════════════════════════════════════════════════════════════════════
// Section screens (pushed from tiles)
// ═════════════════════════════════════════════════════════════════════════════

class _BooksSectionScreen extends StatelessWidget {
  const _BooksSectionScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Books',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: _BooksBody(isDark: isDark),
    );
  }
}

class _CartSectionScreen extends StatelessWidget {
  final bool isDark;
  const _CartSectionScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Cart', style: Theme.of(context).appBarTheme.titleTextStyle),
    ),
    body: CartTab(isDark: isDark),
  );
}

class _LibrarySectionScreen extends StatelessWidget {
  final bool isDark;
  const _LibrarySectionScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'My Library',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
    ),
    body: LibraryTab(isDark: isDark),
  );
}

class _MyListingsSectionScreen extends StatelessWidget {
  final bool isDark;
  const _MyListingsSectionScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'My Listings',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
    ),
    body: MyListingsTab(isDark: isDark),
  );
}

class _SalesSectionScreen extends StatelessWidget {
  final bool isDark;
  const _SalesSectionScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Sales', style: Theme.of(context).appBarTheme.titleTextStyle),
    ),
    body: SalesTab(isDark: isDark),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Books body — all listings with genre + format filters (no genre grouping)
// ═════════════════════════════════════════════════════════════════════════════

class _BooksBody extends ConsumerStatefulWidget {
  final bool isDark;
  const _BooksBody({required this.isDark});

  @override
  ConsumerState<_BooksBody> createState() => _BooksBodyState();
}

class _BooksBodyState extends ConsumerState<_BooksBody> {
  Genre? _genre; // null = all genres
  ListingType? _format; // null = all formats

  // Genres that have at least one listing
  List<Genre> _availableGenres(List<MarketplaceListing> allListings) {
    final seen = <Genre>{};
    for (final l in allListings) {
      if (l.genre != null) seen.add(l.genre!);
    }
    return Genre.values.where(seen.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final allPosts = ref.watch(postsNotifierProvider);
    final allListings = ref.watch(marketplaceListingsProvider);

    final listings = allListings.where((l) {
      if (_genre != null && l.genre != _genre) return false;
      if (_format != null && l.type != _format) return false;
      return true;
    }).toList();

    final hasFilter = _genre != null || _format != null;

    return Column(
      children: [
        const SizedBox(height: 10),
        // ── Sort / filter by genre ──────────────────────────────────────────
        _GenreFilterRow(
          genres: _availableGenres(allListings),
          selected: _genre,
          isDark: isDark,
          onChanged: (g) => setState(() => _genre = g),
        ),
        const SizedBox(height: 8),
        // ── Filter by format ────────────────────────────────────────────────
        _FormatFilterRow(
          selected: _format,
          isDark: isDark,
          onChanged: (t) => setState(() => _format = t),
        ),
        const SizedBox(height: 6),
        // ── Result count + clear ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              Text(
                '${listings.length} ${listings.length == 1 ? 'title' : 'titles'}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
              const Spacer(),
              if (hasFilter)
                GestureDetector(
                  onTap: () => setState(() {
                    _genre = null;
                    _format = null;
                  }),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: divColor),
        Expanded(
          child: listings.isEmpty
              ? _EmptyBooks(
                  isDark: isDark,
                  onClear: () => setState(() {
                    _genre = null;
                    _format = null;
                  }),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  itemCount: listings.length,
                  itemBuilder: (context, i) {
                    final listing = listings[i];
                    VoidCallback? onViewPost;
                    if (listing.linkedPostId != null) {
                      if (listing.type == ListingType.audio) {
                        onViewPost = () =>
                            context.push('/audio', extra: listing.linkedPostId);
                      } else {
                        final idx = allPosts.indexWhere(
                          (p) => p.id == listing.linkedPostId,
                        );
                        if (idx >= 0) {
                          onViewPost = () => context.push('/viewer/$idx');
                        }
                      }
                    }
                    return MarketplaceListingCard(
                      listing: listing,
                      isDark: isDark,
                      onViewPost: onViewPost,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Genre filter row
// ─────────────────────────────────────────────────────────────────────────────

class _GenreFilterRow extends StatelessWidget {
  final List<Genre> genres;
  final Genre? selected;
  final bool isDark;
  final ValueChanged<Genre?> onChanged;

  const _GenreFilterRow({
    required this.genres,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FmtChip(
            label: 'All Genres',
            icon: Icons.auto_stories_rounded,
            color: AppColors.accent,
            selected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          ...genres.map(
            (g) => _FmtChip(
              label: g.label,
              emoji: g.emoji,
              color: g.colors[0],
              selected: selected == g,
              isDark: isDark,
              onTap: () => onChanged(selected == g ? null : g),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Format filter row
// ─────────────────────────────────────────────────────────────────────────────

class _FormatFilterRow extends StatelessWidget {
  final ListingType? selected;
  final bool isDark;
  final ValueChanged<ListingType?> onChanged;

  const _FormatFilterRow({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FmtChip(
            label: 'All',
            icon: Icons.apps_rounded,
            color: AppColors.accent,
            selected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          ...ListingType.values.map(
            (t) => _FmtChip(
              label: t.label,
              icon: t.icon,
              color: t.badgeColor,
              selected: selected == t,
              isDark: isDark,
              onTap: () => onChanged(selected == t ? null : t),
            ),
          ),
        ],
      ),
    );
  }
}

class _FmtChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FmtChip({
    required this.label,
    this.icon,
    this.emoji,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 12))
              else if (icon != null)
                Icon(icon, size: 13, color: selected ? color : mutedColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (no books match the active filters)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBooks extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;
  const _EmptyBooks({required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: mutedColor),
          const SizedBox(height: 12),
          Text(
            'No titles match',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different genre or format',
            style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Show all',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AppBar action buttons
// ═════════════════════════════════════════════════════════════════════════════

// Notification counts use the same mock data as the notifications screen
final _unreadNotifCount = 9; // mockMktNotifs has 3 unread (n1, n2, n3)
final _unreadMsgCount = 2; // sc1, sc2

class _MktNotifButton extends StatelessWidget {
  final bool isDark;
  const _MktNotifButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/marketplace/notifications'),
        ),
        if (_unreadNotifCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                // accentOnFill (darker than accent) keeps the white count
                // at WCAG AA contrast.
                color: isDark
                    ? AppColors.darkAccentOnFill
                    : AppColors.accentOnFill,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_unreadNotifCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MktMessageButton extends StatelessWidget {
  final bool isDark;
  const _MktMessageButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          onPressed: () => context.push('/marketplace/messages'),
        ),
        if (_unreadMsgCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF5C7A5C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_unreadMsgCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
