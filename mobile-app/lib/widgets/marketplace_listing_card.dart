import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/marketplace.dart';
import '../models/post.dart';
import '../providers/marketplace_account_provider.dart';
import '../theme/app_theme.dart';

/// Full listing card used inside the Marketplace tab sections.
class MarketplaceListingCard extends ConsumerWidget {
  final MarketplaceListing listing;
  final bool isDark;

  /// Called when the "View Post" button is tapped.
  /// Null means the listing has no linked feed post — button is hidden.
  final VoidCallback? onViewPost;

  const MarketplaceListingCard({
    super.key,
    required this.listing,
    required this.isDark,
    this.onViewPost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(cartProvider).any((l) => l.id == listing.id);
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover art placeholder ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: Container(
                width: 96,
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.75),
                      listing.type.badgeColor.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    listing.type.icon,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),

            // ── Details ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Format + genre badges — Wrap (not Row) so the pair
                    // reflows onto a second line instead of overflowing when
                    // a longer category label ("Short Story", etc.) doesn't
                    // fit next to the type badge on narrow phones.
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _TypeBadge(type: listing.type),
                        if (listing.contentCategory != null)
                          _GenreBadge(category: listing.contentCategory!),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),

                    // Author
                    Text(
                      listing.authorName,
                      style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    _RatingRow(
                      rating: listing.rating,
                      reviewCount: listing.reviewCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    // Price + CTA row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listing.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _CtaButton(listing: listing, inCart: inCart, ref: ref),
                      ],
                    ),

                    // "View Post" cross-link (only when linked)
                    if (onViewPost != null) ...[
                      const SizedBox(height: 6),
                      _CrossLinkButton(
                        label: 'View Post',
                        icon: Icons.article_outlined,
                        onTap: onViewPost!,
                        isDark: isDark,
                      ),
                    ],
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

// ── Genre badge pill ─────────────────────────────────────────────────────────

class _GenreBadge extends StatelessWidget {
  final ContentCategory category;
  const _GenreBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Text(
            category.label,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type badge pill ─────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final ListingType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: type.badgeColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Star rating row ─────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool isDark;
  const _RatingRow({
    required this.rating,
    required this.reviewCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF4C430)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: mutedColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount)',
          style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
        ),
      ],
    );
  }
}

// ── CTA button ──────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final MarketplaceListing listing;
  final bool inCart;
  final WidgetRef ref;
  const _CtaButton({
    required this.listing,
    required this.inCart,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    // accentOnFill (darker than accent) keeps the white label at WCAG AA
    // contrast for the solid fill state.
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;
    return GestureDetector(
      onTap: () {
        if (inCart) {
          ref.read(cartProvider.notifier).remove(listing.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from cart'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ref.read(cartProvider.notifier).add(listing);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${listing.title}" added to cart'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: inCart ? Colors.transparent : fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: inCart ? accent : fill),
        ),
        child: Text(
          inCart ? 'In Cart' : listing.type.ctaLabel,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: inCart ? accent : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Cross-link "View Post" button ────────────────────────────────────────────

class CrossLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const CrossLinkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Private alias used inside this file only
class _CrossLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _CrossLinkButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) =>
      CrossLinkButton(label: label, icon: icon, onTap: onTap, isDark: isDark);
}
