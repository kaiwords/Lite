import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pill shown on an audio post when a linked Audio Book listing exists.
/// Uses headphone styling distinct from the general MarketplaceBadge.
class AudioMarketplaceBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/marketplace', extra: listingId),
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
            Text(
              'Listen in Marketplace',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _audioColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
