import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/marketplace.dart';
import '../providers/marketplace_account_provider.dart';
import '../theme/app_theme.dart';

/// Bottom sheet shown when tapping a post's marketplace badge — lets a
/// reader buy the linked listing right from the feed, or jump to the full
/// listing page, without being forced through the cart. Mirrors the
/// rounded-sheet look used by [showActionSheet] in `action_sheet.dart`.
Future<void> showListingBuySheet(BuildContext context, MarketplaceListing listing) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ListingBuySheet(listing: listing),
  );
}

class _ListingBuySheet extends ConsumerWidget {
  final MarketplaceListing listing;
  const _ListingBuySheet({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final outline = isDark ? AppColors.darkAccent : AppColors.accent;
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;

    final owned = ref.watch(purchasesProvider).any((p) => p.listing.id == listing.id);
    final isMine = ref.watch(myListingsProvider).any((l) => l.id == listing.id);
    final canAccess = owned || isMine;

    void viewListing() {
      Navigator.pop(context);
      context.push('/marketplace/listing/${listing.id}');
    }

    void buyNow() {
      ref.read(purchasesProvider.notifier).buyNow(listing);
      ref.read(cartProvider.notifier).remove(listing.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${listing.title}" purchased! Check your Library.'),
        behavior: SnackBarBehavior.floating,
      ));
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: divColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(children: [
              // Cover
              Container(
                width: 52,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.85),
                      listing.type.badgeColor.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(listing.type.icon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      canAccess ? (owned ? 'In your library' : 'Your listing') : listing.price,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: outline, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: viewListing,
                  child: Text(
                    'View Listing',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700, color: outline),
                  ),
                ),
              ),
              if (!canAccess) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: fill,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: buyNow,
                    child: Text(
                      'Buy Now',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
