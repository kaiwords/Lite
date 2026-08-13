import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../theme/app_theme.dart';
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
    onListBook: () => showListItemSheet(context),
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
    showListItemSheet(context, existing: listing);
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
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 14),
            itemCount: itemCount,
            // A faint (near-invisible) hairline between rows — enough to
            // separate one listing from the next without a hard visible line.
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: (isDark ? AppColors.darkDivider : AppColors.divider)
                  .withValues(alpha: 0.4),
            ),
            itemBuilder: (_, i) {
              if (i == 0) {
                return AddListRow(
                  isDark: isDark,
                  title: 'List a Book',
                  subtitle: 'Sell your work',
                  onTap: widget.onListBook,
                );
              }
              final listing = filtered[i - 1];
              return BookListRow(
                listing: listing,
                isDark: isDark,
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
