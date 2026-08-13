import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/marketplace.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../services/stripe_service.dart';
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
        // ── Stats row — no card backgrounds, just thin divider lines
        // between cells (same pattern as the profile screen's stats row) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Builder(builder: (context) {
              final div =
                  isDark ? AppColors.darkDivider : AppColors.divider;
              return Row(
                children: [
                  _StatCard(
                    label: 'Total Earned',
                    value: '\$${totalEarned.toStringAsFixed(2)}',
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 48, color: div),
                  _StatCard(
                    label: 'Items Sold',
                    value: '${sales.length}',
                    icon: Icons.shopping_bag_rounded,
                    color: const Color(0xFF5C7A5C),
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 48, color: div),
                  _StatCard(
                    label: 'Listings',
                    value: '${myListings.length}',
                    icon: Icons.list_alt_rounded,
                    color: const Color(0xFF4A6FA5),
                    isDark: isDark,
                  ),
                ],
              );
            }),
          ),
        ),

        // ── Stripe payouts setup — shown until Connect onboarding clears ──
        SliverToBoxAdapter(
          child: _PayoutSetupBanner(isDark: isDark),
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
            padding: const EdgeInsets.only(bottom: 24),
            // A faint (near-invisible) hairline between rows — matches
            // Cart/Library/My Listings. SliverList has no `.separated`
            // constructor, so the divider is interleaved by hand: even
            // indices are rows, odd indices are the divider between them.
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                if (i.isOdd) {
                  return Divider(
                    height: 1,
                    color: (isDark ? AppColors.darkDivider : AppColors.divider)
                        .withValues(alpha: 0.4),
                  );
                }
                return _SaleListRow(sale: sales[i ~/ 2], isDark: isDark);
              }, childCount: sales.length * 2 - 1),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payout setup banner — prompts Stripe Connect onboarding until the
// seller's connected account can actually receive transfers. Buying a
// listing from this seller is blocked server-side
// (stripe-create-checkout) until charges_enabled is true, so this is the
// entry point that unblocks their own sales.
// ─────────────────────────────────────────────────────────────────────────────

class _PayoutSetupBanner extends ConsumerStatefulWidget {
  final bool isDark;
  const _PayoutSetupBanner({required this.isDark});

  @override
  ConsumerState<_PayoutSetupBanner> createState() => _PayoutSetupBannerState();
}

class _PayoutSetupBannerState extends ConsumerState<_PayoutSetupBanner> {
  bool _busy = false;

  Future<void> _startOnboarding() async {
    setState(() => _busy = true);
    try {
      await StripeService.startSellerOnboarding();
    } on StripeCheckoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    setState(() => _busy = true);
    await ref.read(sellerStripeStatusProvider.notifier).refresh(userId);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(sellerStripeStatusProvider);
    if (status.chargesEnabled) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.hasAccount ? 'Finish setting up payouts' : 'Set up payouts',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.hasAccount
                      ? "You've started Stripe onboarding — finish it to receive payouts."
                      : 'Connect a Stripe account to get paid when your books sell.',
                  style: GoogleFonts.lato(fontSize: 11.5, color: mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (status.hasAccount)
            TextButton(
              onPressed: _refreshStatus,
              child: const Text("I'm done"),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: fill,
                foregroundColor: Colors.white,
              ),
              onPressed: _startOnboarding,
              child: const Text('Connect'),
            ),
        ],
      ),
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
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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

class _SaleListRow extends ConsumerStatefulWidget {
  final Sale sale;
  final bool isDark;
  const _SaleListRow({required this.sale, required this.isDark});

  @override
  ConsumerState<_SaleListRow> createState() => _SaleListRowState();
}

class _SaleListRowState extends ConsumerState<_SaleListRow> {
  bool _confirming = false;

  Future<void> _confirmMeetup() async {
    final sellerId = ref.read(currentUserProvider)?.id;
    if (sellerId == null) return;
    setState(() => _confirming = true);
    try {
      await ref
          .read(salesProvider.notifier)
          .confirmMeetup(widget.sale.orderItemId, sellerId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sale = widget.sale;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final listing = sale.listing;
    final isPendingMeetup =
        sale.shippingMethod == ShippingMethod.meetup && !sale.meetupConfirmed;

    // No background/border/margin/separator line — sale rows sit flush
    // against each other with nothing between them.
    // `crossAxisAlignment.stretch` needs a bounded incoming height to
    // work — but this Row is a ListView item, which gives its children
    // unbounded height, so `stretch` here throws "BoxConstraints forces
    // an infinite height" once the list actually has a row to lay out
    // (this only surfaced once a test actually reached a populated Sales
    // list — an empty list never renders the row at all). The fixed-
    // height cover already sets the row's height; no stretch needed.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Cover
            Container(
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
        if (sale.shippingMethod == ShippingMethod.meetup)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 14, 12),
            child: Row(
              children: [
                const SizedBox(width: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sale.meetupPlace != null)
                        Text(
                          'Meetup: ${sale.meetupPlace}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            color: mutedColor,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_confirming)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isPendingMeetup)
                  TextButton(
                    onPressed: _confirmMeetup,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Confirm meetup',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF5C7A5C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confirmed',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5C7A5C),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
