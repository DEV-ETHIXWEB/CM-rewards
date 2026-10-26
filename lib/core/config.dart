import 'package:flutter/foundation.dart';

/// Build-time switches, set with `--dart-define`.
class AppConfig {
  AppConfig._();

  /// Demo affordances: "Explore in Demo Mode", any-code sign-in and the
  /// "simulate a scan" button. On in debug builds and when building with
  /// `--dart-define=CM_DEMO=true`; off in store builds otherwise.
  static const demo = kDebugMode || bool.fromEnvironment('CM_DEMO');
}
