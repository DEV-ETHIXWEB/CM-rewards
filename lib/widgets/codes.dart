import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A QR-style member code. Not scannable: the demo has no backend to verify it.
class QrPainter extends CustomPainter {
  QrPainter({required this.seed, this.color = Brand.ink, this.accent = Brand.burgundy});

  final int seed;
  final Color color;
  final Color accent;

  static const _modules = 25;

  bool _reserved(int x, int y) {
    final finder = (x < 8 && y < 8) || (x >= _modules - 8 && y < 8) || (x < 8 && y >= _modules - 8);
    final center = (x - _modules ~/ 2).abs() <= 3 && (y - _modules ~/ 2).abs() <= 3;
    return finder || center;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final dark = Paint()..color = color;
    final rng = Random(seed);

    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        if (!_reserved(x, y) && rng.nextBool()) {
          canvas.drawCircle(Offset((x + 0.5) * cell, (y + 0.5) * cell), cell * 0.44, dark);
        }
      }
    }

    void finder(int col, int row) {
      final origin = Offset(col * cell, row * cell);
      final ring = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            (origin + Offset(cell / 2, cell / 2)) & Size.square(cell * 6),
            Radius.circular(cell * 1.8),
          ),
          ring,
        )
        ..drawRRect(
          RRect.fromRectAndRadius((origin + Offset(cell * 2, cell * 2)) & Size.square(cell * 3), Radius.circular(cell)),
          dark,
        );
    }

    finder(0, 0);
    finder(_modules - 7, 0);
    finder(0, _modules - 7);
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color || oldDelegate.accent != accent;
}

class BarcodePainter extends CustomPainter {
  BarcodePainter(this.data, {this.color = Brand.ink});

  final String data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(data.codeUnits.fold<int>(7, (hash, c) => (hash * 31 + c) & 0x7fffffff));
    final widths = <int>[];
    var total = 0;
    while (total < 110) {
      final w = 1 + rng.nextInt(3);
      widths.add(w);
      total += w;
    }
    final unit = size.width / total;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < widths.length; i++) {
      if (i.isEven) canvas.drawRect(Rect.fromLTWH(x, 0, widths[i] * unit, size.height), paint);
      x += widths[i] * unit;
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) => oldDelegate.data != data || oldDelegate.color != color;
}

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  static const _colors = [Brand.burgundy, Brand.burgundyBright, Brand.green, Brand.greenBright, Brand.champagne];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final List<_Particle> _particles = () {
    final rng = Random();
    return List.generate(90, (_) {
      return _Particle(
        angle: -pi / 2 + (rng.nextDouble() - 0.5) * 2.6,
        speed: 380 + rng.nextDouble() * 520,
        spin: (rng.nextDouble() - 0.5) * 14,
        size: 6 + rng.nextDouble() * 7,
        color: _colors[rng.nextInt(_colors.length)],
        round: rng.nextBool(),
      );
    });
  }();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: _ConfettiPainter(_particles, _controller.value)),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final t = progress * 2.6;
    final origin = Offset(size.width / 2, size.height * 0.32);
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (final p in particles) {
      final drag = 1 - progress * 0.5;
      final position =
          origin +
          Offset(cos(p.angle) * p.speed * t * drag, sin(p.angle) * p.speed * t * drag + 0.5 * 900 * t * t * 0.6);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
