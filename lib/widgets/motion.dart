import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/rewards_state.dart';

/// Fades and slides its child up into place, optionally after a delay.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 20});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _curve.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

Widget reveal(int index, Widget child) => FadeSlideIn(
  delay: Duration(milliseconds: 55 * index),
  child: child,
);

/// Gives any widget a gentle press-down scale and a haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

/// Swallows a repeat tap on the same control within [window], so a double tap
/// can't redeem twice, place two orders or open a screen twice.
class TapGuard {
  TapGuard([this.window = const Duration(milliseconds: 400)]);

  final Duration window;
  DateTime? _last;

  bool allow() {
    final now = clock.now();
    final last = _last;
    if (last != null && now.difference(last) < window) return false;
    _last = now;
    return true;
  }
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  final _guard = TapGuard();

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                if (!_guard.allow()) return;
                RewardsScope.read(context).haptic();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.fast,
          curve: Motion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Rebuilds on a fixed interval, for clocks, countdowns and live status.
class TickBuilder extends StatefulWidget {
  const TickBuilder({super.key, required this.builder, this.interval = const Duration(seconds: 1)});

  final WidgetBuilder builder;
  final Duration interval;

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// A moving highlight that sweeps across its parent every few seconds.
class Shine extends StatefulWidget {
  const Shine({super.key, this.opacity = 0.14});

  final double opacity;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Sweep during the first 30% of each cycle, then rest.
              final t = Curves.easeInOut.transform((_controller.value / 0.3).clamp(0.0, 1.0));
              return Transform.translate(offset: Offset(-width * 0.8 + t * width * 2.2, 0), child: child);
            },
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: width * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Brand.white.withValues(alpha: 0),
                      Brand.white.withValues(alpha: widget.opacity),
                      Brand.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Counts smoothly from the previous value to the new one.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.builder, this.from});

  final int value;
  final int? from;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: from ?? value, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Motion.standard,
      builder: (context, v, _) => builder(context, v),
    );
  }
}
