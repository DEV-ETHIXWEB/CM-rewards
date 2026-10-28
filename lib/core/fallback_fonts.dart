import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The app's emoji, cut from Noto Color Emoji (Google Fonts, OFL).
const emojiFontFamily = 'CM Emoji';
const _emojiFontAsset = 'assets/fonts/NotoColorEmoji-CM.woff2';

/// Every emoji the app shows; the bundled text fonts have none of them, and
/// the emoji font above covers exactly these. test/fallback_fonts_test.dart
/// fails if one is added to lib/ and not here. To add one: append it, fetch
/// https://fonts.googleapis.com/css2?family=Noto+Color+Emoji&text=<these,
/// URL-encoded> with a Chrome user agent, and save the woff2 it links to.
const appEmoji =
    '☕⚡⛽⭐🇺🇸🌅🌯🍕🍗🍺🎁🎟️🏃📱🔥🥔🥤🥨🥩🧀🧊🧋🧾'
    '🐧🐨🐯🐰🐱🐶🐸🐻🐼🦁🦉🦊';

/// Browsers have no emoji font Flutter can draw with, so for any glyph the
/// bundled fonts lack, Flutter downloads Noto Color Emoji in pieces (1.75 MB
/// for these) and lays out every paragraph again each time one arrives,
/// which showed as a stutter on Home mid-scroll. Registering this 32 KB cut
/// before the app starts, as the theme's fallback, means nothing is missing.
/// Native builds use the system's emoji, as before.
Future<void> loadEmojiFont() async {
  if (!kIsWeb) return;
  try {
    final bytes = await rootBundle.load(_emojiFontAsset);
    await ui.loadFontFromList(bytes.buffer.asUint8List(), fontFamily: emojiFontFamily);
  } catch (_) {
    // Without it Flutter falls back to downloading the emoji it needs.
  }
}
