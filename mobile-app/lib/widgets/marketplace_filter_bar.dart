import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/post.dart';
import '../providers/marketplace_provider.dart';
import '../theme/app_theme.dart';
import 'marketplace_filter_sheet.dart';

class MarketplaceFilterBar extends ConsumerWidget {
  const MarketplaceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCategory = ref.watch(marketplaceCategoryFilterProvider);
    final priceSort = ref.watch(marketplacePriceSortProvider);
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Add Listing
                _AddListingButton(isDark: isDark),
                const SizedBox(width: 8),
                // Category chip
                _CategoryChip(
                  activeCategory: activeCategory,
                  isDark: isDark,
                  onTap: () => _showCategoryPicker(context, ref, isDark),
                ),
                const SizedBox(width: 8),
                // Price sort
                _PriceSortChip(priceSort: priceSort, isDark: isDark, ref: ref),
                const Spacer(),
                // Full filter button
                _FilterIconButton(
                  isDark: isDark,
                  onTap: () => _showFilterSheet(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
        ],
      ),
    );
  }

  void _showCategoryPicker(
      BuildContext context, WidgetRef ref, bool isDark) {
    final categories = [null, ...ContentCategory.values];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        current: ref.read(marketplaceCategoryFilterProvider),
        isDark: isDark,
        onSelected: (c) =>
            ref.read(marketplaceCategoryFilterProvider.notifier).state = c,
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MarketplaceFilterSheet(),
    );
  }
}

// ── Add Listing button ────────────────────────────────────────────────────────

class _AddListingButton extends StatelessWidget {
  final bool isDark;
  const _AddListingButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add Listing — coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Add Listing',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final ContentCategory? activeCategory;
  final bool isDark;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.activeCategory,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCategory != null;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final label = isActive ? activeCategory!.label : 'Category';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16,
                color: isActive ? activeColor : inactiveColor),
          ],
        ),
      ),
    );
  }
}

// ── Price sort chip ───────────────────────────────────────────────────────────

class _PriceSortChip extends StatelessWidget {
  final MarketplacePriceSort priceSort;
  final bool isDark;
  final WidgetRef ref;
  const _PriceSortChip(
      {required this.priceSort, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isActive = priceSort != MarketplacePriceSort.none;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    IconData icon;
    String label;
    MarketplacePriceSort next;
    switch (priceSort) {
      case MarketplacePriceSort.none:
        icon = Icons.swap_vert_rounded;
        label = 'Price';
        next = MarketplacePriceSort.lowToHigh;
      case MarketplacePriceSort.lowToHigh:
        icon = Icons.arrow_upward_rounded;
        label = 'Low → High';
        next = MarketplacePriceSort.highToLow;
      case MarketplacePriceSort.highToLow:
        icon = Icons.arrow_downward_rounded;
        label = 'High → Low';
        next = MarketplacePriceSort.none;
    }

    return GestureDetector(
      onTap: () =>
          ref.read(marketplacePriceSortProvider.notifier).state = next,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? activeColor : inactiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter icon button ────────────────────────────────────────────────────────

class _FilterIconButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _FilterIconButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Icons.tune_rounded,
        size: 22,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      tooltip: 'Filters',
    );
  }
}

// ── Category picker bottom sheet ──────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  final List<ContentCategory?> categories;
  final ContentCategory? current;
  final bool isDark;
  final ValueChanged<ContentCategory?> onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.current,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.80,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Filter by Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSelected = cat == current;
                  final label = cat == null ? 'All Categories' : cat.label;
                  final emoji = cat == null ? '📚' : cat.emoji;
                  return InkWell(
                    onTap: () {
                      onSelected(cat);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? activeColor
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                size: 18, color: activeColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
