// The web page shows the splash's loading dots while the engine downloads
// (web/index.html); the Flutter splash picks them up in step.
export 'splash_handoff_web.dart' if (dart.library.io) 'splash_handoff_io.dart';
