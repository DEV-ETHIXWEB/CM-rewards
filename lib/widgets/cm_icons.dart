import 'dart:math';

import 'package:flutter/material.dart';

/// Center Market's own icon family. Every glyph is drawn here on a 24-unit
/// grid with a 1.8 rounded stroke, so the set stays consistent and owned by
/// the brand rather than borrowed from an icon library.
enum CMGlyph {
  home,
  homeFill,
  bag,
  bagFill,
  gift,
  giftFill,
  store,
  storeFill,
  scan,
  qr,
  check,
  checkCircle,
  close,
  plus,
  minus,
  arrowRight,
  chevronRight,
  chevronDown,
  back,
  unfold,
  external,
  refresh,
  search,
  fuel,
  ev,
  navigate,
  pin,
  locate,
  phone,
  device,
  mail,
  chat,
  bell,
  bellOff,
  heart,
  heartFill,
  star,
  sparkle,
  medal,
  trophy,
  bolt,
  flame,
  wallet,
  card,
  cash,
  receipt,
  ticket,
  tag,
  clip,
  share,
  send,
  copy,
  pencil,
  trash,
  lock,
  shield,
  info,
  help,
  person,
  people,
  idCard,
  handHeart,
  cup,
  icee,
  pizza,
  food,
  basket,
  beer,
  pot,
  cake,
  calendar,
  calendarCheck,
  timer,
  sun,
  sound,
  vibrate,
  trendUp,
  savings,
  register,
  play,
  logout,
  code,
  tools,
  radioOff,
  radioOn,
}

/// Drop-in for [Icon]: same size and color behavior, including inheriting
/// from [IconTheme] inside buttons and list tiles.
class CMIcon extends StatelessWidget {
  const CMIcon(this.glyph, {super.key, this.size, this.color, this.semanticLabel});

  final CMGlyph glyph;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    // Like Icon: when a parent forces a bigger box (a fixed-size button, a
    // text field's icon slot), the glyph keeps its own size, centered.
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _GlyphPainter(glyph, color)),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final CMGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    _draw(canvas, glyph, stroke, fill);
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.glyph != glyph || old.color != color;
}

Path _poly(List<double> xy, {bool close = false}) {
  final p = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    p.lineTo(xy[i], xy[i + 1]);
  }
  if (close) p.close();
  return p;
}

RRect _rr(double l, double t, double r, double b, double radius) =>
    RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));

Path _heartPath(double cx, double cy, double s) {
  // A soft heart centred on (cx, cy), roughly 2*s wide.
  return Path()
    ..moveTo(cx, cy + s * 0.85)
    ..cubicTo(cx - s * 1.25, cy + s * 0.05, cx - s * 1.05, cy - s * 1.0, cx - s * 0.45, cy - s * 0.95)
    ..cubicTo(cx - s * 0.15, cy - s * 0.93, cx, cy - s * 0.6, cx, cy - s * 0.45)
    ..cubicTo(cx, cy - s * 0.6, cx + s * 0.15, cy - s * 0.93, cx + s * 0.45, cy - s * 0.95)
    ..cubicTo(cx + s * 1.05, cy - s * 1.0, cx + s * 1.25, cy + s * 0.05, cx, cy + s * 0.85)
    ..close();
}

Path _starPath(double cx, double cy, double outer, double inner) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = -pi / 2 + i * pi / 5;
    final x = cx + r * cos(a);
    final y = cy + r * sin(a);
    i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  return p..close();
}

Path _sparklePath(double cx, double cy, double r) {
  return Path()
    ..moveTo(cx, cy - r)
    ..quadraticBezierTo(cx + r * 0.18, cy - r * 0.18, cx + r, cy)
    ..quadraticBezierTo(cx + r * 0.18, cy + r * 0.18, cx, cy + r)
    ..quadraticBezierTo(cx - r * 0.18, cy + r * 0.18, cx - r, cy)
    ..quadraticBezierTo(cx - r * 0.18, cy - r * 0.18, cx, cy - r)
    ..close();
}

Path _boltPath() => _poly([13.5, 2.8, 5.5, 13.2, 11.6, 13.2, 10.5, 21.2, 18.5, 10.8, 12.4, 10.8], close: true);

Path _bellBody() => Path()
  ..moveTo(5, 17)
  ..lineTo(19, 17)
  ..cubicTo(17.6, 15.6, 17.4, 14.2, 17.4, 11.6)
  ..cubicTo(17.4, 8.2, 15.1, 5.6, 12, 5.6)
  ..cubicTo(8.9, 5.6, 6.6, 8.2, 6.6, 11.6)
  ..cubicTo(6.6, 14.2, 6.4, 15.6, 5, 17)
  ..close();

