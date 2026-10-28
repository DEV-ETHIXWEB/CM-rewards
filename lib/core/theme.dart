import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/cm_icons.dart';
import 'fallback_fonts.dart';

// ─── Brand ────────────────────────────────────────────────────────────────────

/// Center Market brand colors, sampled from the logo.
class Brand {
  Brand._();

  static const burgundy = Color(0xFF7C1335);
  static const burgundyDeep = Color(0xFF3E0818);
  static const burgundyBright = Color(0xFFA8234D);
  static const green = Color(0xFF168A3B);
  static const greenDeep = Color(0xFF0B4F22);
  static const greenBright = Color(0xFF3CCB6B);
  static const champagne = Color(0xFFE6C78E);
  static const champagneDeep = Color(0xFF9C7430);
  static const ivory = Color(0xFFFAF6F1);
  static const ink = Color(0xFF1C1416);
  static const white = Color(0xFFFFFFFF);
}

/// Semantic colors that change with light and dark appearance.
@immutable
class CMColors extends ThemeExtension<CMColors> {
  const CMColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.primaryInk,
    required this.primarySoft,
    required this.positive,
    required this.positiveInk,
    required this.positiveSoft,
    required this.accent,
    required this.accentInk,
    required this.danger,
  });

  final Brightness brightness;

  /// Page background, a warm paper tone.
  final Color background;

  /// Cards and sheets.
  final Color surface;

  /// Insets inside cards: fields, tracks, quiet tiles.
  final Color surfaceAlt;
  final Color ink;
  final Color muted;

  /// Burgundy for fills (buttons, the member pass).
  final Color primary;

  /// Burgundy for text and icons on [surface].
  final Color primaryInk;
  final Color primarySoft;

  /// Kelly green: earning, open, success.
  final Color positive;
  final Color positiveInk;
  final Color positiveSoft;

  /// Champagne: the top tier and rare highlights.
  final Color accent;
  final Color accentInk;
  final Color danger;

  bool get isDark => brightness == Brightness.dark;
  Color get line => ink.withValues(alpha: isDark ? 0.10 : 0.07);
  Color get faint => ink.withValues(alpha: isDark ? 0.08 : 0.05);
  Color get hint => ink.withValues(alpha: 0.38);

  List<BoxShadow> elevation([double strength = 1]) => isDark
      ? const []
      : [
          BoxShadow(
            color: Brand.burgundyDeep.withValues(alpha: 0.06 * strength),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Brand.ink.withValues(alpha: 0.03 * strength),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  static const light = CMColors(
    brightness: Brightness.light,
    background: Brand.ivory,
    surface: Brand.white,
    surfaceAlt: Color(0xFFF3EDE7),
    ink: Brand.ink,
    muted: Color(0xFF6F6367),
    primary: Brand.burgundy,
    primaryInk: Brand.burgundy,
    primarySoft: Color(0xFFF7E8EC),
    positive: Brand.green,
    positiveInk: Color(0xFF117A33),
    positiveSoft: Color(0xFFE2F3E7),
    accent: Brand.champagne,
    accentInk: Brand.champagneDeep,
    danger: Color(0xFFC93A3A),
  );

  static const dark = CMColors(
    brightness: Brightness.dark,
    background: Color(0xFF0F0A0C),
    surface: Color(0xFF1A1316),
    surfaceAlt: Color(0xFF261C20),
    ink: Color(0xFFF6EEF0),
    muted: Color(0xFFA99BA0),
    primary: Brand.burgundyBright,
    primaryInk: Color(0xFFF08AA6),
    primarySoft: Color(0xFF3A1622),
    positive: Color(0xFF1E9E47),
    positiveInk: Color(0xFF5AD884),
    positiveSoft: Color(0xFF11301C),
    accent: Brand.champagne,
    accentInk: Brand.champagne,
    danger: Color(0xFFFF7A7A),
  );

  @override
  CMColors copyWith() => this;

  @override
  CMColors lerp(CMColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CMColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      primary: l(primary, other.primary),
      primaryInk: l(primaryInk, other.primaryInk),
      primarySoft: l(primarySoft, other.primarySoft),
      positive: l(positive, other.positive),
      positiveInk: l(positiveInk, other.positiveInk),
      positiveSoft: l(positiveSoft, other.positiveSoft),
      accent: l(accent, other.accent),
      accentInk: l(accentInk, other.accentInk),
      danger: l(danger, other.danger),
    );
  }
}

