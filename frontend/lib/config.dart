class AppConfig {
  // Android emulator reaches the host machine at 10.0.2.2.
  // iOS simulator / desktop: use http://localhost:3000
  // Physical device: use your computer's LAN IP, e.g. http://192.168.1.50:3000
  // Override at build time: flutter run --dart-define=API_BASE_URL=http://...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
