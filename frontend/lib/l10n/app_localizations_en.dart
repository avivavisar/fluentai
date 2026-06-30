// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FluentAI';

  @override
  String get welcome => 'Welcome to FluentAI';

  @override
  String get tagline => 'Your AI English tutor';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Log in';

  @override
  String get signup => 'Sign up';

  @override
  String get checkConnection => 'Check backend connection';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';
}
