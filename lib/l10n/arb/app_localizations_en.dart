// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Iatros';

  @override
  String get appSubtitle => 'Your Health Companion';

  @override
  String get loginTitle => 'Login';

  @override
  String get registerTitle => 'Register';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get personalizationTitle => 'Personalization';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get biometricTitle => 'Use Biometrics';

  @override
  String get biometricSubtitle => 'Lock app with fingerprint or face ID';

  @override
  String get themeTitle => 'Light Theme';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get continueButton => 'Continue';

  @override
  String get logoutConfirmationTitle => 'Are you sure?';

  @override
  String get logoutConfirmationContent => 'Press continue to logout.';

  @override
  String get languageTitle => 'Language';
}
