// Renders every CM glyph to a PNG contact sheet for design review:
//   flutter test test/tools/icon_sheet_test.dart --dart-define=OUT=/path/icons.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_markets_rewards/widgets/cm_icons.dart';

const _out = String.fromEnvironment('OUT');

void main() {
  testWidgets('icon contact sheet', (tester) async {
    if (_out.isEmpty) return;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(1200, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFFAF6F1),
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in CMGlyph.values)
                  SizedBox(
                    width: 108,
                    height: 100,
                    child: Column(
                      children: [
                        CMIcon(g, size: 56, color: const Color(0xFF7C1335)),
                        const SizedBox(height: 4),
                        Text(g.name, style: const TextStyle(fontSize: 11, color: Color(0xFF1C1416))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(_out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
