import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import 'motion.dart';

/// The full-color logo, always on a transparent background. On dark surfaces
/// it uses the dark-mode artwork, whose brighter burgundy keeps the wordmark
/// legible without a plate behind it.
class CMLogo extends StatelessWidget {
  const CMLogo({super.key, this.height = 80, this.plate = false, this.onDark});

  final double height;

  /// Sets the logo on an ivory plate, for photos and video where the
  /// background behind it keeps changing.
  final bool plate;

  /// Whether the surface behind the logo is dark. Defaults to the theme's
  /// brightness; pass false for light cards shown in dark mode.
  final bool? onDark;

  /// The image the logo draws at [height], decoded at that size. The splash
  /// precaches it with this so the first frame of the logo is never blank.
  static ImageProvider provider(BuildContext context, {required double height, bool onDark = false}) =>
      ResizeImage.resizeIfNeeded(
        null,
        (height * MediaQuery.devicePixelRatioOf(context)).round(),
        AssetImage(onDark ? logoDarkAsset : logoAsset),
      );

  @override
  Widget build(BuildContext context) {
    final image = Image(
      image: provider(context, height: height, onDark: !plate && (onDark ?? context.cm.isDark)),
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Center Market',
    );
    if (!plate) return image;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: height * 0.22, vertical: height * 0.14),
      decoration: BoxDecoration(color: Brand.ivory, borderRadius: BorderRadius.circular(height * 0.32)),
      child: image,
    );
  }
}

/// The logo's swooshes as a decorative motif: nested crescents in green and
/// burgundy. [progress] sweeps them in, for the splash.
class OrbitArcs extends StatelessWidget {
  const OrbitArcs({
    super.key,
    this.progress = 1,
    this.opacity = 1,
    this.colors = const [Brand.green, Brand.burgundy, Brand.green],
  });

  final double progress;
  final double opacity;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _OrbitArcsPainter(progress: progress, opacity: opacity, colors: colors),
        size: Size.infinite,
      ),
    );
  }
}

class _OrbitArcsPainter extends CustomPainter {
  _OrbitArcsPainter({required this.progress, required this.opacity, required this.colors});

  final double progress;
  final double opacity;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) return;
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.save();
    if (progress < 1) {
      // Sweep in clockwise from the left, like the logo is being drawn.
      final radius = sqrt(w * w + h * h);
      canvas.clipPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(Rect.fromCircle(center: center, radius: radius), pi * 0.75, pi * 2 * progress, false)
          ..close(),
      );
    }

    for (var i = 0; i < colors.length; i++) {
      final inset = i * 0.115;
      final outer = Rect.fromLTRB(w * inset, h * inset * 0.85, w * (1 - inset * 0.55), h * (1 - inset * 0.85));
      // Offsetting the inner oval right makes a crescent: thick on the left, a hairline on the right.
      final thickness = 0.075 - i * 0.012;
      final inner = Rect.fromLTRB(
        outer.left + w * thickness,
        outer.top + h * thickness * 0.55,
        outer.right + w * 0.012,
        outer.bottom - h * thickness * 0.35,
      );
      final crescent = Path.combine(PathOperation.difference, Path()..addOval(outer), Path()..addOval(inner));
      canvas.drawPath(crescent, Paint()..color = colors[i].withValues(alpha: opacity));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitArcsPainter old) =>
      old.progress != progress || old.opacity != opacity || old.colors != colors;
}

/// Four dots, like the ones under "Market" in the logo. Pulses in sequence
/// while [animating].
class MarketDots extends StatefulWidget {
  const MarketDots({super.key, this.color = Brand.green, this.size = 8, this.animating = true, this.phase = 0});

  final Color color;
  final double size;
  final bool animating;

  /// Where in the pulse to start, from 0 to 1, to continue another set of
  /// dots (the web page's loader) without a jump.
  final double phase;

  @override
  State<MarketDots> createState() => _MarketDotsState();
}

class _MarketDotsState extends State<MarketDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MarketDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.animating && !MediaQuery.disableAnimationsOf(context);
    if (run && !_controller.isAnimating) {
      _controller
        ..value = widget.phase
        ..repeat();
    } else if (!run) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.animating ? 'Loading' : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.45),
                child: Transform.scale(
                  scale: _scaleFor(i),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _scaleFor(int i) {
    if (!_controller.isAnimating) return 1;
    final phase = (_controller.value - i * 0.16) % 1;
    return 0.6 + 0.5 * max(0, sin(phase * pi * 2));
  }
}

/// Brand photography: fills its box, decodes at display size and fades in.
class BrandPhoto extends StatelessWidget {
  const BrandPhoto(this.asset, {super.key, this.alignment = Alignment.center, this.semanticLabel});

  final String asset;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final longest = max(constraints.maxWidth, constraints.maxHeight);
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: alignment,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: longest.isFinite ? (longest * dpr).round() : null,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: Motion.slow,
              curve: Motion.standard,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => ColoredBox(color: context.cm.surfaceAlt),
        );
      },
    );
  }
}

/// Muted, looping brand film. Shows the poster until the video is ready, and
/// pauses while hidden, in the background, or when Reduce Motion is on.
class BrandVideo extends StatefulWidget {
  const BrandVideo({super.key, this.asset = brandVideo, this.poster = brandVideoPoster});

  final String asset;
  final String poster;

  @override
  State<BrandVideo> createState() => _BrandVideoState();
}

class _BrandVideoState extends State<BrandVideo> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(
      widget.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
    } catch (_) {
      // No video support (for example in widget tests): the poster stays up.
      return;
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _syncPlayback();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !_ready || !mounted) return;
    final visible = TickerMode.valuesOf(context).enabled;
    final shouldPlay = visible && _appActive && !MediaQuery.disableAnimationsOf(context);
    unawaited(shouldPlay ? controller.play() : controller.pause());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Semantics(
      label: 'Center Market store video',
      image: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BrandPhoto(widget.poster),
          if (controller != null && _ready)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A gradient that keeps text readable over photos and video.
class Scrim extends StatelessWidget {
  const Scrim({super.key, this.from = 0.35, this.opacity = 0.75, this.color = Brand.ink});

  final double from;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [from, 1],
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: opacity),
            ],
          ),
        ),
      ),
    );
  }
}

/// The burgundy surface used by the member pass and hero cards: a deep
/// gradient, a soft green glow and the logo's swooshes, faint.
class BurgundySurface extends StatelessWidget {
  const BurgundySurface({super.key, required this.child, this.radius = 30, this.arcs = true, this.shine = true});

  final Widget child;
  final double radius;
  final bool arcs;
  final bool shine;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.burgundyBright, Brand.burgundy, Brand.burgundyDeep],
          stops: [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.burgundy.withValues(alpha: context.cm.isDark ? 0.25 : 0.35),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            bottom: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Brand.green.withValues(alpha: 0.45), Brand.green.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          if (arcs)
            const Positioned(
              right: -70,
              top: -40,
              width: 280,
              height: 210,
              child: OrbitArcs(opacity: 0.16, colors: [Brand.white, Brand.white, Brand.white]),
            ),
          // Fine border so the card reads as a physical object.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Brand.white.withValues(alpha: 0.12)),
                ),
              ),
            ),
          ),
          if (shine) const Positioned.fill(child: Shine(opacity: 0.12)),
          child,
        ],
      ),
    );
  }
}
