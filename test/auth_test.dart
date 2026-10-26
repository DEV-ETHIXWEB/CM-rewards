// Sign-in against the server, and how a real (non-demo) build behaves:
// fail closed without a server, no sample member, no demo-only payments.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:center_markets_rewards/core/config.dart';
import 'package:center_markets_rewards/core/errors.dart';
import 'package:center_markets_rewards/data/auth_api.dart';
import 'package:center_markets_rewards/data/catalog.dart';
import 'package:center_markets_rewards/main.dart';
import 'package:center_markets_rewards/screens/order.dart';
import 'package:center_markets_rewards/screens/shell.dart';
import 'package:center_markets_rewards/state/storage.dart';

import 'support/fonts.dart';

final _base = Uri.parse('https://api.cm.test/');

HttpAuthApi _api(Future<http.Response> Function(http.Request request) handler) =>
    HttpAuthApi(_base, client: MockClient(handler), timeout: const Duration(seconds: 2));

/// A real build talking to a server that accepts the code 123456.
class _FakeServerAuth implements AuthApi {
  final deleted = <String>[];
  bool failDelete = false;

  @override
  bool get isDemo => false;

  @override
  Future<void> requestCode(String phoneDigits) async {}

  @override
  Future<AuthSession> verifyCode(String phoneDigits, String code) async {
    if (code != '123456') throw const AuthException(AuthFailure.invalidCode, attemptsLeft: 4);
    return const AuthSession('token-1');
  }

  @override
  Future<void> signOut(AuthSession session) async {}

  @override
  Future<void> deleteAccount(AuthSession session) async {
    if (failDelete) throw const AuthException(AuthFailure.network);
    deleted.add(session.token);
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('HttpAuthApi', () {
    test('requests a code for an E.164 number', () async {
      late http.Request sent;
      final api = _api((request) async {
        sent = request;
        return http.Response('', 204);
      });
      await api.requestCode('5035550123');
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.cm.test/v1/auth/code');
      expect(jsonDecode(sent.body), {'phone': '+15035550123'});
      expect(sent.headers['content-type'], startsWith('application/json'));
    });

    test('verifies a code and returns the session', () async {
      final api = _api((request) async => http.Response(jsonEncode({'token': 'abc'}), 200));
      final session = await api.verifyCode('5035550123', '123456');
      expect(session.token, 'abc');
    });

    test('maps server answers to failures', () async {
      Future<AuthFailure> failureFor(int status, [Map<String, Object>? body]) async {
        final api = _api((request) async => http.Response(body == null ? '' : jsonEncode(body), status));
        try {
          await api.verifyCode('5035550123', '111111');
        } on AuthException catch (e) {
          return e.failure;
        }
        fail('expected an AuthException');
      }

      expect(await failureFor(401), AuthFailure.invalidCode);
      expect(await failureFor(400, {'error': 'invalid_phone'}), AuthFailure.invalidPhone);
      expect(await failureFor(429), AuthFailure.rateLimited);
      expect(await failureFor(500), AuthFailure.server);
      // A 200 without a token is not a sign-in.
      expect(await failureFor(200, {'ok': true}), AuthFailure.server);
    });

    test('passes on the attempts the server has left', () async {
      final api = _api((request) async => http.Response(jsonEncode({'attemptsLeft': 2}), 401));
      await expectLater(
        api.verifyCode('5035550123', '111111'),
        throwsA(isA<AuthException>().having((e) => e.attemptsLeft, 'attemptsLeft', 2)),
      );
    });

    test('treats a dropped connection as a network failure', () async {
      final api = _api((request) async => throw const SocketException('offline'));
      await expectLater(
        api.requestCode('5035550123'),
        throwsA(isA<AuthException>().having((e) => e.failure, 'failure', AuthFailure.network)),
      );
    });

    test('deletes the account with the session token', () async {
      late http.Request sent;
      final api = _api((request) async {
        sent = request;
        return http.Response('', 204);
      });
      await api.deleteAccount(const AuthSession('tok'));
      expect(sent.method, 'DELETE');
      expect(sent.url.path, '/v1/account');
      expect(sent.headers['authorization'], 'Bearer tok');
    });
  });

  test('server URLs must be HTTPS, except on this machine', () {
    expect(AppConfig.parseApiUrl(''), isNull);
    expect(AppConfig.parseApiUrl('http://api.cm.test'), isNull);
    expect(AppConfig.parseApiUrl('not a url'), isNull);
    expect(AppConfig.parseApiUrl('https://api.cm.test/rewards').toString(), 'https://api.cm.test/rewards/');
    expect(AppConfig.parseApiUrl('http://127.0.0.1:8080').toString(), 'http://127.0.0.1:8080/');
  });

  test('without a server, sign-in is refused', () async {
    const api = UnavailableAuthApi();
    await expectLater(api.requestCode('5035550123'), throwsA(isA<AuthException>()));
    await expectLater(api.verifyCode('5035550123', '123456'), throwsA(isA<AuthException>()));
  });

  group('real builds', () {
    test('start with a blank member and only payments they can take', () {
      final state = RewardsState(null, const UnavailableAuthApi());
      expect(state.isDemo, isFalse);
      expect(state.points, 0);
      expect(state.name, isEmpty);
      expect(state.transactions, isEmpty);
      expect(state.availablePaymentMethods.map((m) => m.id), ['store']);
      expect(state.payment.id, 'store');
    });

    test('show no sample notices or challenge progress, and take no orders', () {
      final state = RewardsState(null, const UnavailableAuthApi());
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.challengeProgress(challenges.first), 0);
      expect(state.canPlaceOrders, isFalse);
      state.addToCart(menu.first, 0, 1);
      expect(() => state.placeOrder(storeNumber: 1, pickupMinutes: 10, payment: 'Pay at pickup'), throwsStateError);
      expect(state.orders, isEmpty);
      expect(state.points, 0);

      final demo = RewardsState(null, const DemoAuthApi());
      expect(demo.notifications, isNotEmpty);
      expect(demo.challengeProgress(challenges.first), challenges.first.progress);
      expect(demo.canPlaceOrders, isTrue);
    });

    test('a saved sign-in without a server session is not trusted', () async {
      final store = MemoryStore();
      final demo = RewardsState(store, const DemoAuthApi())..signIn('5035550123', skipProfile: true);
      await demo.flush();

      final real = await RewardsState.load(store: store, auth: const UnavailableAuthApi());
      expect(real.signedIn, isFalse);
    });

    test('keeps the session and drops a demo-only payment choice', () async {
      final store = MemoryStore();
      final auth = _FakeServerAuth();
      final state = RewardsState(store, auth)
        ..signIn('5035550123', session: const AuthSession('token-1'))
        ..setDefaultPayment('visa');
      await state.flush();

      final reloaded = await RewardsState.load(store: store, auth: auth);
      expect(reloaded.signedIn, isTrue);
      expect(reloaded.sessionToken, 'token-1');
      expect(reloaded.payment.id, 'store');
    });

    test('account deletion waits for the server', () async {
      final auth = _FakeServerAuth()..failDelete = true;
      final state = RewardsState(null, auth)..signIn('5035550123', session: const AuthSession('token-1'));

      await expectLater(state.deleteAccount(), throwsA(isA<AuthException>()));
      expect(state.signedIn, isTrue, reason: 'the account stays until the server confirms');

      auth.failDelete = false;
      await state.deleteAccount();
      expect(auth.deleted, ['token-1']);
      expect(state.signedIn, isFalse);
      expect(state.sessionToken, isNull);
    });
  });

