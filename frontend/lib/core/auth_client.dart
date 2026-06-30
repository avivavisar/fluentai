import 'package:gotrue/gotrue.dart';
import 'package:web/web.dart' as web;
import 'config.dart';

/// Pure-Dart Supabase auth (GoTrue) with browser-localStorage session persistence.
/// (supabase_flutter is avoided on this machine: it transitively pulls objective_c,
/// whose native-assets build hook breaks on the spaced user path. We re-add it for mobile later.)
class AuthClient {
  AuthClient._() {
    client = GoTrueClient(
      url: '${AppConfig.supabaseUrl}/auth/v1',
      headers: {'apikey': AppConfig.supabaseAnonKey},
      autoRefreshToken: true,
    );
    client.onAuthStateChange.listen((state) {
      final refreshToken = state.session?.refreshToken;
      if (refreshToken != null) {
        web.window.localStorage.setItem(_key, refreshToken);
      } else {
        web.window.localStorage.removeItem(_key);
      }
    });
  }

  static const _key = 'fluentai.refresh_token';
  static final AuthClient instance = AuthClient._();

  late final GoTrueClient client;

  /// Restore a saved session on app startup (web) by exchanging the refresh token.
  Future<void> restore() async {
    final refreshToken = web.window.localStorage.getItem(_key);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await client.setSession(refreshToken);
      } catch (_) {
        web.window.localStorage.removeItem(_key);
      }
    }
  }
}
