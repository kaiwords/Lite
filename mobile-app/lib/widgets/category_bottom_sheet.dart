import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';

class CategoryBottomSheet extends ConsumerWidget {
  const CategoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(feedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
              child: Text(
                'Filter by Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Divider(height: 16, color: isDark ? AppColors.darkDivider : AppColors.divider),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: FeedCategory.values.map((cat) {
                  final isSelected = selected == cat;
                  return InkWell(
                    onTap: () {
                      ref.read(feedCategoryProvider.notifier).state = cat;
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.label,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? activeColor : textColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded, color: activeColor, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
