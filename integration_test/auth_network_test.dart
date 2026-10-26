// Runs the real sign-in client on a device against a local server, so the
// platform networking (URLSession on iOS) is exercised end to end:
//   flutter test integration_test/auth_network_test.dart -d <device-id>
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:center_markets_rewards/data/auth_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign-in round trip through the platform HTTP client', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String>[];
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      seen.add('${request.method} ${request.uri.path} $body');
      request.response.headers.contentType = ContentType.json;
      switch (request.uri.path) {
        case '/v1/auth/code':
          request.response.statusCode = 204;
        case '/v1/auth/verify':
          final code = (jsonDecode(body) as Map<String, dynamic>)['code'];
          if (code == '123456') {
            request.response.write(jsonEncode({'token': 'device-token'}));
          } else {
            request.response
              ..statusCode = 401
              ..write(jsonEncode({'attemptsLeft': 4}));
          }
        default:
          request.response.statusCode = 404;
      }
      await request.response.close();
    });

    // No client passed in: the same one the app uses on this platform.
    final api = HttpAuthApi(Uri.parse('http://127.0.0.1:${server.port}/'));
    await tester.runAsync(() async {
      await api.requestCode('5035550123');
      await expectLater(
        api.verifyCode('5035550123', '000000'),
        throwsA(isA<AuthException>().having((e) => e.attemptsLeft, 'attemptsLeft', 4)),
      );
      final session = await api.verifyCode('5035550123', '123456');
      expect(session.token, 'device-token');
    });
    expect(seen.first, 'POST /v1/auth/code {"phone":"+15035550123"}');
  });
}