extension CMContext on BuildContext {
  CMColors get cm => Theme.of(this).extension<CMColors>()!;
}

// ─── Motion, shape, space ────────────────────────────────────────────────────

/// One motion language for the whole app. Short for feedback, medium for
/// layout changes, slow for arrivals.
class Motion {
  Motion._();

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 460);
  static const page = Duration(milliseconds: 520);

  /// Default ease: quick start, soft landing.
  static const standard = Curves.easeOutCubic;

  /// For things arriving on screen: a confident, decelerating glide.
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// A small overshoot for celebratory moments.
  static const spring = Curves.easeOutBack;
}

/// Corner radii, from chips to sheets.
class Radii {
  Radii._();

  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 26.0;
  static const xl = 32.0;
}

// ─── Type ─────────────────────────────────────────────────────────────────────

class AppText {
  AppText._();

  static const sans = 'Jakarta';

  /// Slab serif display face, a nod to the Center Market wordmark.
  static const slab = 'Zilla';

  static const hero = TextStyle(fontFamily: slab, fontSize: 40, fontWeight: FontWeight.w700, height: 1.0);
  static const display = TextStyle(fontFamily: slab, fontSize: 32, fontWeight: FontWeight.w700, height: 1.05);
  static const headline = TextStyle(fontFamily: slab, fontSize: 25, fontWeight: FontWeight.w700, height: 1.1);
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static const eyebrow = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6);
  static const tabular = [FontFeature.tabularFigures()];
}

// ─── Theme ────────────────────────────────────────────────────────────────────

extension BrowserChrome on SystemUiOverlayStyle {
  /// In a browser, also tints the browser's own toolbar (the page's
  /// theme-color) to [color], the color at the top of the screen, so the app
  /// and the browser read as one surface. Native status bars stay transparent.
  SystemUiOverlayStyle withBrowserColor(Color color) => kIsWeb ? copyWith(statusBarColor: color) : this;
}

ThemeData buildTheme(CMColors c) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    fontFamily: AppText.sans,
    fontFamilyFallback: kIsWeb ? const [emojiFontFamily] : null,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.burgundy,
      brightness: c.brightness,
      primary: c.primary,
      secondary: c.positive,
      tertiary: c.accent,
      surface: c.surface,
      error: c.danger,
    ),
  );
  final overlay = (c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).withBrowserColor(c.background);

  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink, fontFamily: AppText.sans),
    // The sparkle is a shader the browser compiles on the first tap; the web
    // build uses the plain ripple so the first tap responds at once.
    splashFactory: kIsWeb ? InkRipple.splashFactory : InkSparkle.splashFactory,
    dividerColor: c.line,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const CMIcon(CMGlyph.back, size: 24),
      closeButtonIconBuilder: (context) => const CMIcon(CMGlyph.close, size: 22),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: overlay,
      backgroundColor: c.background,
      surfaceTintColor: c.background,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.title.copyWith(color: c.ink, fontFamily: AppText.sans),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.isDark ? c.surfaceAlt : Brand.ink,
      contentTextStyle: const TextStyle(fontFamily: AppText.sans, color: Brand.white, fontWeight: FontWeight.w600),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.background, dragHandleColor: c.hint),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Brand.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.positive : null,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.primaryInk, selectionHandleColor: c.primaryInk),
  );
}
