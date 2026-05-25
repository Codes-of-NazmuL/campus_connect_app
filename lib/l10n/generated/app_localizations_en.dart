// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CampusConnect';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginSubtitle => 'Login to your account';

  @override
  String get emailHint => 'Enter email address';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get registerNow => ' Register now';

  @override
  String get emailOrStudentId => 'Email or Student ID';

  @override
  String get password => 'Password';
}
