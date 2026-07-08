import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';

class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(feedCategoryProvider);
    final visible = ref.watch(visibleCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Always show "All" first, then visible categories in enum order
    final chips = [
      FeedCategory.all,
      ...FeedCategory.values
          .where((c) => c != FeedCategory.all && visible.contains(c)),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ...chips.map(
            (cat) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _CategoryChip(
                category: cat,
                isSelected: selected == cat,
                isDark: isDark,
                onTap: () =>
                    ref.read(feedCategoryProvider.notifier).state = cat,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _AddChip(
              isDark: isDark,
              onTap: () => _showManageSheet(context, isDark),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManageCategoriesSheet(isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual chip
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final FeedCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final activeText =
        isDark ? AppColors.darkBackground : Colors.white;
    final inactiveText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category.label,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// + chip
// ─────────────────────────────────────────────────────────────────────────────

class _AddChip extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddChip({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 18,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manage categories bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ManageCategoriesSheet extends ConsumerWidget {
  final bool isDark;
  const _ManageCategoriesSheet({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleCategoriesProvider);
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final categories =
        FeedCategory.values.where((c) => c != FeedCategory.all).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                Expanded(
                  child: Text(
                    'Manage Categories',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Reset to all visible
                    for (final c in categories) {
                      if (!visible.contains(c)) {
                        ref
                            .read(visibleCategoriesProvider.notifier)
                            .toggle(c);
                      }
                    }
                  },
                  child: Text(
                    'Show all',
                    style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Choose which categories appear in your feed bar',
                style:
                    GoogleFonts.lato(fontSize: 13, color: mutedColor),
              ),
            ),
            Divider(height: 1, color: divColor),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: divColor),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isOn = visible.contains(cat);
                  return InkWell(
                    onTap: () => ref
                        .read(visibleCategoriesProvider.notifier)
                        .toggle(cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            cat.label,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: isOn
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isOn ? textColor : mutedColor,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isOn
                                ? AppColors.accent
                                : (isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.surfaceVariant),
                            borderRadius: BorderRadius.circular(13),
                            border: isOn
                                ? null
                                : Border.all(color: divColor),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 150),
                            alignment: isOn
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.textMuted),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
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
