import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Pill shown on a feed post when the writer has a linked Marketplace listing.
/// Tapping opens the listing detail page directly.
class MarketplaceBadge extends StatelessWidget {
  final String listingId;
  final bool isDark;

  const MarketplaceBadge({
    super.key,
    required this.listingId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/marketplace/listing/$listingId'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 12,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
            ),
            const SizedBox(width: 5),
            Text(
              'Available in Marketplace',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkAccent : AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
