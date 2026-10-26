import 'package:flutter/foundation.dart';

/// Build-time switches, set with `--dart-define`.
class AppConfig {
  AppConfig._();

  /// Demo affordances: "Explore in Demo Mode", any-code sign-in and the
  /// "simulate a scan" button. On in debug builds and when building with
  /// `--dart-define=CM_DEMO=true`; off in store builds otherwise.
  static const demo = kDebugMode || bool.fromEnvironment('CM_DEMO');

  /// The CM Rewards server, from `--dart-define=CM_API_URL=https://...`.
  /// Must be HTTPS; plain HTTP is accepted only for this machine, in tests.
  static Uri? get apiBaseUrl => parseApiUrl(const String.fromEnvironment('CM_API_URL'));

  /// Sentry project DSN, from `--dart-define=CM_SENTRY_DSN=...`. Without it,
  /// crash reporting stays off.
  static const sentryDsn = String.fromEnvironment('CM_SENTRY_DSN');

  /// Which deployment crash reports belong to.
  static const environment = String.fromEnvironment(
    'CM_ENV',
    defaultValue: kReleaseMode ? (demo ? 'demo' : 'production') : 'development',
  );

  @visibleForTesting
  static Uri? parseApiUrl(String value) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) return null;
    // Resolve paths relative to the base, so "https://api/x" and "https://api/x/" agree.
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
}
