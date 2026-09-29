import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
// Marketplace — a storefront home. Search up top, quick-access pills for
// Cart / My Library / My Listings / Sales, a featured "Popular" banner, the
// genre/format/offer filter chips, then the full book grid (or list).
// ═════════════════════════════════════════════════════════════════════════════

class MarketplaceScreen extends ConsumerWidget {
  final String? initialListingId;
  const MarketplaceScreen({super.key, this.initialListingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Marketplace',
          style: AppFonts.display(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          _MktCartButton(isDark: isDark),
          _MktNotifButton(isDark: isDark),
          _MktMessageButton(isDark: isDark),
        ],
      ),
      // Audio tab disabled — Market moved from index 2 to 1.
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 1),
      body: _StorefrontBody(isDark: isDark),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Section screens (pushed from the quick-access row / cart button)
// ═════════════════════════════════════════════════════════════════════════════

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
      // The storefront underneath *is* the book browse now — just go back.
      onBrowseBooks: () => Navigator.of(context).pop(),
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
// Storefront body — search + quick access + featured + filters + book grid
// ═════════════════════════════════════════════════════════════════════════════

class _StorefrontBody extends ConsumerStatefulWidget {
  final bool isDark;
  const _StorefrontBody({required this.isDark});

  @override
  ConsumerState<_StorefrontBody> createState() => _StorefrontBodyState();
}

enum _BookLayout { grid, list }

class _StorefrontBodyState extends ConsumerState<_StorefrontBody> {
  final _searchController = TextEditingController();
  String _query = '';
  Genre? _genre; // null = all genres
  ListingType? _format; // null = all formats
  ListingOffer? _offer; // null = all offers (Sale/Free/Swap)
  _BookLayout _layout = _BookLayout.grid;
  // Whether the genre/format/offer chip rows are shown. Hiding them only
  // collapses the rows — any filters already picked keep applying (the
  // toggle row says how many are active).
  bool _showFilters = true;

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
    _offer = null;
  });

  bool get _isFiltering =>
      _query.trim().isNotEmpty ||
      _genre != null ||
      _format != null ||
      _offer != null;

  // Genres that have at least one listing
  List<Genre> _availableGenres(List<MarketplaceListing> allListings) {
    final seen = <Genre>{};
    for (final l in allListings) {
      if (l.genre != null) seen.add(l.genre!);
    }
    return Genre.values.where(seen.contains).toList();
  }

  /// The banner book: best-rated (most-reviewed on ties), preferring
  /// listings that can still be bought/claimed.
  MarketplaceListing? _featured(List<MarketplaceListing> allListings) {
    if (allListings.isEmpty) return null;
    final available = allListings.where((l) => !l.isSoldOut).toList();
    final pool = available.isEmpty ? allListings : available;
    return pool.reduce((a, b) {
      if (a.rating != b.rating) return a.rating > b.rating ? a : b;
      return a.reviewCount >= b.reviewCount ? a : b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final allListings = ref.watch(marketplaceListingsProvider);
    final cart = ref.watch(cartProvider);
    final purchases = ref.watch(purchasesProvider);
    final myListings = ref.watch(myListingsProvider);
    final sales = ref.watch(salesProvider);

    final q = _query.trim().toLowerCase();
    final listings = allListings.where((l) {
      if (_genre != null && l.genre != _genre) return false;
      if (_format != null && l.type != _format) return false;
      if (_offer != null && l.offer != _offer) return false;
      if (q.isNotEmpty &&
          !l.title.toLowerCase().contains(q) &&
          !l.authorName.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    final featured = _featured(allListings);

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return CustomScrollView(
      slivers: [
        // ── Search bar ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: _SearchField(
              controller: _searchController,
              isDark: isDark,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),

        // ── Quick access: Cart / Library / Listings / Sales ──────────
        // Non-lazy (SingleChildScrollView, not ListView): only four pills,
        // and having them all always built keeps text finders/semantics
        // stable regardless of screen width.
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _QuickLink(
                  label: 'Cart',
                  subtitle: cart.isEmpty
                      ? 'Empty'
                      : '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
                  icon: Icons.shopping_cart_outlined,
                  badge: cart.isEmpty ? null : '${cart.length}',
                  isDark: isDark,
                  onTap: () => open(_CartSectionScreen(isDark: isDark)),
                ),
                _QuickLink(
                  label: 'My Library',
                  subtitle: purchases.isEmpty
                      ? 'No purchases'
                      : '${purchases.length} ${purchases.length == 1 ? 'title' : 'titles'}',
                  icon: Icons.library_books_outlined,
                  isDark: isDark,
                  onTap: () => open(_LibrarySectionScreen(isDark: isDark)),
                ),
                _QuickLink(
                  label: 'My Listings',
                  subtitle: myListings.isEmpty
                      ? 'Nothing listed'
                      : '${myListings.length} active',
                  icon: Icons.storefront_outlined,
                  isDark: isDark,
                  onTap: () => open(_MyListingsSectionScreen(isDark: isDark)),
                ),
                _QuickLink(
                  label: 'Sales',
                  subtitle: sales.isEmpty
                      ? 'No sales yet'
                      : '${sales.length} ${sales.length == 1 ? 'sale' : 'sales'}',
                  icon: Icons.bar_chart_rounded,
                  isDark: isDark,
                  onTap: () => open(_SalesSectionScreen(isDark: isDark)),
                ),
              ],
            ),
          ),
        ),

        // ── Featured banner — hidden while searching/filtering ───────
        if (!_isFiltering && featured != null)
          SliverToBoxAdapter(
            child: _FeaturedBanner(listing: featured, isDark: isDark),
          ),

        // pinned (not just a plain sliver): the filters toggle — and, when
        // shown, the genre + format + offer rows — stay on screen at all
        // times while the rest scrolls away.
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedFiltersDelegate(
            height: _showFilters ? 166 : 40,
            isDark: isDark,
            child: Column(
              children: [
                const SizedBox(height: 6),
                _FiltersToggleRow(
                  expanded: _showFilters,
                  activeCount: [
                    _genre,
                    _format,
                    _offer,
                  ].whereType<Object>().length,
                  isDark: isDark,
                  onTap: () => setState(() => _showFilters = !_showFilters),
                ),
                const SizedBox(height: 4),
                if (_showFilters) ...[
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
                  const SizedBox(height: 8),
                  _OfferFilterRow(
                    selected: _offer,
                    isDark: isDark,
                    onChanged: (o) => setState(() => _offer = o),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${listings.length} of ${allListings.length} titles',
                    style: AppFonts.ui(fontSize: 12, color: mutedColor),
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
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // Fixed extent (not childAspectRatio) keeps each card's
                // height constant regardless of screen width; must cover
                // the padded cover (166) + the text block below it.
                mainAxisExtent: 264,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BookGridCard(
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
              delegate: SliverChildBuilderDelegate((context, i) {
                if (i.isOdd) {
                  return Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  );
                }
                final listing = listings[i ~/ 2];
                return _BookListTile(
                  listing: listing,
                  coverColor: coverPalette[(i ~/ 2) % coverPalette.length],
                  isDark: isDark,
                );
              }, childCount: listings.isEmpty ? 0 : listings.length * 2 - 1),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick-access pill
// ─────────────────────────────────────────────────────────────────────────────

class _QuickLink extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickLink({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        label: '$label, $subtitle',
        excludeSemantics: true,
        child: Material(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: MktColors.goldFill.withValues(
                            alpha: isDark ? 0.22 : 0.18,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 17,
                          color: MktColors.text(isDark),
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: MktColors.goldFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: AppFonts.ui(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: MktColors.onGold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 9),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppFonts.ui(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppFonts.ui(fontSize: 10.5, color: mutedColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured "Popular" banner — the storefront's hero card
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedBanner extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _FeaturedBanner({required this.listing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Semantics(
        button: true,
        label: 'Popular: ${listing.title} by ${listing.authorName}',
        excludeSemantics: true,
        child: Material(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/marketplace/listing/${listing.id}'),
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: MktColors.goldFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 12,
                                color: MktColors.onGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Popular',
                                style: AppFonts.ui(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: MktColors.onGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.display(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(fontSize: 13, color: mutedColor),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'View book',
                              style: AppFonts.ui(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: MktColors.text(isDark),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: MktColors.text(isDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ListingCover(
                    listing: listing,
                    fallbackColor:
                        listing.genre?.colors.first ?? coverPalette[0],
                    width: 76,
                    height: 110,
                    borderRadius: 10,
                    showLabel: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned genre/format/offer filter header — stays on screen while everything
// else (search bar, quick access, banner) scrolls away.
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
              ? MktColors.goldFill.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? MktColors.text(isDark) : mutedColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters toggle — hides/shows the three chip rows beneath it. Hidden
// filters keep applying; the "N active" count keeps that visible.
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersToggleRow extends StatelessWidget {
  final bool expanded;
  final int activeCount;
  final bool isDark;
  final VoidCallback onTap;

  const _FiltersToggleRow({
    required this.expanded,
    required this.activeCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return SizedBox(
      height: 30,
      child: Semantics(
        button: true,
        label:
            '${expanded ? 'Hide' : 'Show'} filters'
            '${activeCount > 0 ? ', $activeCount active' : ''}',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 14, color: textColor),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: AppFonts.ui(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· $activeCount active',
                    style: AppFonts.ui(fontSize: 11.5, color: mutedColor),
                  ),
                ],
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: mutedColor,
                ),
              ],
            ),
          ),
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
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FmtChip(
            label: 'All Genres',
            icon: Icons.auto_stories_rounded,
            selected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          ...genres.map(
            (g) => _FmtChip(
              label: g.label,
              emoji: g.emoji,
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
// Format filter row — Physical / Ebook (Audio disabled 2026-09-30)
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
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FmtChip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          // Audio disabled: was `...ListingType.values.map(` — the Audio chip
          // is skipped so only Physical / E-Book can be filtered.
          ...ListingType.values
              .where((t) => t != ListingType.audio)
              .map(
                (t) => _FmtChip(
                  label: t.label,
                  icon: t.icon,
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

// ─────────────────────────────────────────────────────────────────────────────
// Offer filter row — For Sale / Free / Swap. Underneath the format row, so a
// reader can browse straight to giveaways/swaps regardless of format.
// ─────────────────────────────────────────────────────────────────────────────

class _OfferFilterRow extends StatelessWidget {
  final ListingOffer? selected;
  final bool isDark;
  final ValueChanged<ListingOffer?> onChanged;

  const _OfferFilterRow({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FmtChip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: selected == null,
            isDark: isDark,
            onTap: () => onChanged(null),
          ),
          ...ListingOffer.values.map(
            (o) => _FmtChip(
              label: o.label,
              icon: o.icon,
              selected: selected == o,
              isDark: isDark,
              onTap: () => onChanged(selected == o ? null : o),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip in the storefront's single gold accent: solid gold with ink
/// text when selected, a quiet hairline outline otherwise.
class _FmtChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FmtChip({
    required this.label,
    this.icon,
    this.emoji,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final fg = selected ? MktColors.onGold : mutedColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? MktColors.goldFill : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? MktColors.goldFill : borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 11))
              else if (icon != null)
                Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppFonts.ui(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
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
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppFonts.ui(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: 'Search books, authors...',
        hintStyle: AppFonts.ui(fontSize: 14, color: mutedColor),
        prefixIcon: Icon(Icons.search_rounded, color: mutedColor),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book grid card — cover with rating + format tags, then title/author/price
// ─────────────────────────────────────────────────────────────────────────────

class _BookGridCard extends StatelessWidget {
  final MarketplaceListing listing;
  final Color coverColor;
  final bool isDark;
  const _BookGridCard({
    required this.listing,
    required this.coverColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  ListingCover(
                    listing: listing,
                    fallbackColor: coverColor,
                    width: double.infinity,
                    height: 150,
                    borderRadius: 10,
                  ),
                  if (listing.rating > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: RatingBadge(
                        rating: listing.rating,
                        isDark: isDark,
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _TypeTag(type: listing.type, isDark: isDark),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(fontSize: 11, color: mutedColor),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    listing.isSoldOut ? 'Claimed' : listing.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: listing.isSoldOut
                          ? mutedColor
                          : offerPriceColor(listing.offer, isDark),
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

/// Small Physical/E-Book tag overlaid on grid covers — solid surface behind
/// the colored label so it stays readable over cover photos.
class _TypeTag extends StatelessWidget {
  final ListingType type;
  final bool isDark;
  const _TypeTag({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
      ),
      child: Text(
        type.label,
        style: AppFonts.ui(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: type.badgeColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book list tile — thumbnail cover + title/author/rating/price row
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
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListingCover(
              listing: listing,
              fallbackColor: coverColor,
              width: 56,
              height: 80,
              borderRadius: 8,
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
                    style: AppFonts.display(
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
                    style: AppFonts.ui(fontSize: 12.5, color: mutedColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (listing.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: MktColors.star,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          listing.rating.toStringAsFixed(1),
                          style: AppFonts.ui(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                        Text(
                          '  ·  ',
                          style: AppFonts.ui(fontSize: 11, color: mutedColor),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          listing.isSoldOut ? 'Claimed' : listing.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: listing.isSoldOut
                                ? mutedColor
                                : offerPriceColor(listing.offer, isDark),
                          ),
                        ),
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
            style: AppFonts.display(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search, genre, or format',
            style: AppFonts.ui(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Show all',
              style: AppFonts.ui(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MktColors.text(isDark),
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

class _MktCartButton extends ConsumerWidget {
  final bool isDark;
  const _MktCartButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Cart',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _CartSectionScreen(isDark: isDark),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: MktColors.goldFill,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: MktColors.onGold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