Path _houseBody() => Path()
  ..moveTo(4, 10.4)
  ..lineTo(12, 3.8)
  ..lineTo(20, 10.4)
  ..lineTo(20, 18.4)
  ..quadraticBezierTo(20, 20.2, 18.2, 20.2)
  ..lineTo(5.8, 20.2)
  ..quadraticBezierTo(4, 20.2, 4, 18.4)
  ..close();

Path _bagBody() => Path()
  ..moveTo(5.4, 8)
  ..lineTo(18.6, 8)
  ..lineTo(19.5, 18.6)
  ..quadraticBezierTo(19.6, 20.4, 17.8, 20.4)
  ..lineTo(6.2, 20.4)
  ..quadraticBezierTo(4.4, 20.4, 4.5, 18.6)
  ..close();

Path _storeAwning() => Path()
  ..moveTo(3.5, 9)
  ..lineTo(5, 4)
  ..lineTo(19, 4)
  ..lineTo(20.5, 9)
  ..quadraticBezierTo(20.5, 11, 18.4, 11)
  ..quadraticBezierTo(16.2, 11, 16, 9)
  ..quadraticBezierTo(15.8, 11, 13.9, 11)
  ..quadraticBezierTo(12, 11, 12, 9)
  ..quadraticBezierTo(12, 11, 10.1, 11)
  ..quadraticBezierTo(8.2, 11, 8, 9)
  ..quadraticBezierTo(7.8, 11, 5.6, 11)
  ..quadraticBezierTo(3.5, 11, 3.5, 9)
  ..close();

