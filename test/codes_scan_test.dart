// The member pass, reward and order codes must scan. This draws each one the
// way the app does (QR with the CM badge over its middle, Code 128 barcode)
// and decodes the image with zbar. Skipped where `zbarimg` isn't installed
// (brew install zbar).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/widgets/codes.dart';

final _zbar = [
  '/opt/homebrew/bin/zbarimg',
  '/usr/local/bin/zbarimg',
  '/usr/bin/zbarimg',
].where((p) => File(p).existsSync()).firstOrNull;

Future<String> _decode(WidgetTester tester, Widget code, Size size) async {
  final key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        // White all round, like the pass card: scanners need a quiet zone.
        child: ColoredBox(
          color: Colors.white,
          child: Padding(padding: const EdgeInsets.all(40), child: code),
        ),
      ),
    ),
  );
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${Directory.systemTemp.createTempSync('cm_code').path}/code.png')
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    final result = await Process.run(_zbar!, ['--quiet', '--raw', file.path]);
    return (result.stdout as String).trim();
  }))!;
}

/// The pass screen's QR: 230pt with a 54pt badge in the middle.
Widget _passQr(String data) => SizedBox(
  width: 230,
  height: 230,
  child: Stack(
    alignment: Alignment.center,
    children: [
      Positioned.fill(
        child: CustomPaint(painter: QrPainter(data: data)),
      ),
      Container(
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(5),
        color: Colors.white,
        child: const ColoredBox(color: Color(0xFF7C1335)),
      ),
    ],
  ),
);

void main() {
  final skip = _zbar == null ? 'zbarimg not installed' : null;

  testWidgets('member QR scans, badge and all', skip: skip != null, (tester) async {
    expect(await _decode(tester, _passQr('CM5035550123'), const Size(310, 310)), 'CM5035550123');
  });

  testWidgets('demo rotating member QR scans', skip: skip != null, (tester) async {
    expect(await _decode(tester, _passQr('CM5551234567-58723401'), const Size(310, 310)), 'CM5551234567-58723401');
  });

  testWidgets('member barcode scans', skip: skip != null, (tester) async {
    final bar = SizedBox(width: 300, height: 120, child: CustomPaint(painter: BarcodePainter('CM5035550123')));
    expect(await _decode(tester, bar, const Size(380, 200)), 'CM5035550123');
  });

  testWidgets('reward code barcode scans', skip: skip != null, (tester) async {
    final bar = SizedBox(width: 300, height: 76, child: CustomPaint(painter: BarcodePainter('CM988268500')));
    expect(await _decode(tester, bar, const Size(380, 160)), 'CM988268500');
  });

  testWidgets('order pickup QR scans', skip: skip != null, (tester) async {
    final qr = SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(painter: QrPainter(data: 'CM-ORDER-890')),
    );
    expect(await _decode(tester, qr, const Size(210, 210)), 'CM-ORDER-890');
  });
}
