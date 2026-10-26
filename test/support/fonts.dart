import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's bundled fonts so layout tests measure real text widths
/// instead of the test font's full-width placeholder glyphs.
Future<void> loadAppFonts() async {
  Future<void> load(String family, String prefix) async {
    final loader = FontLoader(family);
    for (final file in Directory('assets/fonts').listSync().whereType<File>()) {
      if (file.path.split('/').last.startsWith(prefix)) {
        loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()))));
      }
    }
    await loader.load();
  }

  await load('Jakarta', 'PlusJakartaSans');
  await load('Zilla', 'ZillaSlab');
}
