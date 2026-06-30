// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'FluentAI';

  @override
  String get welcome => 'ברוך הבא ל-FluentAI';

  @override
  String get tagline => 'מורה האנגלית החכם שלך';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get login => 'התחברות';

  @override
  String get signup => 'הרשמה';

  @override
  String get checkConnection => 'בדיקת חיבור לשרת';

  @override
  String get connected => 'מחובר';

  @override
  String get notConnected => 'לא מחובר';
}
