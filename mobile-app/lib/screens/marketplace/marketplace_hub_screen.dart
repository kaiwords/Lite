import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/book.dart';
import '../../models/marketplace.dart';
import '../../models/post.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../screens/reader/book_reader_screen.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public tab bodies — rendered directly inside the Marketplace screen's tabs.
// Thin wrappers around the private tab implementations below so they can be
// reused without exposing internals.
// ─────────────────────────────────────────────────────────────────────────────

class CartTab extends StatelessWidget {
  final bool isDark;
  const CartTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _CartTab(isDark: isDark);
}

class LibraryTab extends StatelessWidget {
  final bool isDark;
  const LibraryTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _LibraryTab(isDark: isDark);
}

class SalesTab extends StatelessWidget {
  final bool isDark;
  const SalesTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _SalesTab(isDark: isDark);
}

class MyListingsTab extends StatelessWidget {
  final bool isDark;
  const MyListingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _MyListingsTab(
    isDark: isDark,
    onListBook: () => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListItemSheet(isDark: isDark),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hub screen
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceHubScreen extends ConsumerWidget {
  const MarketplaceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final purchases = ref.watch(purchasesProvider);
    final myListings = ref.watch(myListingsProvider);
    final sales = ref.watch(salesProvider);
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final tiles = [
      _HubTileData(
        label: 'Cart',
        subtitle: cart.isEmpty
            ? 'Nothing here yet'
            : '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.accent,
        badge: cart.isEmpty ? null : '${cart.length}',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => _CartScreen(isDark: isDark))),
      ),
      _HubTileData(
        label: 'Library',
        subtitle: purchases.isEmpty
            ? 'No purchases yet'
            : '${purchases.length} ${purchases.length == 1 ? 'title' : 'titles'}',
        icon: Icons.library_books_outlined,
        color: const Color(0xFF4A6FA5),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _LibraryScreen(isDark: isDark)),
        ),
      ),
      _HubTileData(
        label: 'My Listings',
        subtitle: myListings.isEmpty
            ? 'Nothing listed yet'
            : '${myListings.length} active',
        icon: Icons.storefront_outlined,
        color: const Color(0xFF5C7A5C),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _MyListingsScreen(isDark: isDark)),
        ),
      ),
      _HubTileData(
        label: 'Sales',
        subtitle: sales.isEmpty
            ? 'No sales yet'
            : '${sales.length} ${sales.length == 1 ? 'sale' : 'sales'}',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF9B5C8A),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => _SalesScreen(isDark: isDark))),
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'My Hub',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
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
              'Manage your purchases, listings and sales',
              style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: tiles
                    .map((t) => _HubTile(data: t, isDark: isDark))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hub tile data + widget
// ─────────────────────────────────────────────────────────────────────────────

class _HubTileData {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _HubTileData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class _HubTile extends StatelessWidget {
  final _HubTileData data;
  final bool isDark;
  const _HubTile({required this.data, required this.isDark});

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
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, size: 22, color: data.color),
                  ),
                  const Spacer(),
                  Text(
                    data.label,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'View →',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: data.color,
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
// Section screens (pushed from tiles)
// ─────────────────────────────────────────────────────────────────────────────

class _CartScreen extends StatelessWidget {
  final bool isDark;
  const _CartScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Cart', style: Theme.of(context).appBarTheme.titleTextStyle),
    ),
    body: _CartTab(isDark: isDark),
  );
}

class _LibraryScreen extends StatelessWidget {
  final bool isDark;
  const _LibraryScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Library',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
    ),
    body: _LibraryTab(isDark: isDark),
  );
}

class _MyListingsScreen extends StatelessWidget {
  final bool isDark;
  const _MyListingsScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'My Listings',
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
    ),
    body: _MyListingsTab(
      isDark: isDark,
      onListBook: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ListItemSheet(isDark: isDark),
      ),
    ),
  );
}

class _SalesScreen extends StatelessWidget {
  final bool isDark;
  const _SalesScreen({required this.isDark});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Sales', style: Theme.of(context).appBarTheme.titleTextStyle),
    ),
    body: _SalesTab(isDark: isDark),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart tab
// ─────────────────────────────────────────────────────────────────────────────

