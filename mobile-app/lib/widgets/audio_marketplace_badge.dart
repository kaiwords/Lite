import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/marketplace_lookup.dart';
import 'listing_buy_sheet.dart';

/// Pill shown on an audio post when a linked Audio Book listing exists.
/// Uses headphone styling distinct from the general MarketplaceBadge. Tapping
/// opens a "buy now" sheet (falling back to the marketplace tab if the
/// listing can't be resolved) so a listener can purchase without leaving
/// the feed.
class AudioMarketplaceBadge extends ConsumerWidget {
  final String listingId;
  final bool isDark;

  const AudioMarketplaceBadge({
    super.key,
    required this.listingId,
    required this.isDark,
  });

  // Audio listing badge colour — matches ListingType.audio.badgeColor
  static const _audioColor = Color(0xFF9B5C8A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final listing = findListingById(ref, listingId);
        if (listing != null) {
          showListingBuySheet(context, listing);
        } else {
          context.push('/marketplace', extra: listingId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _audioColor.withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _audioColor.withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.headphones_rounded, size: 12, color: _audioColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Listen in Marketplace',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _audioColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
