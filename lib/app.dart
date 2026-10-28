import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/responsive.dart';
import 'core/theme.dart';
import 'screens/splash.dart';
import 'state/rewards_state.dart';

class CenterMarketsApp extends StatelessWidget {
  const CenterMarketsApp({super.key, required this.state});

  final RewardsState state;

  static final _light = buildTheme(CMColors.light);
  static final _dark = buildTheme(CMColors.dark);

  /// In a browser, MaterialApp's color becomes the toolbar color whenever the
  /// app rebuilds: the background of the theme in use, as each screen sets it.
  Color? _browserColor() {
    if (!kIsWeb) return null;
    final dark = switch (state.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    };
    return dark ? CMColors.dark.background : CMColors.light.background;
  }

  @override
  Widget build(BuildContext context) {
    return RewardsScope(
      state: state,
      child: ListenableBuilder(
        listenable: state.appearance,
        builder: (context, _) => MaterialApp(
          title: 'Center Market Rewards',
          color: _browserColor(),
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: state.themeMode,
          // Honor large accessibility text up to the scale the layouts are built for.
          builder: (context, child) =>
              MediaQuery.withClampedTextScaling(maxScaleFactor: Breakpoints.maxTextScale, child: child!),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
