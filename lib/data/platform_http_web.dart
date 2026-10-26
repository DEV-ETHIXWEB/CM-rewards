import 'package:http/http.dart' as http;

/// In a browser, the browser's own networking (fetch).
http.Client platformHttpClient() => http.Client();
