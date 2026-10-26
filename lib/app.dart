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

  @override
  Widget build(BuildContext context) {
    return RewardsScope(
      state: state,
      child: ListenableBuilder(
        listenable: state.appearance,
        builder: (context, _) => MaterialApp(
          title: 'Center Market Rewards',
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
