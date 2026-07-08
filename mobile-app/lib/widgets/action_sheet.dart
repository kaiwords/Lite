import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class ActionSheetItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const ActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
}

/// A simple bottom sheet of tappable actions. Each item pops the sheet, then
/// runs its callback.
Future<void> showActionSheet(
  BuildContext context, {
  String? title,
  required List<ActionSheetItem> items,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.darkSurface : AppColors.surface;
  final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
  final titleColor =
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: divColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: mutedColor)),
                ),
              ),
            ...items.map((item) {
              final color = item.destructive ? AppColors.like : titleColor;
              return ListTile(
                leading: Icon(item.icon, color: color, size: 22),
                title: Text(item.label,
                    style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: color)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  item.onTap();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
