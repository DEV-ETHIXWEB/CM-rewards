import 'dart:io';

import 'package:center_markets_rewards/core/fallback_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Emoji and pictographs, which the bundled fonts don't cover.
bool _isEmoji(int rune) =>
    (rune >= 0x2600 && rune <= 0x27BF) || (rune >= 0x2B00 && rune <= 0x2BFF) || (rune >= 0x1F000 && rune <= 0x1FAFF);

void main() {
  test('every emoji in the app is warmed up at launch on the web', () {
    final warmed = appEmoji.runes.toSet();
    final missing = <String, String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final rune in file.readAsStringSync().runes) {
        if (_isEmoji(rune) && !warmed.contains(rune)) missing[String.fromCharCode(rune)] = file.path;
      }
    }
    expect(missing, isEmpty, reason: 'Add these to appEmoji in lib/core/fallback_fonts.dart');
  });
}
