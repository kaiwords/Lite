import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Shared "support this writer" tip bottom sheet.
///
/// Previously duplicated (with subtly different colors) across
/// `post_card.dart`, `audio_post_card.dart`, `audio_screen.dart`, and
/// `full_screen_post_viewer.dart`. All call sites should use [TipSheet.show]
/// instead of rolling their own copy, so tipping UI and its theming stay in
/// exactly one place.
class TipSheet extends StatefulWidget {
  final String? authorName;

  const TipSheet({super.key, this.authorName});

  /// Opens the tip sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, {String? authorName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TipSheet(authorName: authorName),
    );
  }

  @override
  State<TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<TipSheet> {
  int _amount = 2;
  static const _amounts = [1, 2, 5, 10, 20];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final handleColor = isDark ? AppColors.darkDivider : AppColors.divider;
    // Darkened accent so the white amount/button text keeps WCAG AA contrast
    // in both themes (see AppColors.accentOnFill).
    final accentOnFill = isDark
        ? AppColors.darkAccentOnFill
        : AppColors.accentOnFill;

    final title = widget.authorName == null || widget.authorName!.isEmpty
        ? 'Support this writer'
        : 'Support ${widget.authorName}';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Send a tip to show your appreciation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < _amounts.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final amt = _amounts[i];
                      final sel = amt == _amount;
                      return GestureDetector(
                        onTap: () => setState(() => _amount = amt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 48,
                          decoration: BoxDecoration(
                            color: sel ? accentOnFill : surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '\$$amt',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: sel ? Colors.white : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentOnFill,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tip of \$$_amount sent! ✨'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Send \$$_amount tip',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
