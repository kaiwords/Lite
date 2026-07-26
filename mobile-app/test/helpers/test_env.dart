// Shared test bootstrap.
//
// The app hard-requires `Supabase.initialize` before `LiteratureApp` can even
// build (the router reads `SupabaseService.client` while wiring its auth
// refresh listener — app_router.dart:34). Tests therefore initialize Supabase
// against a fake local URL. No request ever succeeds: inside `testWidgets`
// all HTTP is stubbed by flutter_test to return 400, and in plain `test`
// bodies the fake port is refused — both paths land in the app's existing
// catch/fallback branches.
//
// By default the environment is "authenticated": a hand-crafted session
// (unsigned JWT with a far-future exp) is injected through a custom
// [LocalStorage], so the router's redirect treats the tester as logged in and
// the real screens — not the login screen — are exercised.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:literature/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseReady = false;

Future<void> initTestEnv({bool authenticated = true}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await LocalStore.init();
  if (_supabaseReady) return;
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    publishableKey: 'sb_publishable_fake_test_key',
    debug: false,
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage:
          _SessionLocalStorage(authenticated ? _fakeSessionJson() : null),
    ),
  );
  _supabaseReady = true;
}

/// In-memory session storage seeded with an optional fake session, so
/// `Supabase.initialize` "recovers" a logged-in state without any network.
class _SessionLocalStorage extends LocalStorage {
  _SessionLocalStorage(this._session);
  String? _session;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => _session;

  @override
  Future<bool> hasAccessToken() async => _session != null;

  @override
  Future<void> persistSession(String persistSessionString) async =>
      _session = persistSessionString;

  @override
  Future<void> removePersistedSession() async => _session = null;
}

String _b64Url(Map<String, dynamic> m) =>
    base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

/// Unsigned JWT whose `exp` is far in the future, so the recovered session is
/// never considered expired and no refresh request is attempted.
String _fakeJwt() {
  final header = _b64Url({'alg': 'none', 'typ': 'JWT'});
  final payload = _b64Url({
    'exp': 9999999999,
    'sub': 'test-user-id',
    'role': 'authenticated',
  });
  return '$header.$payload.fake-signature';
}

String _fakeSessionJson() => jsonEncode({
      'access_token': _fakeJwt(),
      'expires_in': 3600,
      'refresh_token': 'fake-refresh-token',
      'token_type': 'bearer',
      'user': {
        'id': 'test-user-id',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'test@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    });
