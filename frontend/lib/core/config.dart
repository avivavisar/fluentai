import 'package:web/web.dart' as web;

/// App configuration. `API_BASE_URL` can be injected via --dart-define; when empty
/// (the default) the app talks to its own origin (the static server proxies /v1 → backend),
/// which keeps a single stable public URL even across backend restarts.
class AppConfig {
  static const _apiOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl =>
      _apiOverride.isNotEmpty ? _apiOverride : web.window.location.origin;

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
