import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Window-size breakpoints, in logical pixels. They follow the window, not the
/// device, so iPad Split View and foldables get the layout that fits.
class Breakpoints {
  Breakpoints._();

  /// Below this, phones are narrow (iPhone SE, folded Galaxy Z Fold).
  static const compact = 360.0;

  /// Tablets and unfolded foldables start here (by shortest side).
  static const tablet = 600.0;

  /// Wide enough for a side navigation rail.
  static const expanded = 840.0;

  /// Longest comfortable reading width for page content.
  static const content = 680.0;

  /// Tab pages on wide windows use this much room, in two columns or a grid.
  static const wide = 1120.0;

  /// Home becomes a two-column dashboard from this page width.
  static const wideHome = 900.0;

  /// Lists switch to two columns once the page is at least this wide.
  static const twoColumn = 760.0;

  /// Bottom sheets stop growing past this on large screens.
  static const sheet = 640.0;

  /// The largest text scale the layouts are designed for.
  static const maxTextScale = 1.5;
}

extension LayoutContext on BuildContext {
  double get windowWidth => MediaQuery.sizeOf(this).width;
  bool get isCompactWidth => windowWidth < Breakpoints.compact;
  bool get isExpandedWidth => windowWidth >= Breakpoints.expanded;

  /// Grows a fixed height to make room for larger text. [textShare] is the
  /// fraction of [base] taken up by text rather than images and padding.
  double textHeight(double base, {double textShare = 0.5}) {
    final scale = MediaQuery.textScalerOf(this).scale(1);
    return base * (1 + (scale - 1) * textShare);
  }
}

/// Fades a horizontal scroller out at its ends when it stops short of the
/// window edge (inside a capped column or beside the rail), so cards slide
/// out of view instead of being sliced off mid-card. On phones, where the
/// scroller already runs edge to edge, it's a no-op.
class EdgeFade extends StatelessWidget {
  const EdgeFade({super.key, required this.child, this.width = 20, this.start = true, this.always = false});

  final Widget child;

  /// Width of each fade, usually the scroller's own side padding.
  final double width;

  /// Whether the leading end fades too. Off for rows that start flush.
  final bool start;

  /// Fade even when running edge to edge, for rows inside a card.
  final bool always;

  @override
  Widget build(BuildContext context) {
    return _EdgeFade(
      window: MediaQuery.sizeOf(context).width,
      width: width,
      start: start,
      always: always,
      child: child,
    );
  }
}

class _EdgeFade extends SingleChildRenderObjectWidget {
  const _EdgeFade({required this.window, required this.width, required this.start, required this.always, super.child});

  final double window;
  final double width;
  final bool start;
  final bool always;

  @override
  _RenderEdgeFade createRenderObject(BuildContext context) => _RenderEdgeFade(window, width, start, always);

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeFade renderObject) {
    renderObject
      ..window = window
      ..width = width
      ..start = start
      ..always = always;
  }
}

/// Decides at paint time from the painted width, rather than with a
/// LayoutBuilder, so it still works inside IntrinsicHeight. Edge to edge it
/// paints the child directly: no mask layer, so scrolling costs nothing extra.
class _RenderEdgeFade extends RenderProxyBox {
  _RenderEdgeFade(this._window, this._width, this._start, this._always);

  double _window;
  set window(double value) => _set(_window != value, () => _window = value);

  double _width;
  set width(double value) => _set(_width != value, () => _width = value);

  bool _start;
  set start(bool value) => _set(_start != value, () => _start = value);

  bool _always;
  set always(bool value) => _set(_always != value, () => _always = value);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    _syncCompositing();
    markNeedsPaint();
  }

  bool get _fades => _always || (hasSize && size.width < _window - 1);
  bool? _lastFades;

  // Only a fading row pushes a layer, and whether it fades depends on its size.
  void _syncCompositing() {
    if (_lastFades == _fades) return;
    _lastFades = _fades;
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _fades;

  @override
  void performLayout() {
    super.performLayout();
    _syncCompositing();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (!_fades) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    final stop = (_width / size.width).clamp(0.0, 0.5);
    final shader = LinearGradient(
      colors: const [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
      stops: [0, _start ? stop : 0, 1 - stop, 1],
    ).createShader(Offset.zero & size);
    final mask = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    mask
      ..shader = shader
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    layer = context.pushLayer(mask, (context, offset) => context.paintChild(child, offset), offset) as ShaderMaskLayer?;
  }
}

/// An app bar whose back button, title and actions line up with a
/// [ContentWidth] column instead of the window edges.
class ContentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContentAppBar(this.bar, {super.key, this.maxWidth = Breakpoints.content});

  final AppBar bar;
  final double maxWidth;

  @override
  Size get preferredSize => bar.preferredSize;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
    child: ContentWidth(maxWidth: maxWidth, child: bar),
  );
}

/// Lays [children] out in rows of two once there's room, with each pair
/// sharing the taller one's height. Below [Breakpoints.twoColumn], a column.
class PairedList extends StatelessWidget {
  const PairedList({super.key, required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pairs = constraints.maxWidth >= Breakpoints.twoColumn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!pairs)
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: spacing), children[i]]
            else
              for (var i = 0; i < children.length; i += 2) ...[
                if (i > 0) SizedBox(height: spacing),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: children[i]),
                      SizedBox(width: spacing),
                      Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
          ],
        );
      },
    );
  }
}

/// Centers [child] and caps its width so lines stay readable on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = Breakpoints.content});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: min(maxWidth, constraints.maxWidth),
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          child: child,
        ),
      ),
    );
  }
}
