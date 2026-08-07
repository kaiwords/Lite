import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'cart_tab.dart';
import 'library_tab.dart';
import 'marketplace_shared_widgets.dart';
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
        color: const Color(0xFF6E51A6),
        iconBg: const Color(0xFFECE6F5),
        onTap: () => open(const _BooksSectionScreen()),
      ),
      _SectionTileData(
        label: 'Cart',
        subtitle: cart.isEmpty
            ? 'Nothing here yet'
            : '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFFB4692A),
        iconBg: const Color(0xFFF7E6D2),
        badge: cart.isEmpty ? null : '${cart.length}',
        onTap: () => open(_CartSectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'My Library',
        subtitle: purchases.isEmpty
            ? 'No purchases yet'
            : '${purchases.length} ${purchases.length == 1 ? 'title' : 'titles'}',
        icon: Icons.library_books_outlined,
        color: const Color(0xFF47637E),
        iconBg: const Color(0xFFE2E9EE),
        onTap: () => open(_LibrarySectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'My Listings',
        subtitle: myListings.isEmpty
            ? 'Nothing listed yet'
            : '${myListings.length} active',
        icon: Icons.storefront_outlined,
        color: const Color(0xFF5A7A3C),
        iconBg: const Color(0xFFE6EEDD),
        onTap: () => open(_MyListingsSectionScreen(isDark: isDark)),
      ),
      _SectionTileData(
        label: 'Sales',
        subtitle: sales.isEmpty
            ? 'No sales yet'
            : '${sales.length} ${sales.length == 1 ? 'sale' : 'sales'}',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF8A4468),
        iconBg: const Color(0xFFF2E1E9),
        onTap: () => open(_SalesSectionScreen(isDark: isDark)),
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Marketplace',
          style: GoogleFonts.playfairDisplay(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
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
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse books, manage your cart, library, listings and sales',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: mutedColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
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
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  // 168 was too tight for the tile's actual content (icon
                  // chip + title + subtitle + "View" row + 18px padding on
                  // all sides) and overflowed by ~14px on every phone width.
                  mainAxisExtent: 190,
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
  final Color iconBg;
  final String? badge;
  final VoidCallback onTap;

  const _SectionTileData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBg,
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
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    // Card tile: white surface, hairline border, rounded corners — matches
    // the marketplace redesign reference (soft pastel icon chip, serif
    // title, muted subtitle, "View →" link pinned to the bottom).
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            // Badge
            if (data.badge != null)
              Positioned(
                top: -4,
                right: -4,
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

            // Content — left-aligned, icon chip → title → subtitle → "View →"
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(data.icon, size: 22, color: data.color),
                ),
                const SizedBox(height: 14),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: data.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: data.color,
                    ),
                  ],
                ),
              ],
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
    return Scaffold(body: _BooksBody(isDark: isDark));
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
    body: CartTab(
      isDark: isDark,
      onBrowseBooks: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _BooksSectionScreen()),
      ),
    ),
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
// Books body — search bar + result count + a 3-column cover grid
// ═════════════════════════════════════════════════════════════════════════════

class _BooksBody extends ConsumerStatefulWidget {
  final bool isDark;
  const _BooksBody({required this.isDark});

  @override
  ConsumerState<_BooksBody> createState() => _BooksBodyState();
}

enum _BookLayout { grid, list }

