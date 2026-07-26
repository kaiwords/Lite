import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../theme/app_theme.dart';
import 'marketplace_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sales tab — stats row + recent sales list
// ─────────────────────────────────────────────────────────────────────────────

class SalesTab extends StatelessWidget {
  final bool isDark;
  const SalesTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _SalesTab(isDark: isDark);
}

class _SalesTab extends ConsumerWidget {
  final bool isDark;
  const _SalesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final myListings = ref.watch(myListingsProvider);

    final totalEarned = sales.fold<double>(0, (sum, s) => sum + s.amount);

    return CustomScrollView(
      slivers: [
        // ── Stats row ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatCard(
                  label: 'Total Earned',
                  value: '\$${totalEarned.toStringAsFixed(2)}',
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Items Sold',
                  value: '${sales.length}',
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFF5C7A5C),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Listings',
                  value: '${myListings.length}',
                  icon: Icons.list_alt_rounded,
                  color: const Color(0xFF4A6FA5),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        // ── Section header ──────────────────────────────────────────────
        if (sales.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Recent Sales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),

        // ── Sales grid ──────────────────────────────────────────────────
        if (sales.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              isDark: isDark,
              icon: Icons.bar_chart_rounded,
              message: 'No sales yet',
              sub:
                  'Your sales will appear here once readers purchase your work',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SaleListRow(sale: sales[i], isDark: isDark),
                childCount: sales.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 10, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleListRow extends StatelessWidget {
  final Sale sale;
  final bool isDark;
  const _SaleListRow({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final listing = sale.listing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      // `crossAxisAlignment.stretch` needs a bounded incoming height to
      // work — but this Row is a ListView item, which gives its children
      // unbounded height, so `stretch` here throws "BoxConstraints forces
      // an infinite height" once the list actually has a row to lay out
      // (this only surfaced once a test actually reached a populated Sales
      // list — an empty list never renders the row at all). The fixed-
      // height cover already sets the row's height; no stretch needed.
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    listing.type.badgeColor.withValues(alpha: 0.8),
                    listing.type.badgeColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(listing.type.icon, size: 26, color: Colors.white),
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
                  const SizedBox(height: 2),
                  Text(
                    'Sold to ${sale.buyerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(sale.soldAt),
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
          ),

          // Amount
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Text(
              '+\$${sale.amount.toStringAsFixed(2)}',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5C7A5C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
