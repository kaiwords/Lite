import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            itemCount: cart.length,
            itemBuilder: (_, i) => _CartListRow(
              listing: cart[i],
              coverColor: coverPalette[i % coverPalette.length],
              isDark: isDark,
            ),
          ),
        ),
        // Checkout footer — a rounded sheet lifting off the list, with the
        // total and the storefront's gold Checkout button.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Total',
                    style: AppFonts.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: AppFonts.ui(
                      fontSize: 21,
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
                height: 52,
                child: FilledButton(
                  style: mktFilledStyle(radius: 16),
                  onPressed: () async {
                    // One order, one Payment Sheet, for the whole cart —
                    // even when it spans multiple sellers (see
                    // supabase/functions/stripe-create-checkout).
                    final ok = await runPurchaseFlow(context, ref, cart);
                    if (!ok || !context.mounted) return;
                    // Remove only what was paid for, so anything added to
                    // the cart during checkout stays there.
                    final notifier = ref.read(cartProvider.notifier);
                    for (final item in cart) {
                      notifier.remove(item.id);
                    }
                  },
                  child: const Text('Checkout'),
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

    // Rounded storefront card: cover thumbnail, details, and a trash button.
    return GestureDetector(
      onTap: () => context.push('/marketplace/listing/${listing.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            ListingCover(
              listing: listing,
              fallbackColor: coverColor,
              width: 56,
              height: 80,
              borderRadius: 8,
              showLabel: false,
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
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
                      style: AppFonts.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(fontSize: 12.5, color: mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.price,
                      style: AppFonts.ui(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: offerPriceColor(listing.offer, isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Remove button
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: mutedColor,
              ),
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
                color: MktColors.goldFill.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 28,
                color: MktColors.text(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: AppFonts.display(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing here yet. Books you add will show up here.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(fontSize: 14, color: mutedColor, height: 1.5),
            ),
            if (onBrowseBooks != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                style: mktFilledStyle(),
                onPressed: onBrowseBooks,
                child: const Text('Browse Books'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
