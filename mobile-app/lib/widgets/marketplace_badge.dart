import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../utils/marketplace_lookup.dart';
import 'listing_buy_sheet.dart';

/// Pill shown on a feed post when the writer has a linked Marketplace listing.
/// Tapping opens a "buy now" sheet (falling back to the full listing page if
/// the listing can't be resolved) so a reader can purchase without leaving
/// the feed.
class MarketplaceBadge extends ConsumerWidget {
  final String listingId;
  final bool isDark;

  const MarketplaceBadge({
    super.key,
    required this.listingId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final listing = findListingById(ref, listingId);
        if (listing != null) {
          showListingBuySheet(context, listing);
        } else {
          context.push('/marketplace/listing/$listingId');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // Solid fill (accentOnFill, darker than accent) + white text/icon
          // keeps this at WCAG AA contrast — the previous translucent tint
          // read as washed-out.
          color: isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Available in Marketplace',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.ui(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
