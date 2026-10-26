import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Why a sign-in step failed, so the screen can say something useful.
enum AuthFailure {
  /// The code was wrong. [AuthException.attemptsLeft] may say how many tries remain.
  invalidCode,

  /// Too many codes or tries; the server asks the member to wait.
  rateLimited,

  /// The phone number was rejected.
  invalidPhone,

  /// No connection, or the server didn't answer in time.
  network,

  /// The server answered with something unexpected.
  server,

  /// This build has no sign-in server configured.
  unavailable,
}

class AuthException implements Exception {
  const AuthException(this.failure, {this.attemptsLeft});

  final AuthFailure failure;
  final int? attemptsLeft;

  @override
  String toString() => 'AuthException($failure)';
}

/// A signed-in session issued by the server.
class AuthSession {
  const AuthSession(this.token);

  final String token;
}

/// Phone sign-in: text a one-time code, trade it for a session, and delete
/// the account on request (App Store Review Guideline 5.1.1(v)).
///
/// The HTTP contract is in docs/backend-api.md.
abstract class AuthApi {
  /// Picks the implementation for this build: the real server when
  /// `CM_API_URL` is set, simulated codes in demo builds, and otherwise one
  /// that refuses to sign anyone in.
  factory AuthApi.forBuild() {
    final base = AppConfig.apiBaseUrl;
    if (base != null) return HttpAuthApi(base);
    if (AppConfig.demo) return const DemoAuthApi();
    return const UnavailableAuthApi();
  }

  /// Whether this build runs on demo data with simulated sign-in.
  bool get isDemo;

  /// Texts a code to [phoneDigits], ten US digits.
  Future<void> requestCode(String phoneDigits);

  /// Trades the code the member typed for a session.
  Future<AuthSession> verifyCode(String phoneDigits, String code);

  /// Ends the session on the server. Best effort: signing out locally always works.
  Future<void> signOut(AuthSession session);

  /// Permanently deletes the member's account and data on the server.
  Future<void> deleteAccount(AuthSession session);
}

/// Demo builds: no texts are sent, any code but 000000 works.
class DemoAuthApi implements AuthApi {
  const DemoAuthApi();

  static const _delay = Duration(milliseconds: 900);

  @override
  bool get isDemo => true;

  @override
  Future<void> requestCode(String phoneDigits) => Future<void>.delayed(_delay);

  @override
  Future<AuthSession> verifyCode(String phoneDigits, String code) async {
    await Future<void>.delayed(_delay);
    if (code == '000000') throw const AuthException(AuthFailure.invalidCode);
    return const AuthSession('demo');
  }

  @override
  Future<void> signOut(AuthSession session) async {}

  @override
  Future<void> deleteAccount(AuthSession session) async {}
}

/// Release builds without a server: sign-in fails closed rather than letting
/// anyone in with any code.
class UnavailableAuthApi implements AuthApi {
  const UnavailableAuthApi();

  @override
  bool get isDemo => false;

  @override
  Future<void> requestCode(String phoneDigits) async => throw const AuthException(AuthFailure.unavailable);

  @override
  Future<AuthSession> verifyCode(String phoneDigits, String code) async =>
      throw const AuthException(AuthFailure.unavailable);

  @override
  Future<void> signOut(AuthSession session) async {}

  @override
  Future<void> deleteAccount(AuthSession session) async => throw const AuthException(AuthFailure.unavailable);
}

/// Talks to the CM Rewards server over HTTPS (TLS from the Flutter engine).
class HttpAuthApi implements AuthApi {
  HttpAuthApi(this.baseUrl, {http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  bool get isDemo => false;

  @override
  Future<void> requestCode(String phoneDigits) async {
    await _send('POST', 'v1/auth/code', body: {'phone': '+1$phoneDigits'});
  }

  @override
  Future<AuthSession> verifyCode(String phoneDigits, String code) async {
    final json = await _send('POST', 'v1/auth/verify', body: {'phone': '+1$phoneDigits', 'code': code});
    final token = json?['token'];
    if (token is! String || token.isEmpty) throw const AuthException(AuthFailure.server);
    return AuthSession(token);
  }

  @override
  Future<void> signOut(AuthSession session) async {
    try {
      await _send('POST', 'v1/auth/logout', token: session.token);
    } on AuthException {
      // The local session is cleared either way; the server token expires on its own.
    }
  }

  @override
  Future<void> deleteAccount(AuthSession session) async {
    await _send('DELETE', 'v1/account', token: session.token);
  }

  Future<Map<String, dynamic>?> _send(String method, String path, {Map<String, Object>? body, String? token}) async {
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['accept'] = 'application/json'
      ..headers['user-agent'] = 'CMRewards';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout)).timeout(timeout);
    } on TimeoutException {
      throw const AuthException(AuthFailure.network);
    } on http.ClientException {
      throw const AuthException(AuthFailure.network);
    } on SocketException {
      throw const AuthException(AuthFailure.network);
    }

    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        json = null;
      }
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return json;
    final left = json?['attemptsLeft'];
    throw switch (status) {
      400 when json?['error'] == 'invalid_phone' => const AuthException(AuthFailure.invalidPhone),
      400 || 401 || 403 => AuthException(AuthFailure.invalidCode, attemptsLeft: left is int ? left : null),
      429 => const AuthException(AuthFailure.rateLimited),
      _ => const AuthException(AuthFailure.server),
    };
  }
}