void _draw(Canvas c, CMGlyph g, Paint s, Paint f) {
  void circle(double x, double y, double r, [Paint? p]) => c.drawCircle(Offset(x, y), r, p ?? s);
  void line(double x1, double y1, double x2, double y2) => c.drawLine(Offset(x1, y1), Offset(x2, y2), s);
  void path(Path p, [Paint? paint]) => c.drawPath(p, paint ?? s);
  void rrect(RRect r, [Paint? paint]) => c.drawRRect(r, paint ?? s);
  void arc(double cx, double cy, double r, double start, double sweep) =>
      c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false, s);

  switch (g) {
    case CMGlyph.home:
      path(_houseBody());
      path(_poly([9.8, 20.2, 9.8, 14.8, 14.2, 14.8, 14.2, 20.2]));
    case CMGlyph.homeFill:
      // Own layer, so cutting out the door doesn't punch through what's behind.
      c.saveLayer(const Rect.fromLTWH(0, 0, 24, 24), Paint());
      path(_houseBody(), f);
      path(_houseBody());
      c.drawRRect(_rr(10, 14.4, 14, 20.2, 1), Paint()..blendMode = BlendMode.clear);
      c.restore();
    case CMGlyph.bag:
      path(_bagBody());
      path(
        Path()
          ..moveTo(8.8, 10.6)
          ..lineTo(8.8, 7.2)
          ..cubicTo(8.8, 3.6, 15.2, 3.6, 15.2, 7.2)
          ..lineTo(15.2, 10.6),
      );
    case CMGlyph.bagFill:
      path(_bagBody(), f);
      path(_bagBody());
      path(
        Path()
          ..moveTo(8.8, 8)
          ..lineTo(8.8, 7.2)
          ..cubicTo(8.8, 3.6, 15.2, 3.6, 15.2, 7.2)
          ..lineTo(15.2, 8),
      );
    case CMGlyph.gift:
    case CMGlyph.giftFill:
      final box = _rr(4.5, 11, 19.5, 20.5, 1.8);
      if (g == CMGlyph.giftFill) rrect(box, f);
      rrect(box);
      rrect(_rr(3.5, 7.5, 20.5, 11, 1.4), g == CMGlyph.giftFill ? f : null);
      rrect(_rr(3.5, 7.5, 20.5, 11, 1.4));
      line(12, 7.5, 12, 20.5);
      path(
        Path()
          ..moveTo(12, 7.4)
          ..cubicTo(10.6, 3.4, 6.6, 4.4, 8.2, 6.8)
          ..cubicTo(9, 7.8, 12, 7.4, 12, 7.4),
      );
      path(
        Path()
          ..moveTo(12, 7.4)
          ..cubicTo(13.4, 3.4, 17.4, 4.4, 15.8, 6.8)
          ..cubicTo(15, 7.8, 12, 7.4, 12, 7.4),
      );
    case CMGlyph.store:
      path(_storeAwning());
      path(_poly([5, 11, 5, 20, 19, 20, 19, 11]));
      path(_poly([10, 20, 10, 15, 14, 15, 14, 20]));
    case CMGlyph.storeFill:
      path(_storeAwning(), f);
      path(_storeAwning());
      path(_poly([5, 11, 5, 20, 19, 20, 19, 11]));
      path(_poly([10, 20, 10, 15, 14, 15, 14, 20]));
    case CMGlyph.scan:
      path(_poly([3.5, 8, 3.5, 5.5, 5.5, 3.5, 8, 3.5]));
      path(_poly([16, 3.5, 18.5, 3.5, 20.5, 5.5, 20.5, 8]));
      path(_poly([20.5, 16, 20.5, 18.5, 18.5, 20.5, 16, 20.5]));
      path(_poly([8, 20.5, 5.5, 20.5, 3.5, 18.5, 3.5, 16]));
      line(6.5, 12, 17.5, 12);
      rrect(_rr(7.5, 7.5, 10.5, 10, 0.6), f);
      rrect(_rr(13.5, 14, 16.5, 16.5, 0.6), f);
    case CMGlyph.qr:
      rrect(_rr(4, 4, 10, 10, 1.6));
      rrect(_rr(14, 4, 20, 10, 1.6));
      rrect(_rr(4, 14, 10, 20, 1.6));
      circle(7, 7, 0.9, f);
      circle(17, 7, 0.9, f);
      circle(7, 17, 0.9, f);
      circle(14.5, 14.5, 1, f);
      circle(19, 14.5, 1, f);
      circle(16.8, 17, 1, f);
      circle(14.5, 19.5, 1, f);
      circle(19, 19.5, 1, f);
    case CMGlyph.check:
      path(_poly([5, 12.5, 9.8, 17.2, 19, 7.4]));
    case CMGlyph.checkCircle:
      circle(12, 12, 9, f);
      path(
        _poly([7.8, 12.3, 10.8, 15.2, 16.4, 9.2]),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    case CMGlyph.close:
      line(6.5, 6.5, 17.5, 17.5);
      line(17.5, 6.5, 6.5, 17.5);
    case CMGlyph.plus:
      line(12, 5.5, 12, 18.5);
      line(5.5, 12, 18.5, 12);
    case CMGlyph.minus:
      line(5.5, 12, 18.5, 12);
    case CMGlyph.arrowRight:
      line(4.5, 12, 19, 12);
      path(_poly([13, 6, 19, 12, 13, 18]));
    case CMGlyph.chevronRight:
      path(_poly([9.5, 6, 15.5, 12, 9.5, 18]));
    case CMGlyph.chevronDown:
      path(_poly([6, 9.5, 12, 15.5, 18, 9.5]));
    case CMGlyph.back:
      path(_poly([15, 5, 8, 12, 15, 19]));
    case CMGlyph.unfold:
      path(_poly([7.5, 9.5, 12, 5, 16.5, 9.5]));
      path(_poly([7.5, 14.5, 12, 19, 16.5, 14.5]));
    case CMGlyph.external:
      path(_poly([18.5, 13.5, 18.5, 18, 17, 19.5, 6, 19.5, 4.5, 18, 4.5, 7, 6, 5.5, 10.5, 5.5]));
      path(_poly([14, 4.5, 19.5, 4.5, 19.5, 10]));
      line(19.5, 4.5, 11.5, 12.5);
    case CMGlyph.refresh:
      arc(12, 12, 7.5, -pi * 0.35, pi * 1.6);
      path(_poly([19.4, 4.6, 19.2, 8.6, 15.2, 8.4]));
    case CMGlyph.search:
      circle(10.5, 10.5, 6);
      line(15, 15, 20, 20);
    case CMGlyph.fuel:
    case CMGlyph.ev:
      rrect(_rr(4.5, 4, 13.5, 20.5, 2));
      line(3, 20.5, 15, 20.5);
      if (g == CMGlyph.fuel) {
        rrect(_rr(6.8, 6.5, 11.2, 10.5, 0.8));
      } else {
        path(_poly([10, 6.5, 7.5, 11, 10.5, 11, 8.5, 15.5]));
      }
      path(
        Path()
          ..moveTo(13.5, 9)
          ..lineTo(16.5, 9)
          ..quadraticBezierTo(18, 9, 18, 10.5)
          ..lineTo(18, 16)
          ..quadraticBezierTo(18, 17.6, 19.2, 17.6)
          ..quadraticBezierTo(20.5, 17.6, 20.5, 16)
          ..lineTo(20.5, 8)
          ..lineTo(18.5, 5.5),
      );
    case CMGlyph.navigate:
      path(_poly([20, 4, 4.5, 10.8, 11.2, 12.8, 13.2, 19.5], close: true));
    case CMGlyph.pin:
      path(
        Path()
          ..moveTo(12, 21)
          ..cubicTo(12, 21, 5, 14.6, 5, 9.6)
          ..cubicTo(5, 5.6, 8.1, 3, 12, 3)
          ..cubicTo(15.9, 3, 19, 5.6, 19, 9.6)
          ..cubicTo(19, 14.6, 12, 21, 12, 21)
          ..close(),
      );
      circle(12, 9.6, 2.6);
    case CMGlyph.locate:
      circle(12, 12, 6.5);
      circle(12, 12, 2.2, f);
      line(12, 2.5, 12, 5.5);
      line(12, 18.5, 12, 21.5);
      line(2.5, 12, 5.5, 12);
      line(18.5, 12, 21.5, 12);
    case CMGlyph.phone:
      path(
        Path()
          ..moveTo(6.4, 3.8)
          ..lineTo(9, 3.8)
          ..lineTo(10.4, 7.8)
          ..lineTo(8.4, 9.4)
          ..cubicTo(9.4, 11.8, 12.2, 14.6, 14.6, 15.6)
          ..lineTo(16.2, 13.6)
          ..lineTo(20.2, 15)
          ..lineTo(20.2, 17.6)
          ..cubicTo(20.2, 19.2, 19, 20.4, 17.4, 20.2)
          ..cubicTo(10.4, 19.6, 4.4, 13.6, 3.8, 6.6)
          ..cubicTo(3.6, 5, 4.8, 3.8, 6.4, 3.8)
          ..close(),
      );
    case CMGlyph.device:
      rrect(_rr(6.5, 2.8, 17.5, 21.2, 2.6));
      line(10.5, 18.2, 13.5, 18.2);
    case CMGlyph.mail:
      rrect(_rr(3.5, 5.5, 20.5, 18.5, 2.4));
      path(_poly([4.5, 7.5, 12, 12.8, 19.5, 7.5]));
    case CMGlyph.chat:
      path(
        Path()
          ..moveTo(7, 4.5)
          ..lineTo(17, 4.5)
          ..quadraticBezierTo(20, 4.5, 20, 7.5)
          ..lineTo(20, 13.5)
          ..quadraticBezierTo(20, 16.5, 17, 16.5)
          ..lineTo(11, 16.5)
          ..lineTo(6.5, 20)
          ..lineTo(6.5, 16.4)
          ..quadraticBezierTo(4, 16, 4, 13.5)
          ..lineTo(4, 7.5)
          ..quadraticBezierTo(4, 4.5, 7, 4.5)
          ..close(),
      );
    case CMGlyph.bell:
    case CMGlyph.bellOff:
      path(_bellBody());
      line(12, 3.4, 12, 5.6);
      path(
        Path()
          ..moveTo(9.8, 19.4)
          ..quadraticBezierTo(12, 21.4, 14.2, 19.4),
      );
      if (g == CMGlyph.bellOff) line(4, 4, 20, 20);
    case CMGlyph.heart:
      path(_heartPath(12, 12.6, 8.2));
    case CMGlyph.heartFill:
      path(_heartPath(12, 12.6, 8.2), f);
      path(_heartPath(12, 12.6, 8.2));
    case CMGlyph.star:
      path(_starPath(12, 12.6, 8.6, 4), f);
      path(_starPath(12, 12.6, 8.6, 4));
    case CMGlyph.sparkle:
      path(_sparklePath(10.5, 13, 7), f);
      path(_sparklePath(18.2, 5.8, 3), f);
    case CMGlyph.medal:
      path(_poly([8.2, 2.8, 10.4, 8.6]));
      path(_poly([15.8, 2.8, 13.6, 8.6]));
      circle(12, 14.2, 6.4);
      path(_starPath(12, 14.4, 3.2, 1.4), f);
    case CMGlyph.trophy:
      path(
        Path()
          ..moveTo(7, 4)
          ..lineTo(17, 4)
          ..lineTo(17, 9)
          ..cubicTo(17, 12.2, 14.8, 14.4, 12, 14.4)
          ..cubicTo(9.2, 14.4, 7, 12.2, 7, 9)
          ..close(),
      );
      path(
        Path()
          ..moveTo(7, 6)
          ..lineTo(4, 6)
          ..cubicTo(4, 9.6, 5.4, 11, 7.6, 11),
      );
      path(
        Path()
          ..moveTo(17, 6)
          ..lineTo(20, 6)
          ..cubicTo(20, 9.6, 18.6, 11, 16.4, 11),
      );
      line(12, 14.4, 12, 18);
      line(8, 20.2, 16, 20.2);
      line(9.5, 18, 14.5, 18);
    case CMGlyph.bolt:
      path(_boltPath(), f);
      path(_boltPath());
    case CMGlyph.flame:
      final flame = Path()
        ..moveTo(12, 21)
        ..cubicTo(7.4, 21, 5, 17.8, 5, 14.6)
        ..cubicTo(5, 10, 9.8, 8.4, 10.2, 3)
        ..cubicTo(13.4, 5, 15, 8, 14.4, 11)
        ..cubicTo(15.6, 10.4, 16.4, 9.4, 16.6, 8.2)
        ..cubicTo(18.2, 10, 19, 12.4, 19, 14.6)
        ..cubicTo(19, 17.8, 16.6, 21, 12, 21)
        ..close();
      path(flame, f);
      path(flame);
    case CMGlyph.wallet:
      rrect(_rr(3.5, 6.5, 20.5, 19.5, 2.6));
      path(_poly([5, 6.5, 15.2, 3.6, 16.2, 6.5]));
      rrect(_rr(14.5, 11, 20.5, 15, 1.6));
      circle(16.8, 13, 0.9, f);
    case CMGlyph.card:
      rrect(_rr(3, 5.5, 21, 18.5, 2.4));
      line(3, 9.6, 21, 9.6);
      line(6.5, 14.8, 10, 14.8);
    case CMGlyph.cash:
      rrect(_rr(3, 6.5, 21, 17.5, 2.2));
      circle(12, 12, 2.6);
      circle(6.6, 12, 0.9, f);
      circle(17.4, 12, 0.9, f);
    case CMGlyph.receipt:
      path(
        _poly([5.5, 3, 5.5, 21, 8, 19.4, 10.4, 21, 12.8, 19.4, 15.2, 21, 17.6, 19.4, 18.5, 20, 18.5, 3], close: true),
      );
      line(8.5, 8, 15.5, 8);
      line(8.5, 11.5, 15.5, 11.5);
      line(8.5, 15, 12.5, 15);
    case CMGlyph.ticket:
      path(
        Path()
          ..moveTo(4, 6)
          ..lineTo(20, 6)
          ..lineTo(20, 9.6)
          ..arcToPoint(const Offset(20, 14.4), radius: const Radius.circular(2.4), clockwise: false)
          ..lineTo(20, 18)
          ..lineTo(4, 18)
          ..lineTo(4, 14.4)
          ..arcToPoint(const Offset(4, 9.6), radius: const Radius.circular(2.4), clockwise: false)
          ..close(),
      );
      line(14.5, 8.5, 14.5, 9.5);
      line(14.5, 11.5, 14.5, 12.5);
      line(14.5, 14.5, 14.5, 15.5);
    case CMGlyph.tag:
      path(_poly([3.5, 4.6, 3.5, 11.6, 12.6, 20.6, 20.6, 12.6, 11.6, 3.5, 4.6, 3.5], close: true));
      circle(8, 8, 1.4, f);
    case CMGlyph.clip:
      circle(6.8, 17, 2.8);
      circle(17.2, 17, 2.8);
      line(8.8, 15, 18, 4.5);
      line(15.2, 15, 6, 4.5);
    case CMGlyph.share:
      path(_poly([8, 7.5, 12, 3.5, 16, 7.5]));
      line(12, 3.5, 12, 14.5);
      path(_poly([8.5, 10.5, 6, 10.5, 5, 11.5, 5, 19.5, 6, 20.5, 18, 20.5, 19, 19.5, 19, 11.5, 18, 10.5, 15.5, 10.5]));
    case CMGlyph.send:
      path(_poly([20.5, 3.5, 3.5, 10.5, 10.6, 13.4, 13.5, 20.5], close: true));
      line(20.5, 3.5, 10.6, 13.4);
    case CMGlyph.copy:
      rrect(_rr(8.5, 8.5, 20, 20, 2.2));
      path(_poly([15.5, 8.5, 15.5, 5.8, 13.7, 4, 5.8, 4, 4, 5.8, 4, 13.7, 5.8, 15.5, 8.5, 15.5]));
    case CMGlyph.pencil:
      path(_poly([4, 20, 4.8, 15.8, 15.6, 5, 19, 8.4, 8.2, 19.2], close: true));
      line(13.2, 7.4, 16.6, 10.8);
    case CMGlyph.trash:
      line(4, 6.5, 20, 6.5);
      path(_poly([9, 6.5, 9.6, 3.8, 14.4, 3.8, 15, 6.5]));
      path(_poly([6, 6.5, 7, 19, 8.4, 20.4, 15.6, 20.4, 17, 19, 18, 6.5]));
      line(10.2, 10.5, 10.2, 16.5);
      line(13.8, 10.5, 13.8, 16.5);
    case CMGlyph.lock:
      rrect(_rr(5, 10.5, 19, 20.5, 2.4));
      path(
        Path()
          ..moveTo(8, 10.5)
          ..lineTo(8, 7.8)
          ..cubicTo(8, 2.8, 16, 2.8, 16, 7.8)
          ..lineTo(16, 10.5),
      );
      circle(12, 15.5, 1.3, f);
    case CMGlyph.shield:
      path(
        Path()
          ..moveTo(12, 3)
          ..lineTo(19.5, 5.8)
          ..lineTo(19.5, 11.2)
          ..cubicTo(19.5, 16, 16.4, 19.6, 12, 21)
          ..cubicTo(7.6, 19.6, 4.5, 16, 4.5, 11.2)
          ..lineTo(4.5, 5.8)
          ..close(),
      );
      path(_poly([8.8, 12, 11.2, 14.4, 15.6, 9.8]));
    case CMGlyph.info:
      circle(12, 12, 8.8);
      line(12, 11, 12, 16.5);
      circle(12, 7.8, 1.1, f);
    case CMGlyph.help:
      circle(12, 12, 8.8);
      path(
        Path()
          ..moveTo(9.4, 9.4)
          ..cubicTo(9.4, 6.2, 14.8, 6.2, 14.8, 9.4)
          ..cubicTo(14.8, 11.4, 12, 11.4, 12, 13.6),
      );
      circle(12, 16.8, 1.1, f);
    case CMGlyph.person:
      circle(12, 8, 4);
      path(
        Path()
          ..moveTo(4.5, 20.5)
          ..cubicTo(4.5, 15.5, 8, 13.6, 12, 13.6)
          ..cubicTo(16, 13.6, 19.5, 15.5, 19.5, 20.5),
      );
    case CMGlyph.people:
      circle(9, 8.4, 3.4);
      path(
        Path()
          ..moveTo(3, 19.5)
          ..cubicTo(3, 15.4, 5.8, 13.6, 9, 13.6)
          ..cubicTo(12.2, 13.6, 15, 15.4, 15, 19.5),
      );
      line(18.5, 7, 18.5, 13);
      line(15.5, 10, 21.5, 10);
    case CMGlyph.idCard:
      rrect(_rr(3, 5, 21, 19, 2.4));
      circle(8.6, 11, 2);
      path(
        Path()
          ..moveTo(5.6, 16.2)
          ..quadraticBezierTo(8.6, 13.4, 11.6, 16.2),
      );
      line(14, 10, 18, 10);
      line(14, 14, 17, 14);
    case CMGlyph.handHeart:
      path(_heartPath(14.2, 7.2, 4.2), f);
      path(
        Path()
          ..moveTo(2.8, 13.6)
          ..lineTo(5.6, 13.6)
          ..lineTo(9.6, 12.6)
          ..quadraticBezierTo(12.4, 12, 13.2, 14.4)
          ..lineTo(9.6, 15.4),
      );
      path(
        Path()
          ..moveTo(13.2, 14.4)
          ..lineTo(18, 12.8)
          ..quadraticBezierTo(20.4, 12.2, 20.8, 14.2)
          ..lineTo(12.8, 19.4)
          ..lineTo(5.6, 18.4)
          ..lineTo(2.8, 18.4),
      );
    case CMGlyph.cup:
      path(_poly([5, 8.5, 6.6, 19, 8, 20.4, 14, 20.4, 15.4, 19, 17, 8.5], close: true));
      path(
        Path()
          ..moveTo(16.6, 11)
          ..lineTo(18, 11)
          ..quadraticBezierTo(20.4, 11, 20.4, 13.4)
          ..quadraticBezierTo(20.4, 15.8, 16, 15.8),
      );
      path(
        Path()
          ..moveTo(9, 3)
          ..quadraticBezierTo(8, 4.5, 9, 6),
      );
      path(
        Path()
          ..moveTo(13, 3)
          ..quadraticBezierTo(12, 4.5, 13, 6),
      );
    case CMGlyph.icee:
      path(_poly([6.5, 10.5, 8, 20.4, 16, 20.4, 17.5, 10.5]));
      path(
        Path()
          ..moveTo(5.5, 10.5)
          ..lineTo(18.5, 10.5)
          ..cubicTo(18.5, 5.8, 5.5, 5.8, 5.5, 10.5),
      );
      line(13.5, 7.2, 16, 2.5);
      line(7.2, 14.5, 16.8, 14.5);
    case CMGlyph.pizza:
      path(
        Path()
          ..moveTo(12, 21)
          ..lineTo(3.6, 6.4)
          ..quadraticBezierTo(12, 1.6, 20.4, 6.4)
          ..close(),
      );
      path(
        Path()
          ..moveTo(5.4, 9.6)
          ..quadraticBezierTo(12, 6, 18.6, 9.6),
      );
      circle(10, 12.2, 1.2, f);
      circle(14, 13.2, 1.2, f);
      circle(12, 16.4, 1.1, f);
    case CMGlyph.food:
      line(7, 3.5, 7, 20.5);
      path(
        Path()
          ..moveTo(4.5, 3.5)
          ..lineTo(4.5, 8)
          ..quadraticBezierTo(4.5, 10.4, 7, 10.4)
          ..quadraticBezierTo(9.5, 10.4, 9.5, 8)
          ..lineTo(9.5, 3.5),
      );
      path(
        Path()
          ..moveTo(17.5, 20.5)
          ..lineTo(17.5, 3.5)
          ..cubicTo(14.6, 4.6, 14, 8.6, 14.4, 13)
          ..lineTo(17.5, 13),
      );
    case CMGlyph.basket:
      path(_poly([3.5, 10, 20.5, 10, 18.8, 19, 17.4, 20.4, 6.6, 20.4, 5.2, 19], close: true));
      path(_poly([7.5, 10, 10.5, 4]));
      path(_poly([16.5, 10, 13.5, 4]));
      line(9.5, 13.5, 9.5, 17);
      line(14.5, 13.5, 14.5, 17);
    case CMGlyph.beer:
      rrect(_rr(5, 8, 15, 20.5, 2));
      path(
        Path()
          ..moveTo(15, 10.5)
          ..lineTo(17, 10.5)
          ..quadraticBezierTo(19.5, 10.5, 19.5, 13)
          ..lineTo(19.5, 15)
          ..quadraticBezierTo(19.5, 17.5, 17, 17.5)
          ..lineTo(15, 17.5),
      );
      path(
        Path()
          ..moveTo(5, 8)
          ..quadraticBezierTo(5, 4, 8.4, 4.6)
          ..quadraticBezierTo(10, 3, 12, 4.4)
          ..quadraticBezierTo(15, 3.8, 15, 8),
      );
      line(8.5, 11.5, 8.5, 17);
      line(11.5, 11.5, 11.5, 17);
    case CMGlyph.pot:
      path(_poly([4.5, 10.5, 19.5, 10.5, 18.6, 18.6, 17, 20.2, 7, 20.2, 5.4, 18.6], close: true));
      line(2.5, 10.5, 21.5, 10.5);
      path(
        Path()
          ..moveTo(8.5, 7)
          ..quadraticBezierTo(7.6, 5.2, 8.5, 3.4),
      );
      path(
        Path()
          ..moveTo(12, 7)
          ..quadraticBezierTo(11.1, 5.2, 12, 3.4),
      );
      path(
        Path()
          ..moveTo(15.5, 7)
          ..quadraticBezierTo(14.6, 5.2, 15.5, 3.4),
      );
    case CMGlyph.cake:
      rrect(_rr(4, 12, 20, 20.5, 2));
      path(
        Path()
          ..moveTo(4, 15.4)
          ..quadraticBezierTo(6, 17.2, 8, 15.4)
          ..quadraticBezierTo(10, 17.2, 12, 15.4)
          ..quadraticBezierTo(14, 17.2, 16, 15.4)
          ..quadraticBezierTo(18, 17.2, 20, 15.4),
      );
      line(12, 8.4, 12, 12);
      path(
        Path()
          ..moveTo(12, 3.4)
          ..quadraticBezierTo(14, 5.6, 12, 7)
          ..quadraticBezierTo(10, 5.6, 12, 3.4)
          ..close(),
        f,
      );
    case CMGlyph.calendar:
    case CMGlyph.calendarCheck:
      rrect(_rr(3.5, 5, 20.5, 20.5, 2.6));
      line(3.5, 9.8, 20.5, 9.8);
      line(8, 3, 8, 6.6);
      line(16, 3, 16, 6.6);
      if (g == CMGlyph.calendarCheck) {
        path(_poly([8.4, 15, 10.8, 17.2, 15.6, 12.8]));
      } else {
        circle(8, 14, 1, f);
        circle(12, 14, 1, f);
        circle(16, 14, 1, f);
        circle(8, 17.4, 1, f);
        circle(12, 17.4, 1, f);
      }
    case CMGlyph.timer:
      circle(12, 13.4, 7.6);
      line(12, 13.4, 12, 9.4);
      line(9.5, 2.8, 14.5, 2.8);
      line(18.2, 6.6, 19.6, 5.2);
    case CMGlyph.sun:
      circle(12, 12, 4.2);
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        line(12 + 7 * cos(a), 12 + 7 * sin(a), 12 + 9 * cos(a), 12 + 9 * sin(a));
      }
    case CMGlyph.sound:
      path(_poly([3.5, 9.5, 7, 9.5, 11.5, 5, 11.5, 19, 7, 14.5, 3.5, 14.5], close: true));
      arc(11.5, 12, 4.4, -pi / 4, pi / 2);
      arc(11.5, 12, 8, -pi / 4, pi / 2);
    case CMGlyph.vibrate:
      rrect(_rr(8, 4, 16, 20, 2.2));
      path(_poly([4.5, 8, 2.8, 10, 4.5, 12, 2.8, 14, 4.5, 16]));
      path(_poly([19.5, 8, 21.2, 10, 19.5, 12, 21.2, 14, 19.5, 16]));
    case CMGlyph.trendUp:
      path(_poly([3.5, 17.5, 9.5, 11.5, 13, 15, 20.5, 7.5]));
      path(_poly([15, 7.5, 20.5, 7.5, 20.5, 13]));
    case CMGlyph.savings:
      c.drawOval(const Rect.fromLTRB(4, 14, 20, 18), s);
      path(_poly([4, 16, 4, 19, 20, 19, 20, 16]));
      c.drawOval(const Rect.fromLTRB(4, 9, 20, 13), s);
      path(_poly([4, 11, 4, 14.4]));
      path(_poly([20, 11, 20, 14.4]));
      c.drawOval(const Rect.fromLTRB(6.5, 3.5, 17.5, 7.5), s);
      line(6.5, 5.5, 6.5, 9.4);
      line(17.5, 5.5, 17.5, 9.4);
    case CMGlyph.register:
      rrect(_rr(3.5, 11, 20.5, 20.5, 2));
      rrect(_rr(6, 3.5, 15, 8, 1.4));
      line(10.5, 8, 10.5, 11);
      line(7, 15, 9, 15);
      line(11, 15, 13, 15);
      line(15, 15, 17, 15);
    case CMGlyph.play:
      circle(12, 12, 8.8);
      path(_poly([10, 8.5, 15.6, 12, 10, 15.5], close: true), f);
    case CMGlyph.logout:
      path(_poly([10, 4, 6, 4, 4.5, 5.5, 4.5, 18.5, 6, 20, 10, 20]));
      line(9.5, 12, 20, 12);
      path(_poly([16, 8, 20, 12, 16, 16]));
    case CMGlyph.code:
      path(_poly([8, 7, 3.5, 12, 8, 17]));
      path(_poly([16, 7, 20.5, 12, 16, 17]));
      line(13.6, 5, 10.4, 19);
    case CMGlyph.tools:
      path(
        Path()
          ..moveTo(14.6, 3.6)
          ..cubicTo(11.4, 3, 9, 6, 10.2, 9.2)
          ..lineTo(3.8, 15.6)
          ..quadraticBezierTo(2.8, 17.2, 4, 18.6)
          ..lineTo(5.4, 20)
          ..quadraticBezierTo(6.8, 21.2, 8.4, 20.2)
          ..lineTo(14.8, 13.8)
          ..cubicTo(18, 15, 21, 12.6, 20.4, 9.4)
          ..lineTo(17.4, 12.4)
          ..lineTo(14.8, 11.8)
          ..lineTo(14.2, 9.2)
          ..close(),
      );
    case CMGlyph.radioOff:
      circle(12, 12, 8.4);
    case CMGlyph.radioOn:
      circle(12, 12, 8.4);
      circle(12, 12, 4.4, f);
  }
}
