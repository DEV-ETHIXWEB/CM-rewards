import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/errors.dart';
import 'core/responsive.dart';
import 'state/rewards_state.dart';

export 'app.dart';
export 'state/rewards_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ErrorReporting.run(() async {
    registerFontLicenses();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await _lockPhonesToPortrait();
    final state = await RewardsState.load();
    runApp(CenterMarketsApp(state: state));
  });
}

/// Phones stay in portrait, like most member apps. Tablets rotate freely,
/// which iPad multitasking requires.
Future<void> _lockPhonesToPortrait() async {
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view == null) return;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide < Breakpoints.tablet) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