  testWidgets('a build without a server explains that sign-in is unavailable', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(CenterMarketsApp(state: RewardsState(null, const UnavailableAuthApi())));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Explore in Demo Mode'), findsNothing);
    await tester.enterText(find.byType(TextField), '5035550123');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in isn’t available yet. Please check back soon.'), findsOneWidget);
    expect(find.text('Enter your code'), findsNothing);
  });

  testWidgets('a wrong code shows the tries the server has left', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = RewardsState(null, _FakeServerAuth());
    await tester.pumpWidget(CenterMarketsApp(state: state));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5035550123');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);
    expect(find.textContaining('Demo:'), findsNothing);

    await tester.enterText(find.byType(TextField), '111111');
    await tester.pumpAndSettle();
    expect(find.text('That code didn’t work. 4 tries left.'), findsOneWidget);

    // A full code submits on its own.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    // The checkmark shows briefly before the app moves on.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(state.signedIn, isTrue);
    expect(state.sessionToken, 'token-1');
    expect(state.points, 0);
  });

  for (final (width, height, scale) in [(320.0, 568.0, 2.0), (393.0, 852.0, 1.0), (1376.0, 1032.0, 1.0)]) {
    testWidgets('a new member\'s home and checkout lay out at ${width.round()}pt, text ${scale}x', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      addTearDown(tester.view.reset);

      final state = RewardsState(null, _FakeServerAuth())
        ..signIn('5035550123', skipProfile: true, session: const AuthSession('token-1'));
      await tester.pumpWidget(CenterMarketsApp(state: state));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      final home = find.byType(Scrollable).first;
      for (var i = 0; i < 8; i++) {
        await tester.drag(home, const Offset(0, -500), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      state.addToCart(menu.first, 0, 1);
      showCheckoutSheet(tester.element(find.byType(MainShell))).ignore();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Order Ahead opens soon'), findsOneWidget);
      await tester.tap(find.text('Order Ahead opens soon'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(state.orders, isEmpty);
    });
  }

  for (final dsn in ['not a dsn', 'https://abc@o0.ingest.sentry.invalid/1']) {
    testWidgets('the app still starts once with Sentry DSN "$dsn"', (tester) async {
      final onError = FlutterError.onError;
      final platformOnError = tester.binding.platformDispatcher.onError;
      final builder = ErrorWidget.builder;
      addTearDown(() async {
        await Sentry.close();
        FlutterError.onError = onError;
        tester.binding.platformDispatcher.onError = platformOnError;
        ErrorWidget.builder = builder;
      });
      var starts = 0;
      await tester.runAsync(() => ErrorReporting.run(() => starts++, dsn: dsn));
      expect(starts, 1);
    });
  }

  test('legal links must be published HTTPS pages', () {
    expect(AppConfig.parseLegalUrl(''), isNull);
    expect(AppConfig.parseLegalUrl('http://example.com/privacy'), isNull);
    expect(AppConfig.parseLegalUrl('https://example.com/privacy').toString(), 'https://example.com/privacy');
  });

  test('crash reports carry no member details', () {
    final event = SentryEvent(
      user: SentryUser(id: 'member', ipAddress: '1.2.3.4'),
      serverName: 'phone',
    );
    final scrubbed = ErrorReporting.scrub(event, Hint());
    expect(scrubbed.user, isNull);
    expect(scrubbed.serverName, isNull);

    final options = SentryFlutterOptions();
    ErrorReporting.configure(options);
    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    expect(options.attachViewHierarchy, isFalse);
  });
}
