import 'package:flutter/material.dart';

import '../models/marketplace.dart';
import '../theme/app_theme.dart';

/// Shows a shipping-method picker for every Physical listing in [listings]
/// that has at least one seller-supported [ShippingMethod] configured —
/// skipped entirely (returns `{}` immediately, no sheet shown) if none of
/// them need it. Returns `null` if the buyer backs out, which the caller
/// should treat as "cancel the purchase" the same way a dismissed Payment
/// Sheet is.
Future<Map<String, ShippingSelection>?> pickShippingMethods(
  BuildContext context,
  List<MarketplaceListing> listings,
) async {
  final needsChoice = listings
      .where(
        (l) => l.type == ListingType.physical && l.shippingMethods.isNotEmpty,
      )
      .toList();
  if (needsChoice.isEmpty) return const {};

  return showModalBottomSheet<Map<String, ShippingSelection>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShippingMethodSheet(listings: needsChoice),
  );
}

class _ShippingMethodSheet extends StatefulWidget {
  final List<MarketplaceListing> listings;
  const _ShippingMethodSheet({required this.listings});

  @override
  State<_ShippingMethodSheet> createState() => _ShippingMethodSheetState();
}

class _ShippingMethodSheetState extends State<_ShippingMethodSheet> {
  late final Map<String, ShippingMethod> _selected;
  final Map<String, TextEditingController> _placeCtrls = {};

  @override
  void initState() {
    super.initState();
    _selected = {
      for (final l in widget.listings) l.id: l.shippingMethods.first,
    };
    for (final l in widget.listings) {
      if (l.shippingMethods.contains(ShippingMethod.meetup)) {
        _placeCtrls[l.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _placeCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() {
    // If Meetup is the chosen method for a listing, a suggested place/time
    // is required — there's nothing to confirm otherwise.
    for (final l in widget.listings) {
      if (_selected[l.id] == ShippingMethod.meetup &&
          (_placeCtrls[l.id]?.text.trim().isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suggest a place/time to meet for "${l.title}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    final result = {
      for (final l in widget.listings)
        l.id: ShippingSelection(
          method: _selected[l.id]!,
          meetupPlace: _selected[l.id] == ShippingMethod.meetup
              ? _placeCtrls[l.id]!.text.trim()
              : null,
        ),
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final surfaceVariant = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Shipping & Delivery',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'How would you like to get this from the seller?',
                style: AppFonts.ui(fontSize: 13, color: labelColor),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < widget.listings.length; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                _ListingShippingCard(
                  listing: widget.listings[i],
                  selected: _selected[widget.listings[i].id]!,
                  onSelect: (m) =>
                      setState(() => _selected[widget.listings[i].id] = m),
                  placeController: _placeCtrls[widget.listings[i].id],
                  isDark: isDark,
                  titleColor: titleColor,
                  labelColor: labelColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  surfaceVariant: surfaceVariant,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(
                    'Continue to Payment',
                    style: AppFonts.ui(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingShippingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final ShippingMethod selected;
  final ValueChanged<ShippingMethod> onSelect;
  final TextEditingController? placeController;
  final bool isDark;
  final Color titleColor;
  final Color labelColor;
  final Color mutedColor;
  final Color borderColor;
  final Color surfaceVariant;
  const _ListingShippingCard({
    required this.listing,
    required this.selected,
    required this.onSelect,
    required this.placeController,
    required this.isDark,
    required this.titleColor,
    required this.labelColor,
    required this.mutedColor,
    required this.borderColor,
    required this.surfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.ui(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: listing.shippingMethods.map((m) {
            final sel = selected == m;
            return GestureDetector(
              onTap: () => onSelect(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sel ? AppColors.accent : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m.icon,
                      size: 14,
                      color: sel ? AppColors.accent : labelColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      m.label,
                      style: AppFonts.ui(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.accent : labelColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selected == ShippingMethod.meetup && placeController != null) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: placeController,
              style: AppFonts.ui(fontSize: 14, color: titleColor),
              decoration: InputDecoration(
                hintText: 'Suggest a place/time, e.g. "Sat 2pm, Main St Cafe"',
                hintStyle: AppFonts.ui(fontSize: 13, color: mutedColor),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "The seller confirms after you pay. You'll see its status in your Library.",
            style: AppFonts.ui(fontSize: 11, color: mutedColor),
          ),
        ],
      ],
    );
  }
}
