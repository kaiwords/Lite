import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import 'list_item_sheet.dart';
import 'marketplace_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// My Listings tab — user's own listings as grid + List a Book tile + filter
// ─────────────────────────────────────────────────────────────────────────────

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
      builder: (_) => ListItemSheet(isDark: isDark),
    ),
  );
}

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
      builder: (_) => ListItemSheet(isDark: widget.isDark, existing: listing),
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
        TypeFilterBar(
          selected: _filter,
          onChanged: (t) => setState(() => _filter = t),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            // A fixed `mainAxisExtent` (rather than `childAspectRatio`) keeps
            // each card's height constant regardless of screen width — see
            // library_tab.dart's identical grid for why.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 225,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i == 0) {
                return AddTile(
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
              return BookGridCard(
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