class _CartTab extends ConsumerWidget {
  final bool isDark;
  const _CartTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return _EmptyState(
        isDark: isDark,
        icon: Icons.shopping_cart_outlined,
        message: 'Your cart is empty',
        sub: 'Browse the marketplace and add books to your cart',
      );
    }

    final total = cart.fold<double>(
      0,
      (sum, l) => sum + (double.tryParse(l.price.replaceAll('\$', '')) ?? 0),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            itemCount: cart.length,
            itemBuilder: (_, i) =>
                _CartListRow(listing: cart[i], isDark: isDark),
          ),
        ),
        // Checkout footer
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Subtotal',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Simulate checkout
                    final purchases = cart
                        .map(
                          (l) => Purchase(
                            listing: l,
                            purchasedAt: DateTime.now(),
                            orderId:
                                'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}',
                          ),
                        )
                        .toList();
                    for (final p in purchases) {
                      ref.read(purchasesProvider.notifier).add(p);
                    }
                    ref.read(cartProvider.notifier).clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Purchase complete! ✨ Check your Library.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    'Checkout · \$${total.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart list row — horizontal "listing view" card for the cart
// ─────────────────────────────────────────────────────────────────────────────

class _CartListRow extends ConsumerWidget {
  final MarketplaceListing listing;
  final bool isDark;
  const _CartListRow({required this.listing, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: Container(
                width: 72,
                height: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.85),
                      listing.type.badgeColor.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(listing.type.icon, size: 30, color: Colors.white),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TypeChip(type: listing.type),
                    const SizedBox(height: 5),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.price,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Remove button
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: mutedColor),
                tooltip: 'Remove',
                onPressed: () =>
                    ref.read(cartProvider.notifier).remove(listing.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared grid card — used in Library and My Listings
// ─────────────────────────────────────────────────────────────────────────────

class _BookGridCard extends ConsumerWidget {
  final MarketplaceListing listing;
  final bool isDark;
  final VoidCallback? onRemove; // shows an X button (e.g. remove from library)
  final VoidCallback? onEdit; // my listings: edit via ⋮ menu
  final VoidCallback? onDelete; // my listings: delete via ⋮ menu
  final String? accessLabel; // library: Play/Read/View
  final int? salesCount; // my listings: sold count

  const _BookGridCard({
    required this.listing,
    required this.isDark,
    this.onRemove,
    this.onEdit,
    this.onDelete,
    this.accessLabel,
    this.salesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (accessLabel == 'Read') {
          // Map listing id → book id (extend as more books are added)
          const listingToBook = {'mBook1': 'b1'};
          final bookId = listingToBook[listing.id] ?? 'b1';
          final book = findBook(bookId) ?? mockBooks.first;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
          );
        } else {
          context.push('/marketplace/listing/${listing.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.85),
                      listing.type.badgeColor.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        listing.type.icon,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (onEdit != null || onDelete != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _CardMenu(
                          onEdit: onEdit,
                          onDelete: onDelete,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeChip(type: listing.type),
                    const SizedBox(height: 5),
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
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          listing.price,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        const Spacer(),
                        if (accessLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: listing.type.badgeColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              accessLabel!,
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: listing.type.badgeColor,
                              ),
                            ),
                          ),
                        if (salesCount != null)
                          Text(
                            '$salesCount sold',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              color: mutedColor,
                            ),
                          ),
                      ],
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

// ── Edit / delete menu overlay (My Listings) ────────────────────────────────

class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDark;
  const _CardMenu({
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: 'Options',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 16,
          color: Colors.white,
        ),
        onSelected: (v) {
          if (v == 'edit') onEdit?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => [
          if (onEdit != null)
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text('Edit', style: GoogleFonts.lato(fontSize: 13)),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFC0392B),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Delete',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: const Color(0xFFC0392B),
                    ),
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
// Library tab — purchased items as grid with genre + format filters
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _LibraryTab({required this.isDark});

  @override
  ConsumerState<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<_LibraryTab> {
  ListingType? _format;
  Genre? _genre;

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToLibrarySheet(isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    final isDark = widget.isDark;

    // Genres present in the library
    final genreSeen = <Genre>{};
    for (final p in purchases) {
      if (p.listing.genre != null) genreSeen.add(p.listing.genre!);
    }
    final genres = Genre.values.where(genreSeen.contains).toList();

    final filtered = purchases.where((p) {
      if (_genre != null && p.listing.genre != _genre) return false;
      if (_format != null && p.listing.type != _format) return false;
      return true;
    }).toList();

    // First grid cell is the "Add Book" tile
    final itemCount = filtered.length + 1;

    return Column(
      children: [
        const SizedBox(height: 10),
        if (genres.isNotEmpty) ...[
          _GenreFilterBar(
            genres: genres,
            selected: _genre,
            onChanged: (g) => setState(() => _genre = g),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],
        _TypeFilterBar(
          selected: _format,
          onChanged: (t) => setState(() => _format = t),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i == 0) {
                return _AddTile(
                  isDark: isDark,
                  title: 'Add Book',
                  subtitle: 'Add to your library',
                  onTap: _showAddSheet,
                );
              }
              final l = filtered[i - 1].listing;
              final label = l.type == ListingType.audio
                  ? 'Play'
                  : l.type == ListingType.ebook
                  ? 'Read'
                  : 'View';
              return _BookGridCard(
                listing: l,
                isDark: isDark,
                accessLabel: label,
                onRemove: () =>
                    ref.read(purchasesProvider.notifier).remove(l.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Listings tab — user's own listings as grid + List a Book tile + filter
// ─────────────────────────────────────────────────────────────────────────────

class _MyListingsTab extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback onListBook;
  const _MyListingsTab({required this.isDark, required this.onListBook});

  @override
  ConsumerState<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends ConsumerState<_MyListingsTab> {
  ListingType? _filter;

  void _showEditSheet(MarketplaceListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListItemSheet(isDark: widget.isDark, existing: listing),
    );
  }

  Future<void> _confirmDelete(MarketplaceListing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('"${listing.title}" will be removed from your listings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(myListingsProvider.notifier).remove(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${listing.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myListings = ref.watch(myListingsProvider);
    final sales = ref.watch(salesProvider);
    final isDark = widget.isDark;

    final filtered = _filter == null
        ? myListings
        : myListings.where((l) => l.type == _filter).toList();

    // First grid cell is the "List a Book" tile
    final itemCount = filtered.length + 1;

    return Column(
      children: [
        const SizedBox(height: 10),
        _TypeFilterBar(
          selected: _filter,
          onChanged: (t) => setState(() => _filter = t),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i == 0) {
                return _AddTile(
                  isDark: isDark,
                  title: 'List a Book',
                  subtitle: 'Sell your work',
                  onTap: widget.onListBook,
                );
              }
              final listing = filtered[i - 1];
              final sold = sales
                  .where((s) => s.listing.id == listing.id)
                  .length;
              return _BookGridCard(
                listing: listing,
                isDark: isDark,
                salesCount: sold,
                onEdit: () => _showEditSheet(listing),
                onDelete: () => _confirmDelete(listing),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales tab — stats row + recent sales list
// ─────────────────────────────────────────────────────────────────────────────

class _SalesTab extends ConsumerWidget {
  final bool isDark;
  const _SalesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final myListings = ref.watch(myListingsProvider);

    final totalEarned = sales.fold<double>(0, (sum, s) => sum + s.amount);

    return CustomScrollView(
      slivers: [
        // ── Stats row ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatCard(
                  label: 'Total Earned',
                  value: '\$${totalEarned.toStringAsFixed(2)}',
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Items Sold',
                  value: '${sales.length}',
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFF5C7A5C),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Listings',
                  value: '${myListings.length}',
                  icon: Icons.list_alt_rounded,
                  color: const Color(0xFF4A6FA5),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        // ── Section header ──────────────────────────────────────────────
        if (sales.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Recent Sales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),

        // ── Sales grid ──────────────────────────────────────────────────
        if (sales.isEmpty)
          SliverFillRemaining(
            child: _EmptyState(
              isDark: isDark,
              icon: Icons.bar_chart_rounded,
              message: 'No sales yet',
              sub:
                  'Your sales will appear here once readers purchase your work',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SaleListRow(sale: sales[i], isDark: isDark),
                childCount: sales.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 10, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleListRow extends StatelessWidget {
  final Sale sale;
  final bool isDark;
  const _SaleListRow({required this.sale, required this.isDark});

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
    final listing = sale.listing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: Container(
              width: 64,
              height: 80,
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
              child: Icon(listing.type.icon, size: 26, color: Colors.white),
            ),
          ),

          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sold to ${sale.buyerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(sale.soldAt),
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
          ),

          // Amount
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Text(
              '+\$${sale.amount.toStringAsFixed(2)}',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C7A5C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List a Book bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the "List a Book" sheet. [initialType] pre-selects the listing format
/// (e.g. E-Book or Audio) when launching from elsewhere, such as the Home
/// upload action.
void showListItemSheet(
  BuildContext context, {
  ListingType? initialType,
  MarketplaceListing? existing,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ListItemSheet(
      isDark: isDark,
      initialType: initialType,
      existing: existing,
    ),
  );
}

class _ListItemSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final MarketplaceListing? existing; // non-null = edit mode
  final ListingType? initialType; // pre-selected format for new listings
  const _ListItemSheet({required this.isDark, this.existing, this.initialType});

  @override
  ConsumerState<_ListItemSheet> createState() => _ListItemSheetState();
}

class _ListItemSheetState extends ConsumerState<_ListItemSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late ListingType _type;
  late ContentCategory _category;

  // E-book source
  _EbookSource _ebookSource = _EbookSource.pdf;
  String? _pdfFileName;
  String? _ebookContent;

  // Audio book source — one uploaded file per volume
  List<String> _audioVolumes = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? e.price.replaceAll('\$', '') : '',
    );
    _type = e?.type ?? widget.initialType ?? ListingType.ebook;
    _category = e?.contentCategory ?? ContentCategory.novel;
    _pdfFileName = e?.pdfFileName;
    _ebookContent = e?.ebookContent;
    _audioVolumes = List.of(e?.audioVolumes ?? const []);
    // Pick the source tab that matches whatever was already provided
    _ebookSource = (_ebookContent != null && _ebookContent!.isNotEmpty)
        ? _EbookSource.write
        : _EbookSource.pdf;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pdfFileName = result.files.single.name);
    }
  }

  /// Picks an audio file from local storage. Appends it as a new volume, or
  /// replaces the volume at [replaceIndex] when re-uploading.
  Future<void> _pickAudioVolume({int? replaceIndex}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final name = result.files.single.name;
      setState(() {
        if (replaceIndex != null && replaceIndex < _audioVolumes.length) {
          _audioVolumes[replaceIndex] = name;
        } else {
          _audioVolumes.add(name);
        }
      });
    }
  }

  Future<void> _openWriter() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _WriteBookScreen(
          initialTitle: _titleCtrl.text.trim(),
          initialContent: _ebookContent ?? '',
        ),
      ),
    );
    if (result != null) {
      setState(() => _ebookContent = result);
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final priceRaw = _priceCtrl.text.trim();
    if (title.isEmpty || priceRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final price = double.tryParse(
      priceRaw.replaceAll('\$', '').replaceAll(',', ''),
    );
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For E-Books, require either an uploaded PDF or written content.
    final isEbook = _type == ListingType.ebook;
    final pdfName = isEbook && _ebookSource == _EbookSource.pdf
        ? _pdfFileName
        : null;
    final content =
        isEbook &&
            _ebookSource == _EbookSource.write &&
            (_ebookContent?.trim().isNotEmpty ?? false)
        ? _ebookContent!.trim()
        : null;
    if (isEbook && pdfName == null && content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a PDF or write your book to list an E-Book.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For Audio books, require at least one uploaded volume.
    final isAudio = _type == ListingType.audio;
    final audioVolumes = isAudio ? List<String>.of(_audioVolumes) : <String>[];
    if (isAudio && audioVolumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload at least one audio volume to list an Audio book.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final e = widget.existing;
    final listing = MarketplaceListing(
      id: e?.id ?? 'u${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authorName: e?.authorName ?? 'Eleanor Voss',
      price: '\$${price.toStringAsFixed(2)}',
      type: _type,
      rating: e?.rating ?? 0,
      reviewCount: e?.reviewCount ?? 0,
      linkedPostId: e?.linkedPostId,
      contentCategory: _category,
      genre: e?.genre,
      description: e?.description ?? '',
      pdfFileName: pdfName,
      ebookContent: content,
      audioVolumes: audioVolumes,
    );
    if (_isEdit) {
      ref.read(myListingsProvider.notifier).update(listing);
    } else {
      ref.read(myListingsProvider.notifier).add(listing);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? '"$title" updated' : '"$title" listed for sale!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEdit ? 'Edit Listing' : 'List a Book',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit
                  ? 'Update your listing details'
                  : 'Your listing will appear in the marketplace',
              style: GoogleFonts.lato(fontSize: 13, color: labelColor),
            ),
            const SizedBox(height: 20),

            // Title
            _FieldLabel('Title', isDark: isDark),
            const SizedBox(height: 6),
            _TextField(
              controller: _titleCtrl,
              hint: 'e.g. Midnight Verses',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Type
            _FieldLabel('Type', isDark: isDark),
            const SizedBox(height: 8),
            Row(
              children: ListingType.values.map((t) {
                final sel = _type == t;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.badgeColor.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? t.badgeColor : borderColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              t.icon,
                              size: 20,
                              color: sel ? t.badgeColor : labelColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sel ? t.badgeColor : labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // E-Book content — upload a PDF or write the book online
            if (_type == ListingType.ebook) ...[
              _FieldLabel('E-Book Content', isDark: isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SourceToggle(
                      label: 'Upload PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      selected: _ebookSource == _EbookSource.pdf,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _ebookSource = _EbookSource.pdf),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceToggle(
                      label: 'Write online',
                      icon: Icons.edit_note_rounded,
                      selected: _ebookSource == _EbookSource.write,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _ebookSource = _EbookSource.write),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_ebookSource == _EbookSource.pdf)
                _FileUploadBox(
                  fileName: _pdfFileName,
                  isDark: isDark,
                  onPick: _pickPdf,
                  onClear: () => setState(() => _pdfFileName = null),
                  fileIcon: Icons.picture_as_pdf_rounded,
                  fileIconColor: const Color(0xFFC0392B),
                  emptyTitle: 'Tap to upload PDF',
                  emptyHint: 'Choose a .pdf file from your device',
                  attachedLabel: 'PDF attached',
                )
              else
                _WriteBox(
                  content: _ebookContent,
                  isDark: isDark,
                  onTap: _openWriter,
                ),
              const SizedBox(height: 16),
            ],

            // Audio book — upload one file per volume (1 is fine, add more)
            if (_type == ListingType.audio) ...[
              Row(
                children: [
                  _FieldLabel(
                    _audioVolumes.length > 1 ? 'Audio Volumes' : 'Audio File',
                    isDark: isDark,
                  ),
                  const Spacer(),
                  if (_audioVolumes.isNotEmpty)
                    Text(
                      '${_audioVolumes.length} ${_audioVolumes.length == 1 ? 'volume' : 'volumes'}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_audioVolumes.isEmpty)
                _FileUploadBox(
                  fileName: null,
                  isDark: isDark,
                  onPick: () => _pickAudioVolume(),
                  onClear: () {},
                  fileIcon: Icons.audiotrack_rounded,
                  fileIconColor: ListingType.audio.badgeColor,
                  emptyTitle: 'Tap to upload audio',
                  emptyHint: 'MP3, M4A, AAC, WAV, OGG or FLAC',
                  attachedLabel: 'Audio attached',
                )
              else ...[
                for (var i = 0; i < _audioVolumes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _VolumeTile(
                      volumeNumber: i + 1,
                      fileName: _audioVolumes[i],
                      isDark: isDark,
                      onReplace: () => _pickAudioVolume(replaceIndex: i),
                      onRemove: () => setState(() => _audioVolumes.removeAt(i)),
                    ),
                  ),
                _AddVolumeButton(
                  isDark: isDark,
                  onTap: () => _pickAudioVolume(),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Category
            _FieldLabel('Category', isDark: isDark),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                      ContentCategory.novel,
                      ContentCategory.poem,
                      ContentCategory.essay,
                      ContentCategory.story,
                      ContentCategory.haiku,
                      ContentCategory.article,
                      ContentCategory.joke,
                    ].map((cat) {
                      final sel = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: sel ? AppColors.accent : borderColor,
                              ),
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.label}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : labelColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            _FieldLabel('Price (USD)', isDark: isDark),
            const SizedBox(height: 6),
            _TextField(
              controller: _priceCtrl,
              hint: 'e.g. 9.99',
              isDark: isDark,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefix: Text(
                '\$ ',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  _isEdit ? 'Save Changes' : 'List for Sale',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

// ─────────────────────────────────────────────────────────────────────────────
// E-book source widgets (PDF upload vs write online)
// ─────────────────────────────────────────────────────────────────────────────

enum _EbookSource { pdf, write }

class _SourceToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _SourceToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.accent : borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.accent : labelColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileUploadBox extends StatelessWidget {
  final String? fileName;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final IconData fileIcon;
  final Color fileIconColor;
  final String emptyTitle;
  final String emptyHint;
  final String attachedLabel;
  const _FileUploadBox({
    required this.fileName,
    required this.isDark,
    required this.onPick,
    required this.onClear,
    required this.fileIcon,
    required this.fileIconColor,
    required this.emptyTitle,
    required this.emptyHint,
    required this.attachedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    if (fileName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(fileIcon, size: 24, color: fileIconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    attachedLabel,
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: Text(
                'Replace',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
              tooltip: 'Remove',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 30,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            Text(
              emptyTitle,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              emptyHint,
              style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audiobook volume tile + add-volume button ───────────────────────────────

class _VolumeTile extends StatelessWidget {
  final int volumeNumber;
  final String fileName;
  final bool isDark;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  const _VolumeTile({
    required this.volumeNumber,
    required this.fileName,
    required this.isDark,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final audioColor = ListingType.audio.badgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: audioColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.audiotrack_rounded, size: 18, color: audioColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volume $volumeNumber',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReplace,
            child: Text(
              'Replace',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
            tooltip: 'Remove volume',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddVolumeButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddVolumeButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Add another volume',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WriteBox extends StatelessWidget {
  final String? content;
  final bool isDark;
  final VoidCallback onTap;
  const _WriteBox({
    required this.content,
    required this.isDark,
    required this.onTap,
  });

  int get _wordCount {
    final t = content?.trim() ?? '';
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final hasContent = (content?.trim().isNotEmpty ?? false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasContent ? Icons.menu_book_rounded : Icons.edit_note_rounded,
              size: 28,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasContent ? 'Continue writing' : 'Write your book',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasContent
                        ? '$_wordCount ${_wordCount == 1 ? 'word' : 'words'} written'
                        : 'Open the editor to write online',
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
            Text(
              hasContent ? 'Edit' : 'Open',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Write-online editor — full-screen writing surface
// ─────────────────────────────────────────────────────────────────────────────

class _WriteBookScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  const _WriteBookScreen({
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<_WriteBookScreen> createState() => _WriteBookScreenState();
}

// Formatting uses markdown-style markers (**bold**, _italic_, …). The book is a
// single continuous string, auto-paginated to fit the page shown on screen.

class _WriteBookScreenState extends State<_WriteBookScreen> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  List<String> _pages = [''];
  int _index = 0;
  Size? _pageSize; // measured text area of one page

  TextStyle get _baseStyle => GoogleFonts.lora(fontSize: 16, height: 1.6);

  @override
  void initState() {
    super.initState();
    _pages = [widget.initialContent];
    _ctrl = TextEditingController(text: _pages[0]);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  int get _wordCount {
    final t = _pages.join().trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  /// Splits [text] into pages, each holding as much as fits in [size],
  /// breaking on word boundaries where possible.
  List<String> _paginate(String text, Size size) {
    if (text.isEmpty) return [''];
    final pages = <String>[];
    var start = 0;
    while (start < text.length) {
      final remaining = text.substring(start);
      final tp = TextPainter(
        text: TextSpan(text: remaining, style: _baseStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      if (tp.height <= size.height) {
        pages.add(remaining);
        break;
      }

      // How many whole lines fit in the page height?
      final metrics = tp.computeLineMetrics();
      var used = 0.0;
      var lastFit = -1;
      for (var i = 0; i < metrics.length; i++) {
        if (used + metrics[i].height <= size.height) {
          used += metrics[i].height;
          lastFit = i;
        } else {
          break;
        }
      }
      if (lastFit < 0) lastFit = 0;
      var top = 0.0;
      for (var i = 0; i < lastFit; i++) {
        top += metrics[i].height;
      }
      final yMid = top + metrics[lastFit].height / 2;
      final pos = tp.getPositionForOffset(Offset(size.width, yMid));
      var end = start + pos.offset;
      if (end <= start) end = start + 1; // always make progress
      if (end >= text.length) {
        pages.add(text.substring(start));
        break;
      }
      // Prefer a word boundary
      final slice = text.substring(start, end);
      final lastWs = slice.lastIndexOf(RegExp(r'\s'));
      if (lastWs > 0) end = start + lastWs + 1;
      pages.add(text.substring(start, end));
      start = end;
    }
    return pages.isEmpty ? [''] : pages;
  }

  bool _samePages(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Re-flows the whole book after an edit (or page-size change), keeping the
  /// caret in place. New pages are created automatically when content overflows.
  void _reflow({int? cursorOverride}) {
    final size = _pageSize;
    if (size == null) return;

    _pages[_index] = _ctrl.text; // commit the active page
    final full = _pages.join();
    final newPages = _paginate(full, size);

    if (_samePages(newPages, _pages)) {
      setState(() {}); // refresh counters only; leave the caret untouched
      return;
    }

    final before = _pages.take(_index).join().length;
    final sel = _ctrl.selection;
    final globalCursor =
        (cursorOverride ??
                (before +
                    (sel.baseOffset < 0 ? _ctrl.text.length : sel.baseOffset)))
            .clamp(0, full.length);

    var page = 0;
    var local = 0;
    var acc = 0;
    for (var i = 0; i < newPages.length; i++) {
      final len = newPages[i].length;
      if (globalCursor <= acc + len) {
        page = i;
        local = globalCursor - acc;
        if (local == len && i < newPages.length - 1) {
          page = i + 1;
          local = 0;
        }
        break;
      }
      acc += len;
      if (i == newPages.length - 1) {
        page = i;
        local = len;
      }
    }

    setState(() {
      _pages = newPages;
      _index = page;
      _ctrl.value = TextEditingValue(
        text: _pages[page],
        selection: TextSelection.collapsed(
          offset: local.clamp(0, _pages[page].length),
        ),
      );
    });
    _focus.requestFocus();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _pages.length || i == _index) return;
    setState(() {
      _index = i;
      _ctrl.value = TextEditingValue(
        text: _pages[i],
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
    _focus.requestFocus();
  }

  void _save() => Navigator.pop(context, _pages.join());

  // ── Formatting (markdown-style markers) ──────────────────────────────────────

  void _wrap(String left, String right) {
    final value = _ctrl.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final cursor = selected.isEmpty
        ? start + left.length
        : start + left.length + selected.length + right.length;
    _ctrl.value = TextEditingValue(
      text: text.replaceRange(start, end, '$left$selected$right'),
      selection: TextSelection.collapsed(offset: cursor),
    );
    _focus.requestFocus();
    _reflow();
  }

  void _linePrefix(String prefix) {
    final value = _ctrl.value;
    final text = value.text;
    final sel = value.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
    _ctrl.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
    _focus.requestFocus();
    _reflow();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.initialTitle.isEmpty ? 'Write your book' : widget.initialTitle,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Page bar ───────────────────────────────────────────────────
          Container(
            color: surfaceBg,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous page',
                  visualDensity: VisualDensity.compact,
                  onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _index,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    items: [
                      for (var i = 0; i < _pages.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('Page ${i + 1}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) _goTo(v);
                    },
                  ),
                ),
                Text(
                  ' of ${_pages.length}',
                  style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next page',
                  visualDensity: VisualDensity.compact,
                  onPressed: _index < _pages.length - 1
                      ? () => _goTo(_index + 1)
                      : null,
                ),
                const Spacer(),
                Text(
                  '$_wordCount ${_wordCount == 1 ? 'word' : 'words'}',
                  style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // ── Formatting toolbar ─────────────────────────────────────────
          Container(
            color: surfaceBg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _FmtBtn(
                    icon: Icons.format_bold_rounded,
                    tooltip: 'Bold',
                    onTap: () => _wrap('**', '**'),
                  ),
                  _FmtBtn(
                    icon: Icons.format_italic_rounded,
                    tooltip: 'Italic',
                    onTap: () => _wrap('_', '_'),
                  ),
                  _FmtBtn(
                    icon: Icons.format_underlined_rounded,
                    tooltip: 'Underline',
                    onTap: () => _wrap('<u>', '</u>'),
                  ),
                  _FmtBtn(
                    icon: Icons.strikethrough_s_rounded,
                    tooltip: 'Strikethrough',
                    onTap: () => _wrap('~~', '~~'),
                  ),
                  Container(width: 1, height: 22, color: divColor),
                  _FmtBtn(
                    icon: Icons.title_rounded,
                    tooltip: 'Heading',
                    onTap: () => _linePrefix('# '),
                  ),
                  _FmtBtn(
                    icon: Icons.format_list_bulleted_rounded,
                    tooltip: 'Bullet list',
                    onTap: () => _linePrefix('- '),
                  ),
                  _FmtBtn(
                    icon: Icons.format_quote_rounded,
                    tooltip: 'Quote',
                    onTap: () => _linePrefix('> '),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: divColor),

          // ── Editor (one page at a time, auto-paginated) ─────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const margin = 16.0;
                const pad = 18.0;
                final pageW = constraints.maxWidth - margin * 2;
                final pageH = constraints.maxHeight - margin * 2;
                final contentSize = Size(pageW - pad * 2, pageH - pad * 2);

                // (Re)paginate when the page size first becomes known or changes.
                if (_pageSize != contentSize) {
                  final first = _pageSize == null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _pageSize = contentSize;
                    _reflow(cursorOverride: first ? 0 : null);
                  });
                }

                return Center(
                  child: Container(
                    width: pageW,
                    height: pageH,
                    margin: const EdgeInsets.all(margin),
                    padding: const EdgeInsets.all(pad),
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: divColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: (_) => _reflow(),
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: _baseStyle.copyWith(color: textColor),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Start writing page ${_index + 1}…',
                        hintStyle: _baseStyle.copyWith(color: mutedColor),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FmtBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _FmtBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add to Library bottom sheet — pick a marketplace book to add to the library
// ─────────────────────────────────────────────────────────────────────────────

class _AddToLibrarySheet extends ConsumerWidget {
  final bool isDark;
  const _AddToLibrarySheet({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesProvider);
    final owned = purchases.map((p) => p.listing.id).toSet();
    final available = mockListings.where((l) => !owned.contains(l.id)).toList();

    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: div,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Add to Library',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: div),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'You already own every title in the marketplace.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: available.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: div),
                      itemBuilder: (_, i) {
                        final l = available[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 40,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [
                                  l.type.badgeColor.withValues(alpha: 0.85),
                                  l.type.badgeColor.withValues(alpha: 0.35),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              l.type.icon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          subtitle: Text(
                            '${l.authorName} · ${l.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              ref
                                  .read(purchasesProvider.notifier)
                                  .add(
                                    Purchase(
                                      listing: l,
                                      purchasedAt: DateTime.now(),
                                      orderId:
                                          'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}',
                                    ),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '"${l.title}" added to library',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Add',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
// Add tile — reused by Library "Add Book" and My Listings "List a Book"
// ─────────────────────────────────────────────────────────────────────────────

class _AddTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AddTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Genre filter bar (Library)
// ─────────────────────────────────────────────────────────────────────────────

class _GenreFilterBar extends StatelessWidget {
  final List<Genre> genres;
  final Genre? selected;
  final ValueChanged<Genre?> onChanged;
  final bool isDark;
  const _GenreFilterBar({
    required this.genres,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _GenreChip(
            label: 'All Genres',
            emoji: '✦',
            color: AppColors.accent,
            selected: selected == null,
            onTap: () => onChanged(null),
            isDark: isDark,
          ),
          ...genres.map(
            (g) => _GenreChip(
              label: g.label,
              emoji: g.emoji,
              color: g.colors[0],
              selected: selected == g,
              onTap: () => onChanged(selected == g ? null : g),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _GenreChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
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
              Text(emoji, style: const TextStyle(fontSize: 12)),
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
// Type filter bar (Library + My Listings)
// ─────────────────────────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  final ListingType? selected;
  final ValueChanged<ListingType?> onChanged;
  final bool isDark;
  const _TypeFilterBar({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: selected == null,
            color: AppColors.accent,
            onTap: () => onChanged(null),
            isDark: isDark,
          ),
          ...ListingType.values.map(
            (t) => _FilterChip(
              label: t.label,
              icon: t.icon,
              selected: selected == t,
              color: t.badgeColor,
              onTap: () => onChanged(selected == t ? null : t),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.isDark,
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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final ListingType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: type.badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: type.badgeColor,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final Widget? prefix;
  const _TextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Padding(padding: const EdgeInsets.only(left: 14), child: prefix!),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.lato(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lato(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: mutedColor),
            const SizedBox(height: 14),
            Text(
              message,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
