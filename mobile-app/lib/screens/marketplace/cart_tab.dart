import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../theme/app_theme.dart';
import 'marketplace_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart tab — rendered directly inside the Marketplace screen's Cart section.
// ─────────────────────────────────────────────────────────────────────────────

class CartTab extends StatelessWidget {
  final bool isDark;
  const CartTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _CartTab(isDark: isDark);
}

class _CartTab extends ConsumerWidget {
  final bool isDark;
  const _CartTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return EmptyState(
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
                    // accentOnFill (darker than accent) keeps the white
                    // label at WCAG AA contrast.
                    backgroundColor: isDark
                        ? AppColors.darkAccentOnFill
                        : AppColors.accentOnFill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Checkout — buy every listing currently in the cart
                    // through the shared purchase-creation logic.
                    final purchasesNotifier = ref.read(
                      purchasesProvider.notifier,
                    );
                    for (final l in cart) {
                      purchasesNotifier.buyNow(l);
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
        // `crossAxisAlignment.stretch` needs a bounded incoming height to
        // work — but this Row is a ListView item, which gives its children
        // unbounded height, so `stretch` here throws "BoxConstraints forces
        // an infinite height" once the list actually has a row to lay out.
        // The fixed-height cover already sets the row's height; no stretch
        // needed.
        child: Row(
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
                    TypeChip(type: listing.type),
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
