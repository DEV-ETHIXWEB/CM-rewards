import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Routes every uncaught error to one place. Hook a crash reporter (Sentry,
/// Crashlytics) into [report] before launch.
class ErrorReporting {
  ErrorReporting._();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true;
    };
    if (kReleaseMode) ErrorWidget.builder = (details) => const _FriendlyError();
  }

  static void report(Object error, StackTrace? stack) {
    // Release builds don't write errors to the device log, where other
    // tools could read them. Send them to a crash reporter here instead.
    if (!kReleaseMode) debugPrint('CM Rewards error: $error');
  }
}

/// Shown in place of a widget that failed to build, instead of a grey box.
class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Something went wrong here. Please try again.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(color: Brand.burgundy, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Registers the bundled fonts' licenses so they appear on the licenses page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [('Plus Jakarta Sans', 'PlusJakartaSans'), ('Zilla Slab', 'ZillaSlab')]) {
      final text = await rootBundle.loadString('assets/licenses/$file-OFL.txt');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
