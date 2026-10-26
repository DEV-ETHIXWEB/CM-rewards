// The HTTP client each platform should use. Native builds get the io
// version (URLSession on iOS and macOS); web builds get the browser's.
export 'platform_http_web.dart' if (dart.library.io) 'platform_http_io.dart';