class _BooksBodyState extends ConsumerState<_BooksBody> {
  final _searchController = TextEditingController();
  String _query = '';
  Genre? _genre; // null = all genres
  ListingType? _format; // null = all formats
  _BookLayout _layout = _BookLayout.grid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
        _searchController.clear();
        _query = '';
        _genre = null;
        _format = null;
      });

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
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final allListings = ref.watch(marketplaceListingsProvider);

    final q = _query.trim().toLowerCase();
    final listings = allListings.where((l) {
      if (_genre != null && l.genre != _genre) return false;
      if (_format != null && l.type != _format) return false;
      if (q.isNotEmpty &&
          !l.title.toLowerCase().contains(q) &&
          !l.authorName.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        // floating+snap: hides the title/search as soon as the list scrolls
        // down, and snaps them back the moment the user scrolls back up.
        SliverAppBar(
          floating: true,
          snap: true,
          toolbarHeight: 44,
          title: Text(
            'Books',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _SearchField(
                controller: _searchController,
                isDark: isDark,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
        ),
        // pinned (not just a plain sliver): genre + format stay on screen at
        // all times, unlike the title/search bar above, which is allowed to
        // scroll out of view.
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedFiltersDelegate(
            height: 78,
            isDark: isDark,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _GenreFilterRow(
                  genres: _availableGenres(allListings),
                  selected: _genre,
                  isDark: isDark,
                  onChanged: (g) => setState(() => _genre = g),
                ),
                const SizedBox(height: 8),
                _FormatFilterRow(
                  selected: _format,
                  isDark: isDark,
                  onChanged: (t) => setState(() => _format = t),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${listings.length} of ${allListings.length} titles',
                    style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                  ),
                ),
                _LayoutToggleButton(
                  icon: Icons.grid_view_rounded,
                  selected: _layout == _BookLayout.grid,
                  isDark: isDark,
                  onTap: () => setState(() => _layout = _BookLayout.grid),
                ),
                const SizedBox(width: 4),
                _LayoutToggleButton(
                  icon: Icons.view_list_rounded,
                  selected: _layout == _BookLayout.list,
                  isDark: isDark,
                  onTap: () => setState(() => _layout = _BookLayout.list),
                ),
              ],
            ),
          ),
        ),
        if (listings.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyBooks(isDark: isDark, onClear: _clearFilters),
          )
        else if (_layout == _BookLayout.grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 4,
                // Fixed extent (not childAspectRatio) keeps each tile's
                // height constant regardless of screen width — see
                // library_tab.dart's identical grid for why. Must stay
                // >= the cover's fixed height (below) + text block, or
                // the tile's Column overflows.
                mainAxisExtent: 250,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BookGridTile(
                  listing: listings[i],
                  coverColor: coverPalette[i % coverPalette.length],
                  isDark: isDark,
                ),
                childCount: listings.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i.isOdd) {
                    return Divider(
                      height: 1,
                      color:
                          isDark ? AppColors.darkDivider : AppColors.divider,
                    );
                  }
                  final listing = listings[i ~/ 2];
                  return _BookListTile(
                    listing: listing,
                    coverColor:
                        coverPalette[(i ~/ 2) % coverPalette.length],
                    isDark: isDark,
                  );
                },
                childCount: listings.isEmpty ? 0 : listings.length * 2 - 1,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned genre/format filter header — stays on screen while everything else
// (including the title/search SliverAppBar above it) scrolls away.
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedFiltersDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool isDark;
  const _PinnedFiltersDelegate({
    required this.child,
    required this.height,
    required this.isDark,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Opaque background needed — a pinned sliver otherwise lets the
    // scrolling content behind it show through.
    return ColoredBox(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedFiltersDelegate oldDelegate) =>
      child != oldDelegate.child ||
      height != oldDelegate.height ||
      isDark != oldDelegate.isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid / list layout toggle
// ─────────────────────────────────────────────────────────────────────────────

class _LayoutToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _LayoutToggleButton({
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? AppColors.accent : mutedColor,
        ),
      ),
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
      height: 30,
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
// Format filter row — Physical / Ebook / Audio
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
      height: 30,
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
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 11))
              else if (icon != null)
                Icon(icon, size: 12, color: selected ? color : mutedColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 11,
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
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.darkSurfaceVariant : AppColors.surface;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.lato(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: 'Search titles, authors...',
        hintStyle: GoogleFonts.lato(fontSize: 14, color: mutedColor),
        prefixIcon: Icon(Icons.search_rounded, color: mutedColor),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book grid tile — cover placeholder, title, author, price
// ─────────────────────────────────────────────────────────────────────────────

class _BookGridTile extends StatelessWidget {
  final MarketplaceListing listing;
  final Color coverColor;
  final bool isDark;
  const _BookGridTile({
    required this.listing,
    required this.coverColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A fixed height (not AspectRatio-driven) keeps every tile's
          // total height constant regardless of screen width — the grid
          // above uses a fixed mainAxisExtent, and a width-relative square
          // cover on wide screens grew taller than that budget, overflowing
          // the column.
          StripedCover(
            color: coverColor,
            width: double.infinity,
            height: 150,
            borderRadius: 8,
          ),
          const SizedBox(height: 8),
          Text(
            listing.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            listing.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
          ),
          const SizedBox(height: 2),
          Text(
            listing.price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book list tile — thumbnail cover + title/author/price row
// ─────────────────────────────────────────────────────────────────────────────

class _BookListTile extends StatelessWidget {
  final MarketplaceListing listing;
  final Color coverColor;
  final bool isDark;
  const _BookListTile({
    required this.listing,
    required this.coverColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StripedCover(
              color: coverColor,
              width: 56,
              height: 80,
              borderRadius: 7,
              showLabel: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 12.5, color: mutedColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.price,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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
            'Try a different search, genre, or format',
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
