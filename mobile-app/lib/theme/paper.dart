import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The "real book" layer: paper grain over the whole app, page-shaped
/// sheets, printer's ornaments, and the route transition. The page-curling
/// pager lives in book_pager.dart.

// ─────────────────────────────────────────────────────────────────────────────
// Paper grain
// ─────────────────────────────────────────────────────────────────────────────

/// Lays a faint paper texture (fibres, specks, a soft vignette like the edge
/// of an old page) over everything below it, so every screen reads as
/// printed on paper without each screen having to know about it. Mounted
/// once in `MaterialApp.builder`. Purely decorative: it ignores touches,
/// is hidden from screen readers, and is painted once and cached.
class PaperGrain extends StatelessWidget {
  final Widget child;
  const PaperGrain({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _GrainPainter(isDark: isDark)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  final bool isDark;
  _GrainPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Fixed seed: the texture is identical on every frame and every launch,
    // like a real sheet of paper.
    final rnd = Random(7);
    final area = size.width * size.height;

    // Specks: tiny dots of darker (or, at night, lighter) pulp.
    final speckCount = (area / 90).round();
    final specks = Float32List(speckCount * 2);
    for (var i = 0; i < speckCount; i++) {
      specks[i * 2] = rnd.nextDouble() * size.width;
      specks[i * 2 + 1] = rnd.nextDouble() * size.height;
    }
    final speckColor = isDark
        ? const Color(0xFFFFF4DC).withValues(alpha: 0.035)
        : const Color(0xFF5A4630).withValues(alpha: 0.05);
    canvas.drawRawPoints(
      ui.PointMode.points,
      specks,
      Paint()
        ..color = speckColor
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    // Fibres: short, faint strokes running mostly along the grain.
    final fibrePaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFF4DC).withValues(alpha: 0.025)
          : const Color(0xFF6E5638).withValues(alpha: 0.045)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    final fibreCount = (area / 2600).round();
    for (var i = 0; i < fibreCount; i++) {
      final start = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final angle = (rnd.nextDouble() - 0.5) * 0.9;
      final length = 4 + rnd.nextDouble() * 10;
      canvas.drawLine(
        start,
        start + Offset(cos(angle) * length, sin(angle) * length),
        fibrePaint,
      );
    }

    // Vignette: page edges a touch darker than the middle.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [
            Colors.transparent,
            (isDark ? Colors.black : const Color(0xFF6E5638)).withValues(
              alpha: isDark ? 0.22 : 0.08,
            ),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page sheet
// ─────────────────────────────────────────────────────────────────────────────

/// A single page of a bound book: the sheet itself, the fore-edge of the
/// page block (dozens of fine page lines) showing below and to the right,
/// the gutter shadow on the left where the page curves into the binding,
/// and a soft shadow.
/// Use it for anything that should feel like a physical page (post cards,
/// menu tiles, listing cards).
class PaperSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;

  /// Show the page block and binding. Turn off for small or dense items.
  final bool stacked;

  const PaperSheet({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.stacked = true,
  });

  static const radius = BorderRadius.all(Radius.circular(3));

  /// How far the page block shows past the sheet, right and bottom.
  static const _blockDepth = 5.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = isDark ? AppColors.darkSurface : AppColors.surface;
    final edge = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final border = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final ink = isDark ? Colors.black : const Color(0xFF5A4630);

    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: page,
        borderRadius: radius,
        border: Border.all(color: border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Gutter: the page darkens toward the spine as it curves into the
      // binding. A foreground decoration, so it never takes touches.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: stacked
            ? BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: [
                    ink.withValues(alpha: isDark ? 0.35 : 0.13),
                    ink.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.06],
                ),
              )
            : const BoxDecoration(),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );

    if (!stacked) return Padding(padding: margin, child: sheet);

    return Padding(
      padding: margin,
      // Room for the page block, so it never overlaps neighbours.
      child: Padding(
        padding: const EdgeInsets.only(right: _blockDepth, bottom: _blockDepth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _PageBlockPainter(
                    edge: edge,
                    line: Color.lerp(edge, ink, isDark ? 0.45 : 0.22)!,
                    depth: _blockDepth,
                  ),
                ),
              ),
            ),
            sheet,
          ],
        ),
      ),
    );
  }
}

/// The fore-edge of a book's page block: every page beneath the top one,
/// each a fraction of a millimetre further out, so their edges read as a
/// run of fine lines along the right and bottom.
class _PageBlockPainter extends CustomPainter {
  final Color edge;
  final Color line;
  final double depth;
  _PageBlockPainter({
    required this.edge,
    required this.line,
    required this.depth,
  });

  static const _pages = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = edge;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    // Deepest page first, so each nearer page covers all but its edge.
    for (var i = _pages; i >= 1; i--) {
      final d = depth * i / _pages;
      final rrect = PaperSheet.radius.toRRect(
        Rect.fromLTWH(d, d, size.width, size.height),
      );
      canvas.drawRRect(rrect, fill);
      // Alternate line weight a touch, like uneven pages in a real block.
      stroke.color = line.withValues(alpha: i.isEven ? 0.55 : 0.8);
      canvas.drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(_PageBlockPainter old) =>
      old.edge != edge || old.line != line || old.depth != depth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ornament
// ─────────────────────────────────────────────────────────────────────────────

/// A printer's section break: rule, fleuron, rule.
class Ornament extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const Ornament({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final rule = Expanded(
      child: Divider(color: color.withValues(alpha: 0.35), thickness: 0.6),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            rule,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('❦', style: TextStyle(fontSize: 14, color: color)),
            ),
            rule,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page-turn transition
// ─────────────────────────────────────────────────────────────────────────────

/// Route transition like laying a fresh sheet on top of the one you were
/// reading: the new page slides in from the right edge casting a soft
/// shadow along its leading edge, while the page beneath eases a little to
/// the left and dims as it is covered. Popping lifts the sheet back off.
/// With reduced motion on, it is a plain fade.
class BookPageTransitionsBuilder extends PageTransitionsBuilder {
  const BookPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        final inT = Curves.easeOutCubic.transform(animation.value);
        final covered = Curves.easeOutCubic.transform(secondaryAnimation.value);
        final shadow = inT < 1 ? (1 - inT).clamp(0.0, 1.0) : 0.0;
        return Transform.translate(
          offset: Offset((1 - inT) * width - covered * width * 0.25, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                if (shadow > 0)
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: (isDark ? 0.55 : 0.25) * min(1, shadow * 4),
                    ),
                    blurRadius: 16,
                    offset: const Offset(-4, 0),
                  ),
              ],
            ),
            child: Stack(
              children: [
                child!,
                if (covered > 0.001)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: covered * (isDark ? 0.3 : 0.12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
