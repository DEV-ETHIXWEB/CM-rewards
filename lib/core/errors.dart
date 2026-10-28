import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config.dart';
import 'theme.dart';

/// Routes every error to one place: the debug console during development and
/// Sentry in builds made with `--dart-define=CM_SENTRY_DSN=...`.
class ErrorReporting {
  ErrorReporting._();

  /// Whether crash reports leave the device in this build.
  static bool get enabled => AppConfig.sentryDsn.isNotEmpty;

  /// Installs the handlers, starts Sentry when configured, then runs the app.
  /// Sentry captures uncaught errors itself and then calls these handlers, so
  /// they only log; otherwise every crash would be reported twice.
  static Future<void> run(FutureOr<void> Function() app, {@visibleForTesting String? dsn}) async {
    final key = dsn ?? AppConfig.sentryDsn;
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _log(error);
      return true;
    };
    if (kReleaseMode) ErrorWidget.builder = (details) => const _FriendlyError();
    if (key.isEmpty) return app();
    // A bad DSN or a native SDK failure must never keep the app from opening:
    // if Sentry fails before the app starts, start it without crash reports.
    var started = false;
    try {
      await SentryFlutter.init(
        (options) {
          configure(options);
          options.dsn = key;
        },
        appRunner: () {
          started = true;
          return app();
        },
      );
    } catch (error) {
      _log(error);
      if (!started) await app();
    }
  }

  @visibleForTesting
  static void configure(SentryFlutterOptions options) {
    options
      ..dsn = AppConfig.sentryDsn
      ..environment = AppConfig.environment
      // No IP addresses, cookies or user details; no screenshots or view
      // trees, which could show a member's phone number or points.
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..attachViewHierarchy = false
      // Crashes only: no performance tracing.
      ..tracesSampleRate = null
      ..beforeSend = scrub;
  }

  /// Drops anything that identifies the member before a report is sent.
  @visibleForTesting
  static SentryEvent scrub(SentryEvent event, Hint hint) {
    event
      ..user = null
      ..serverName = null;
    return event;
  }

  /// For errors the app handles itself but still wants to hear about.
  static void report(Object error, StackTrace? stack) {
    _log(error);
    if (enabled) unawaited(Sentry.captureException(error, stackTrace: stack));
  }

  // Release builds don't write errors to the device log, where other tools
  // could read them.
  static void _log(Object error) {
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
    for (final (font, file) in [
      ('Plus Jakarta Sans', 'PlusJakartaSans'),
      ('Zilla Slab', 'ZillaSlab'),
      ('Noto Color Emoji', 'NotoColorEmoji'),
    ]) {
      final text = await rootBundle.loadString('assets/licenses/$file-OFL.txt');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
