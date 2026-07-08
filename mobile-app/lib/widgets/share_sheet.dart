import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';

/// Opens a share sheet for [title]/[link]. [onShared] fires after any share
/// action (used to bump a post's share count).
Future<void> showShareSheet(
  BuildContext context, {
  required String title,
  required String link,
  VoidCallback? onShared,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(title: title, link: link, onShared: onShared),
  );
}

/// Convenience for sharing a post (copies a link and increments its count).
void sharePost(BuildContext context, WidgetRef ref, Post post) {
  showShareSheet(
    context,
    title: post.title,
    link: 'https://literature.app/post/${post.id}',
    onShared: () => ref.read(postsNotifierProvider.notifier).addShare(post.id),
  );
}

class _ShareSheet extends StatelessWidget {
  final String title;
  final String link;
  final VoidCallback? onShared;
  const _ShareSheet({required this.title, required this.link, this.onShared});

  void _done(BuildContext context, String message, {bool copy = false}) {
    if (copy) Clipboard.setData(ClipboardData(text: link));
    Navigator.pop(context);
    onShared?.call();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return SafeArea(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Share',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
                ),
              ),
            ),
            // Horizontal target row
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _Target(
                    icon: Icons.link_rounded,
                    label: 'Copy link',
                    isDark: isDark,
                    onTap: () =>
                        _done(context, 'Link copied to clipboard', copy: true),
                  ),
                  _Target(
                    icon: Icons.message_outlined,
                    label: 'Messages',
                    isDark: isDark,
                    onTap: () => _done(context, 'Shared to Messages'),
                  ),
                  _Target(
                    icon: Icons.repeat_rounded,
                    label: 'Repost',
                    isDark: isDark,
                    onTap: () => _done(context, 'Reposted to your profile'),
                  ),
                  _Target(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Save',
                    isDark: isDark,
                    onTap: () => _done(context, 'Saved'),
                  ),
                  _Target(
                    icon: Icons.ios_share_rounded,
                    label: 'More',
                    isDark: isDark,
                    onTap: () => _done(context, 'Shared'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Target extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _Target({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final labelColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
