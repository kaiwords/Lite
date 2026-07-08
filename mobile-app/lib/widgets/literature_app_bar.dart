import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LiteratureAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const LiteratureAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return AppBar(
      titleSpacing: 16,
      title: Text(
        'Literature',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: iconColor, size: 26),
          tooltip: 'Create',
          onPressed: () => _showCreateChooser(context, isDark),
        ),
        IconButton(
          icon: Icon(Icons.search_rounded, color: iconColor, size: 26),
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
        ),
        IconButton(
          icon: Icon(Icons.mail_outline_rounded, color: iconColor, size: 26),
          tooltip: 'Messages',
          onPressed: () => context.push('/messages'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create chooser — asks what the user wants to upload
// ─────────────────────────────────────────────────────────────────────────────

void _showCreateChooser(BuildContext context, bool isDark) {
  final bg = isDark ? AppColors.darkSurface : AppColors.surface;
  final div = isDark ? AppColors.darkDivider : AppColors.divider;
  final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: div, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('What would you like to post?',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Share writing or audio to your feed',
                  style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
            ),
            const SizedBox(height: 4),
            _CreateOption(
              icon: Icons.edit_outlined,
              color: AppColors.accent,
              title: 'Post',
              subtitle: 'Write and share to your feed',
              isDark: isDark,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/post/new');
              },
            ),
            _CreateOption(
              icon: Icons.mic_rounded,
              color: const Color(0xFF9B5C8A),
              title: 'Audio',
              subtitle: 'Share an audio recording',
              isDark: isDark,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/post/new', extra: true);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  const _CreateOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
      title: Text(title,
          style: GoogleFonts.lato(
              fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
      subtitle: Text(subtitle,
          style: GoogleFonts.lato(fontSize: 12, color: mutedColor)),
      trailing: Icon(Icons.chevron_right_rounded, color: mutedColor),
    );
  }
}
