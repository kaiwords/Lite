import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../models/marketplace.dart';
import '../../utils/cover_image.dart';
import '../reader/book_reader_screen.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets used across multiple marketplace tabs (Cart, Library,
// My Listings, Sales). Kept together here since Dart's `_` privacy is
// per-file — anything referenced from more than one tab file must be public.
// ─────────────────────────────────────────────────────────────────────────────

// ── Book list row — used in Library and My Listings ─────────────────────────
// Minimal by design: cover on the left, the book's title only — no type
// chip, author, price, or sold count. Whatever trailing action the tab
// needs (remove from library, or edit/delete a listing) sits on the right.

class BookListRow extends StatelessWidget {
  final MarketplaceListing listing;
  final bool isDark;
  final VoidCallback? onRemove; // library: remove from library
  final VoidCallback? onEdit; // my listings: edit via ⋮ menu
  final VoidCallback? onDelete; // my listings: delete via ⋮ menu
  final String?
  accessLabel; // 'Read' opens the book reader instead of the listing detail

  const BookListRow({
    super.key,
    required this.listing,
    required this.isDark,
    this.onRemove,
    this.onEdit,
    this.onDelete,
    this.accessLabel,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    // No background/border/rounded corners/separator line — rows sit flush
    // against each other with nothing between them.
    return GestureDetector(
      onTap: () {
        if (accessLabel == 'Read') {
          // Map listing id → book id (extend as more books are added)
          const listingToBook = {'mBook1': 'b1'};
          final bookId = listingToBook[listing.id];
          final book = bookId == null ? null : findBook(bookId);
          if (book == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This book is not available yet')),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
          );
        } else {
          context.push('/marketplace/listing/${listing.id}');
        }
      },
      child: Row(
        children: [
          // Cover
          _RowCover(listing: listing),
          const SizedBox(width: 12),

          // Title only
          Expanded(
            child: Text(
              listing.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),

          // Trailing action
          if (onRemove != null)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 20, color: mutedColor),
              tooltip: 'Remove',
              onPressed: onRemove,
            )
          else if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: mutedColor),
              tooltip: 'Options',
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
                        Text('Edit', style: AppFonts.ui(fontSize: 13)),
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
                          style: AppFonts.ui(
                            fontSize: 13,
                            color: const Color(0xFFC0392B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// Small (56×72) cover thumbnail — the seller's picked photo when there is
// one, otherwise the type-tinted gradient placeholder this app has always
// shown for listings without real cover art.
class _RowCover extends StatelessWidget {
  final MarketplaceListing listing;
  const _RowCover({required this.listing});

  @override
  Widget build(BuildContext context) {
    final coverImage = coverImageFile(listing.coverImageUrl);
    if (coverImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(coverImage, width: 56, height: 72, fit: BoxFit.cover),
      );
    }
    final color = listing.coverColor != null
        ? Color(listing.coverColor!)
        : listing.type.badgeColor;
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(listing.type.icon, size: 24, color: Colors.white),
    );
  }
}

// ── Add row — reused by Library "Add Book" and My Listings "List a Book" ───

class AddListRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const AddListRow({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 72,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.ui(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: mutedColor),
          const SizedBox(width: 8),
        ],
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
                style: AppFonts.ui(
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

// ── Shared cover tint palette ────────────────────────────────────────────────
// Used to tint StripedCover placeholders across Books (grid/list) and Cart so
// the same listing reads with a consistent color wherever it appears.

const coverPalette = [
  Color(0xFFD9C9AE), // tan
  Color(0xFFBFD8E0), // blue
  Color(0xFFE3C6CE), // pink
  Color(0xFFC3D9C1), // green
  Color(0xFFCEC9E3), // lavender
  Color(0xFFDAD3C2), // sand
];

// ── Striped placeholder cover ────────────────────────────────────────────────
// This app has no real cover art, so every listing shows the same kind of
// diagonal-stripe "cover" skeleton, tinted per-listing by [color]. Shared by
// the Books grid/list tiles and the Cart row so covers read consistently
// across the marketplace.

class StripedCover extends StatelessWidget {
  final Color color;
  final double? width;
  final double height;
  final double borderRadius;
  final bool showLabel;
  const StripedCover({
    super.key,
    required this.color,
    required this.height,
    this.width,
    this.borderRadius = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _StripePainter(color: color),
          child: showLabel
              ? Center(
                  child: Text(
                    'cover',
                    style: AppFonts.ui(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Listing cover — real photo when the seller picked one, else the ─────────
// striped placeholder above (tinted by the seller's chosen design color when
// set, otherwise the caller's per-tile fallback from [coverPalette]).

class ListingCover extends StatelessWidget {
  final MarketplaceListing listing;
  final Color fallbackColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool showLabel;
  const ListingCover({
    super.key,
    required this.listing,
    required this.fallbackColor,
    required this.height,
    this.width,
    this.borderRadius = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final coverImage = coverImageFile(listing.coverImageUrl);
    if (coverImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          coverImage,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    }
    return StripedCover(
      color: listing.coverColor != null
          ? Color(listing.coverColor!)
          : fallbackColor,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showLabel: showLabel,
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  const _StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.35),
    );

    final stripePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 7;
    const gap = 13.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.color != color;
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
        style: AppFonts.ui(
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
              style: AppFonts.display(
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
              style: AppFonts.ui(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
