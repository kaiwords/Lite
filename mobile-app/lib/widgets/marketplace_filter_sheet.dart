import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/marketplace.dart';
import '../models/post.dart';
import '../providers/marketplace_provider.dart';
import '../theme/app_theme.dart';

/// Full filter bottom sheet — category + type + price sort + rating.
class MarketplaceFilterSheet extends ConsumerStatefulWidget {
  const MarketplaceFilterSheet({super.key});

  @override
  ConsumerState<MarketplaceFilterSheet> createState() =>
      _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState
    extends ConsumerState<MarketplaceFilterSheet> {
  late ContentCategory? _category;
  late ListingType? _type;
  late MarketplacePriceSort _priceSort;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _category = ref.read(marketplaceCategoryFilterProvider);
    _type = ref.read(marketplaceTabProvider);
    _priceSort = ref.read(marketplacePriceSortProvider);
  }

  void _apply() {
    ref.read(marketplaceCategoryFilterProvider.notifier).state = _category;
    ref.read(marketplaceTabProvider.notifier).state =
        _type ?? ListingType.physical;
    ref.read(marketplacePriceSortProvider.notifier).state = _priceSort;
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _category = null;
      _type = ListingType.physical;
      _priceSort = MarketplacePriceSort.none;
      _minRating = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final sectionColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      maxChildSize: 0.92,
      minChildSize: 0.50,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle + header ──────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clear,
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // ─ Category ──────────────────────────────────────────
                  _SectionLabel(label: 'Category', color: sectionColor),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _category == null,
                        isDark: isDark,
                        onTap: () => setState(() => _category = null),
                      ),
                      ...ContentCategory.values.map((c) => _FilterChip(
                            label: '${c.emoji} ${c.label}',
                            selected: _category == c,
                            isDark: isDark,
                            onTap: () => setState(() => _category = c),
                          )),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 20),

                  // ─ Type ───────────────────────────────────────────────
                  _SectionLabel(label: 'Book Type', color: sectionColor),
                  const SizedBox(height: 10),
                  Row(
                    children: ListingType.values
                        .map((t) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _FilterChip(
                                  label: t.label,
                                  selected: _type == t,
                                  isDark: isDark,
                                  onTap: () => setState(() => _type = t),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 20),

                  // ─ Price sort ─────────────────────────────────────────
                  _SectionLabel(label: 'Price', color: sectionColor),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterChip(
                          label: 'Any',
                          selected: _priceSort == MarketplacePriceSort.none,
                          isDark: isDark,
                          onTap: () => setState(
                              () => _priceSort = MarketplacePriceSort.none),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: 'Low → High',
                          selected:
                              _priceSort == MarketplacePriceSort.lowToHigh,
                          isDark: isDark,
                          onTap: () => setState(() =>
                              _priceSort = MarketplacePriceSort.lowToHigh),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: 'High → Low',
                          selected:
                              _priceSort == MarketplacePriceSort.highToLow,
                          isDark: isDark,
                          onTap: () => setState(() =>
                              _priceSort = MarketplacePriceSort.highToLow),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 20),

                  // ─ Minimum rating ──────────────────────────────────────
                  _SectionLabel(label: 'Minimum Rating', color: sectionColor),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF4C430)),
                      const SizedBox(width: 4),
                      Text(
                        _minRating == 0.0
                            ? 'Any'
                            : '${_minRating.toStringAsFixed(1)}+',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: dividerColor,
                      thumbColor: AppColors.accent,
                    ),
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (v) => setState(() => _minRating = v),
                    ),
                  ),
                ],
              ),
            ),

            // ── Apply button ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _apply,
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
