import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/purchase_flow.dart';
import 'marketplace_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart tab — rendered directly inside the Marketplace screen's Cart section.
// ─────────────────────────────────────────────────────────────────────────────

class CartTab extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onBrowseBooks;
  const CartTab({super.key, required this.isDark, this.onBrowseBooks});

  @override
  Widget build(BuildContext context) =>
      _CartTab(isDark: isDark, onBrowseBooks: onBrowseBooks);
}

class _CartTab extends ConsumerWidget {
  final bool isDark;
  final VoidCallback? onBrowseBooks;
  const _CartTab({required this.isDark, this.onBrowseBooks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return _EmptyCart(isDark: isDark, onBrowseBooks: onBrowseBooks);
    }

    final total = cart.fold<double>(
      0,
      (sum, l) => sum + (double.tryParse(l.price.replaceAll('\$', '')) ?? 0),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            itemCount: cart.length,
            // A faint (near-invisible) hairline between rows — matches
            // Library/My Listings/Sales.
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: (isDark ? AppColors.darkDivider : AppColors.divider)
                  .withValues(alpha: 0.4),
            ),
            itemBuilder: (_, i) => _CartListRow(
              listing: cart[i],
              coverColor: coverPalette[i % coverPalette.length],
              isDark: isDark,
            ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    // accentOnFill (darker than accent) keeps the white
                    // label at WCAG AA contrast.
                    backgroundColor: isDark
                        ? AppColors.darkAccentOnFill
                        : AppColors.accentOnFill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // One order, one Payment Sheet, for the whole cart —
                    // even when it spans multiple sellers (see
                    // supabase/functions/stripe-create-checkout).
                    final ok = await runPurchaseFlow(context, ref, cart);
                    if (ok) ref.read(cartProvider.notifier).clear();
                  },
                  child: Text(
                    'Checkout',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
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
  final Color coverColor;
  final bool isDark;
  const _CartListRow({
    required this.listing,
    required this.coverColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    // Striped cover thumbnail (56×80) — same placeholder motif as the Books
    // grid/list, so a listing reads consistently wherever it shows up.
    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            ListingCover(
              listing: listing,
              fallbackColor: coverColor,
              width: 56,
              height: 80,
              borderRadius: 7,
              showLabel: false,
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TypeChip(type: listing.type),
                    const SizedBox(height: 5),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.price,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Remove button
            IconButton(
              icon: Icon(Icons.close_rounded, size: 20, color: mutedColor),
              tooltip: 'Remove',
              onPressed: () =>
                  ref.read(cartProvider.notifier).remove(listing.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty cart state — icon chip, serif heading, muted copy, "Browse Books" CTA
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onBrowseBooks;
  const _EmptyCart({required this.isDark, this.onBrowseBooks});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF7E6D2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 28,
                color: Color(0xFFB4692A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing here yet — add books to see them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: mutedColor,
                height: 1.5,
              ),
            ),
            if (onBrowseBooks != null) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onBrowseBooks,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccentOnFill
                        : AppColors.accentOnFill,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    'Browse Books',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
