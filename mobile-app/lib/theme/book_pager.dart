import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A horizontal pager that reads like a real book instead of a slideshow.
///
/// Swiping forward curls the current page off the spine (its left edge): the
/// paper bends around a soft roll that follows the finger, the back of the
/// sheet comes over the top, and the page casts a shadow on the next page
/// lying still underneath. Swiping back plays the same curl in reverse,
/// laying the previous page back down. The fore-edge of the book block
/// (the stack of remaining pages) shows along the right and bottom edges
/// and thins as the reader gets through the book, with a soft gutter
/// shadow at the binding.
///
/// Flings and snapping use the normal [PageView] physics, so this is a
/// drop-in replacement for `PageView.builder` (same controller, same
/// `onPageChanged`). With reduced motion on, pages slide instead.
class BookPageView extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  /// The paper colour of each page. Pages must be opaque so the page
  /// underneath stays hidden until it is uncovered; defaults to the
  /// enclosing [Scaffold]'s background.
  final Color? pageColor;

  const BookPageView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.pageColor,
  });

  double _currentPage() {
    if (controller.hasClients && controller.position.hasContentDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        pageColor ??
        Scaffold.maybeOf(context)?.widget.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // One sheet of paper: the content, the binding's shadow along the spine,
    // and (when it's the top of the pile) the edges of the pages beneath.
    Widget page(BuildContext context, int i, {required bool onPile}) => _Page(
      color: color,
      isDark: isDark,
      pagesBeneath: onPile ? itemCount - 1 - i : 0,
      child: itemBuilder(context, i),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return PageView.builder(
        controller: controller,
        itemCount: itemCount,
        onPageChanged: onPageChanged,
        itemBuilder: (context, i) => page(context, i, onPile: true),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return PageView.builder(
          controller: controller,
          itemCount: itemCount,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) => AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              // How far page i has been turned: 0 = lying open, approaching
              // 1 = turned all the way over.
              final turn = _currentPage() - i;
              if (turn <= -1 || turn >= 1 || turn == 0) {
                return page(context, i, onPile: true);
              }
              // The next page is drawn by the slot before it (underneath the
              // curling page), so its own slot stays empty mid-turn.
              if (turn < 0) return const SizedBox.expand();
              return Transform.translate(
                // PageView slides this slot left as the page turns; hold it
                // still so the page curls on a book that stays put.
                offset: Offset(turn * width, 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (i + 1 < itemCount) page(context, i + 1, onPile: true),
                    _PageCurl(
                      turn: turn,
                      backColor: color,
                      isDark: isDark,
                      child: page(context, i, onPile: false),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One page, with the binding shadow and the book block's edges
// ─────────────────────────────────────────────────────────────────────────────

class _Page extends StatelessWidget {
  final Color color;
  final bool isDark;
  final int pagesBeneath;
  final Widget child;
  const _Page({
    required this.color,
    required this.isDark,
    required this.pagesBeneath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: CustomPaint(
        foregroundPainter: _PageEdgesPainter(
          pagesBeneath: pagesBeneath,
          isDark: isDark,
          paper: color,
        ),
        child: child,
      ),
    );
  }
}

/// The gutter shadow where the page disappears into the binding, and the
/// fore-edge of the pages still to read: fine lines of paper along the
/// right and bottom that thin out as the book nears its end.
class _PageEdgesPainter extends CustomPainter {
  final int pagesBeneath;
  final bool isDark;
  final Color paper;
  _PageEdgesPainter({
    required this.pagesBeneath,
    required this.isDark,
    required this.paper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gutter: the paper curving down into the spine.
    const gutter = 26.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gutter, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: isDark ? 0.34 : 0.13),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, gutter, size.height)),
    );

    // Fore-edge: one line per few pages, capped so it reads as a thickness.
    final layers = (pagesBeneath / 3).ceil().clamp(0, 6);
    if (layers == 0) return;
    final edgeLine = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF6E5638)).withValues(
        alpha: isDark ? 0.55 : 0.28,
      )
      ..strokeWidth = 0.7;
    final paperFill = Paint()..color = Color.lerp(paper, Colors.black, 0.04)!;
    const step = 1.6;
    final thickness = layers * step;
    // Paper showing past the top sheet, then a hairline per page layer,
    // each sheet sitting a hair lower and further right than the one above.
    canvas.drawRect(
      Rect.fromLTRB(size.width - thickness, 6, size.width, size.height),
      paperFill,
    );
    canvas.drawRect(
      Rect.fromLTRB(6, size.height - thickness, size.width, size.height),
      paperFill,
    );
    for (var k = 1; k <= layers; k++) {
      final x = size.width - thickness + k * step - step / 2;
      final y = size.height - thickness + k * step - step / 2;
      canvas.drawLine(Offset(x, 6.0 + k * step), Offset(x, y), edgeLine);
      canvas.drawLine(Offset(6.0 + k * step, y), Offset(x, y), edgeLine);
    }
    // Where the top sheet ends.
    canvas.drawLine(
      Offset(size.width - thickness, 6),
      Offset(size.width - thickness, size.height - thickness),
      edgeLine,
    );
    canvas.drawLine(
      Offset(6, size.height - thickness),
      Offset(size.width - thickness, size.height - thickness),
      edgeLine,
    );
  }

  @override
  bool shouldRepaint(_PageEdgesPainter old) =>
      old.pagesBeneath != pagesBeneath ||
      old.isDark != isDark ||
      old.paper != paper;
}

// ─────────────────────────────────────────────────────────────────────────────
// The curl
// ─────────────────────────────────────────────────────────────────────────────

/// Paints its child as a sheet of paper curling off the spine.
///
/// The page is modelled as a sheet wrapped around a roll whose axis runs top
/// to bottom. Everything left of the roll lies flat; the part on the roll
/// bends (drawn as thin vertical strips, each squeezed by how far it has
/// rotated and shaded by how far it faces away from the light); past half a
/// turn the back of the sheet comes over the top and lies flat again,
/// showing faint show-through of the printing on the other side.
class _PageCurl extends SingleChildRenderObjectWidget {
  final double turn;
  final Color backColor;
  final bool isDark;
  const _PageCurl({
    required this.turn,
    required this.backColor,
    required this.isDark,
    required Widget super.child,
  });

  @override
  _RenderPageCurl createRenderObject(BuildContext context) =>
      _RenderPageCurl(turn: turn, backColor: backColor, isDark: isDark);

  @override
  void updateRenderObject(BuildContext context, _RenderPageCurl renderObject) {
    renderObject
      ..turn = turn
      ..backColor = backColor
      ..isDark = isDark;
  }
}

class _RenderPageCurl extends RenderProxyBox {
  _RenderPageCurl({
    required double turn,
    required Color backColor,
    required bool isDark,
  }) : _turn = turn,
       _backColor = backColor,
       _isDark = isDark;

  double _turn;
  set turn(double v) {
    if (v == _turn) return;
    _turn = v;
    markNeedsPaint();
  }

  Color _backColor;
  set backColor(Color v) {
    if (v == _backColor) return;
    _backColor = v;
    markNeedsPaint();
  }

  bool _isDark;
  set isDark(bool v) {
    if (v == _isDark) return;
    _isDark = v;
    markNeedsPaint();
  }

  // The sheet is not touchable while it is in the air.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  static const _strips = 24;
  // Perspective strength: how much nearer (bigger) paper gets as it rises.
  static const _depth = 0.0011;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    // The curl draws the page several times through canvas clips and
    // transforms, which composited layers inside the page would escape.
    // If the page has any, slide it instead of curling it.
    if (child.needsCompositing) {
      context.paintChild(child, offset.translate(-_turn * size.width, 0));
      return;
    }

    final w = size.width;
    final h = size.height;
    final t = _turn.clamp(0.0, 1.0);

    // The sheet, from the spine outward: lying flat up to the fold, bent
    // round a soft roll through angle [lift], then carried on as a straight
    // flap rising off the book at that same angle. The fold travels from
    // the page edge to the spine while the flap lifts, stands edge-on
    // halfway through, and lies over on its back by the end.
    final lift = pi * Curves.easeInOutSine.transform(t);
    final fold = w * (1 - t);
    final r = w * 0.14 * (1 - t); // the bend tightens as the page goes over
    final arc = r * lift;
    final flapStart = fold + arc; // where the flap leaves the roll, on paper
    final flapLength = max(0.0, w - flapStart);
    // Where the flap starts, on screen, and how high it is off the page.
    final rollEndX = fold + r * sin(lift);
    final rollEndZ = r * (1 - cos(lift));
    final flapEndX = rollEndX + flapLength * cos(lift);
    final presence = (t * 10).clamp(0.0, 1.0) * (1 - t).clamp(0.0, 1.0);
    final dark = _isDark;

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // 1. The part of the page still lying flat on the book.
    if (fold > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, fold, h));
      context.paintChild(child, Offset.zero);
      canvas.restore();
    }

    // 2. The lifted sheet's shadow on the next page, to its right. It
    //    spreads and softens the higher the sheet is off the page.
    final rightmost = max(fold + r * sin(min(lift, pi / 2)), flapEndX);
    final spread = 10 + w * 0.16 * sin(lift);
    _shadow(
      canvas,
      Rect.fromLTRB(rightmost, 0, rightmost + spread, h),
      (dark ? 0.55 : 0.3) * presence,
      towardRight: true,
    );

    // 3. Once the flap is over, its shadow falls on the flat page beside
    //    its free edge.
    if (lift > pi / 2 && fold > 0) {
      final soft = 8 + 26 * sin(lift);
      final edge = max(flapEndX, 0.0);
      _shadow(
        canvas,
        Rect.fromLTRB(edge - soft, 0, edge, h),
        (dark ? 0.4 : 0.2) * presence,
        towardRight: false,
      );
    }

    // 4. The roll, in thin strips: each squeezed by how far it has turned,
    //    a touch taller as it comes nearer, shaded as it faces away from
    //    the light. Past a quarter turn we see the back of the paper.
    final backPaint = Paint()..color = _backColor;
    final ds = arc / _strips;
    for (var k = 0; k < _strips && ds > 0.01; k++) {
      final a0 = k * ds / r;
      final a1 = (k + 1) * ds / r;
      final mid = (a0 + a1) / 2;
      final x0 = fold + r * sin(a0);
      final x1 = fold + r * sin(a1);
      final sy = 1 / (1 - _depth * r * (1 - cos(mid)));
      final left = min(x0, x1) - 0.4; // overlap hides seams between strips
      final right = max(x0, x1) + 0.4;
      canvas.save();
      canvas.translate(0, h / 2);
      canvas.scale(1, sy);
      canvas.translate(0, -h / 2);
      canvas.clipRect(Rect.fromLTRB(left, 0, right, h));
      if (mid < pi / 2) {
        canvas.save();
        canvas.translate(x0, 0);
        canvas.scale(max((x1 - x0) / ds, 0.001), 1);
        canvas.translate(-(fold + k * ds), 0);
        context.paintChild(child, Offset.zero);
        canvas.restore();
      } else {
        canvas.drawRect(Rect.fromLTRB(left, 0, right, h), backPaint);
      }
      _shade(canvas, Rect.fromLTRB(left, 0, right, h), mid, dark);
      canvas.restore();
    }

    // 5. The flap: a flat piece of paper hinged where it leaves the roll,
    //    tilted by [lift] with true perspective. Tilted past upright, its
    //    back faces us, with the printing on the other side faintly showing
    //    through, mirrored.
    if (flapLength > 0.5 && (lift - pi / 2).abs() > 0.02) {
      final m = Matrix4.identity()
        ..translateByDouble(rollEndX, h / 2, 0, 1)
        ..multiply(Matrix4.identity()..setEntry(3, 2, _depth))
        ..translateByDouble(0, 0, -rollEndZ, 1)
        ..rotateY(lift)
        ..translateByDouble(-flapStart, -h / 2, 0, 1);
      final region = Rect.fromLTRB(flapStart, 0, w, h);
      canvas.save();
      canvas.transform(m.storage);
      canvas.clipRect(region);
      if (lift < pi / 2) {
        context.paintChild(child, Offset.zero);
      } else {
        canvas.drawRect(region, backPaint);
        canvas.saveLayer(
          region,
          Paint()..color = Colors.black.withValues(alpha: dark ? 0.04 : 0.07),
        );
        context.paintChild(child, Offset.zero);
        canvas.restore();
      }
      _shade(canvas, region, lift, dark);
      canvas.restore();
    }

    canvas.restore();
  }

  /// Light on paper by angle: 0 lying flat (full light), darkest edge-on
  /// at a quarter turn, the back brightening again as it faces the reader.
  /// The back of a curl also catches a soft highlight.
  static void _shade(Canvas canvas, Rect rect, double angle, bool dark) {
    final edgeOn = sin(angle.clamp(0.0, pi)); // 0 flat .. 1 edge-on
    final shade = (dark ? 0.42 : 0.2) * pow(edgeOn, 2.2);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: shade.toDouble()),
    );
    if (angle > pi / 2) {
      final glint = sin((angle - pi / 2) * 2).clamp(0.0, 1.0);
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (dark ? 0.015 : 0.18) * glint,
          ),
      );
    }
  }

  static void _shadow(
    Canvas canvas,
    Rect rect,
    double strength, {
    required bool towardRight,
  }) {
    if (strength <= 0 || rect.width <= 0) return;
    final strong = Colors.black.withValues(alpha: strength);
    final none = Colors.black.withValues(alpha: 0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: towardRight ? [strong, none] : [none, strong],
        ).createShader(rect),
    );
  }
}
