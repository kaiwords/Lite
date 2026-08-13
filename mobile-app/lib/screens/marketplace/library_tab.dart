import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/purchase_flow.dart';
import 'marketplace_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Library tab — purchased items as grid with genre + format filters
// ─────────────────────────────────────────────────────────────────────────────

class LibraryTab extends StatelessWidget {
  final bool isDark;
  const LibraryTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => _LibraryTab(isDark: isDark);
}

class _LibraryTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _LibraryTab({required this.isDark});

  @override
  ConsumerState<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<_LibraryTab> {
  ListingType? _format;
  Genre? _genre;

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToLibrarySheet(isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    final isDark = widget.isDark;

    // Genres present in the library
    final genreSeen = <Genre>{};
    for (final p in purchases) {
      if (p.listing.genre != null) genreSeen.add(p.listing.genre!);
    }
    final genres = Genre.values.where(genreSeen.contains).toList();

    final filtered = purchases.where((p) {
      if (_genre != null && p.listing.genre != _genre) return false;
      if (_format != null && p.listing.type != _format) return false;
      return true;
    }).toList();

    // First grid cell is the "Add Book" tile
    final itemCount = filtered.length + 1;

    return Column(
      children: [
        const SizedBox(height: 10),
        if (genres.isNotEmpty) ...[
          _GenreFilterBar(
            genres: genres,
            selected: _genre,
            onChanged: (g) => setState(() => _genre = g),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],
        TypeFilterBar(
          selected: _format,
          onChanged: (t) => setState(() => _format = t),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 14),
            itemCount: itemCount,
            // A faint (near-invisible) hairline between rows — enough to
            // separate one book from the next without a hard visible line.
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: (isDark ? AppColors.darkDivider : AppColors.divider)
                  .withValues(alpha: 0.4),
            ),
            itemBuilder: (_, i) {
              if (i == 0) {
                return AddListRow(
                  isDark: isDark,
                  title: 'Add Book',
                  subtitle: 'Add to your library',
                  onTap: _showAddSheet,
                );
              }
              final l = filtered[i - 1].listing;
              final label = l.type == ListingType.audio
                  ? 'Play'
                  : l.type == ListingType.ebook
                  ? 'Read'
                  : 'View';
              return BookListRow(
                listing: l,
                isDark: isDark,
                accessLabel: label,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add to Library bottom sheet — pick a marketplace book to add to the library
// ─────────────────────────────────────────────────────────────────────────────

class _AddToLibrarySheet extends ConsumerWidget {
  final bool isDark;
  const _AddToLibrarySheet({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesProvider);
    final owned = purchases.map((p) => p.listing.id).toSet();
    final catalogue = ref.watch(marketplaceListingsProvider);
    final available = catalogue.where((l) => !owned.contains(l.id)).toList();

    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
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
                  color: div,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Add to Library',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: div),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'You already own every title in the marketplace.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: available.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: div),
                      itemBuilder: (_, i) {
                        final l = available[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 40,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [
                                  l.type.badgeColor.withValues(alpha: 0.85),
                                  l.type.badgeColor.withValues(alpha: 0.35),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              l.type.icon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          subtitle: Text(
                            '${l.authorName} · ${l.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () => runPurchaseFlow(context, ref, [l]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                // accentOnFill (darker than accent) keeps the
                                // white label at WCAG AA contrast.
                                color: isDark
                                    ? AppColors.darkAccentOnFill
                                    : AppColors.accentOnFill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l.price,
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Genre filter bar (Library)
// ─────────────────────────────────────────────────────────────────────────────

class _GenreFilterBar extends StatelessWidget {
  final List<Genre> genres;
  final Genre? selected;
  final ValueChanged<Genre?> onChanged;
  final bool isDark;
  const _GenreFilterBar({
    required this.genres,
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
          _GenreChip(
            label: 'All Genres',
            emoji: '✦',
            color: AppColors.accent,
            selected: selected == null,
            onTap: () => onChanged(null),
            isDark: isDark,
          ),
          ...genres.map(
            (g) => _GenreChip(
              label: g.label,
              emoji: g.emoji,
              color: g.colors[0],
              selected: selected == g,
              onTap: () => onChanged(selected == g ? null : g),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _GenreChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
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
              Text(emoji, style: const TextStyle(fontSize: 12)),
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
