import 'dart:math';

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../core/theme.dart';

/// A scannable QR code (ISO/IEC 18004), drawn in the brand style: round
/// modules and rounded finder rings. High error correction leaves room for
/// the CM badge laid over the middle.
class QrPainter extends CustomPainter {
  QrPainter({required this.data, this.color = Brand.ink, this.accent = Brand.burgundy})
    : _image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.H));

  final String data;
  final Color color;
  final Color accent;
  final QrImage _image;

  int get moduleCount => _image.moduleCount;

  bool _inFinder(int x, int y) {
    final n = _image.moduleCount;
    return (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = _image.moduleCount;
    final cell = size.shortestSide / n;
    final dark = Paint()..color = color;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!_inFinder(x, y) && _image.isDark(y, x)) {
          canvas.drawCircle(Offset((x + 0.5) * cell, (y + 0.5) * cell), cell * 0.46, dark);
        }
      }
    }

    // Each finder: a 7-module ring around a 3-module square, as the standard requires.
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
            Radius.circular(cell * 1.6),
          ),
          ring,
        )
        ..drawRRect(
          RRect.fromRectAndRadius((origin + Offset(cell * 2, cell * 2)) & Size.square(cell * 3), Radius.circular(cell)),
          dark,
        );
    }

    finder(0, 0);
    finder(n - 7, 0);
    finder(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color || oldDelegate.accent != accent;
}

/// A scannable Code 128 barcode, which every register scanner reads.
class BarcodePainter extends CustomPainter {
  BarcodePainter(this.data, {this.color = Brand.ink});

  final String data;
  final Color color;

  static final _code128 = Barcode.code128();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final bar in _code128.make(data, width: size.width, height: size.height).whereType<BarcodeBar>()) {
      if (bar.black) canvas.drawRect(Rect.fromLTWH(bar.left, bar.top, bar.width, bar.height), paint);
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
