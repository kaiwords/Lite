import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/book.dart';
import '../../models/marketplace.dart';
import '../reader/book_reader_screen.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets used across multiple marketplace tabs (Cart, Library,
// My Listings, Sales). Kept together here since Dart's `_` privacy is
// per-file — anything referenced from more than one tab file must be public.
// ─────────────────────────────────────────────────────────────────────────────

// ── Book grid card — used in Library and My Listings ────────────────────────

class BookGridCard extends ConsumerWidget {
  final MarketplaceListing listing;
  final bool isDark;
  final VoidCallback? onRemove; // shows an X button (e.g. remove from library)
  final VoidCallback? onEdit; // my listings: edit via ⋮ menu
  final VoidCallback? onDelete; // my listings: delete via ⋮ menu
  final String? accessLabel; // library: Play/Read/View
  final int? salesCount; // my listings: sold count

  const BookGridCard({
    super.key,
    required this.listing,
    required this.isDark,
    this.onRemove,
    this.onEdit,
    this.onDelete,
    this.accessLabel,
    this.salesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (accessLabel == 'Read') {
          // Map listing id → book id (extend as more books are added)
          const listingToBook = {'mBook1': 'b1'};
          final bookId = listingToBook[listing.id] ?? 'b1';
          final book = findBook(bookId) ?? mockBooks.first;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
          );
        } else {
          context.push('/marketplace/listing/${listing.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      listing.type.badgeColor.withValues(alpha: 0.85),
                      listing.type.badgeColor.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        listing.type.icon,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (onEdit != null || onDelete != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _CardMenu(
                          onEdit: onEdit,
                          onDelete: onDelete,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeChip(type: listing.type),
                    const SizedBox(height: 5),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listing.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (accessLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: listing.type.badgeColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              accessLabel!,
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: listing.type.badgeColor,
                              ),
                            ),
                          ),
                        if (salesCount != null)
                          Text(
                            '$salesCount sold',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              color: mutedColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit / delete menu overlay (My Listings) ────────────────────────────────

class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDark;
  const _CardMenu({
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: 'Options',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 16,
          color: Colors.white,
        ),
        onSelected: (v) {
          if (v == 'edit') onEdit?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => [
          if (onEdit != null)
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text('Edit', style: GoogleFonts.lato(fontSize: 13)),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFC0392B),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Delete',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: const Color(0xFFC0392B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add tile — reused by Library "Add Book" and My Listings "List a Book" ──

class AddTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const AddTile({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type filter bar (Library + My Listings) ─────────────────────────────────

class TypeFilterBar extends StatelessWidget {
  final ListingType? selected;
  final ValueChanged<ListingType?> onChanged;
  final bool isDark;
  const TypeFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: selected == null,
            color: AppColors.accent,
            onTap: () => onChanged(null),
            isDark: isDark,
          ),
          ...ListingType.values.map(
            (t) => _FilterChip(
              label: t.label,
              icon: t.icon,
              selected: selected == t,
              color: t.badgeColor,
              onTap: () => onChanged(selected == t ? null : t),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: selected ? color : mutedColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class TypeChip extends StatelessWidget {
  final ListingType type;
  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: type.badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: type.badgeColor,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  final String sub;
  const EmptyState({
    super.key,
    required this.isDark,
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: mutedColor),
            const SizedBox(height: 14),
            Text(
              message,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
