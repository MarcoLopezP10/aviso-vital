import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';

/// Maps authentication errors to user-facing Spanish messages.
abstract class AuthErrorMapper {
  /// For login screens (user and admin).
  static String fromLogin(Object error) {
    final message = error.toString();
    final strings = AppStrings.current;
    if (message.contains('Invalid login credentials')) {
      return strings.loginInvalidCredentials;
    }
    if (message.contains('Email not confirmed')) {
      return strings.emailNotConfirmed;
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return strings.isEnglish
        ? 'Could not sign in: $message'
        : 'No se pudo iniciar sesión: $message';
  }

  /// For the sign-up screen.
  static String fromSignup(Object error) {
    final message = error.toString();
    final strings = AppStrings.current;
    if (message.contains('User already registered')) {
      return strings.accountAlreadyExists;
    }
    if (message.contains('Password should be at least')) {
      return strings.passwordTooShort;
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return strings.isEnglish
        ? 'Could not create the account: $message'
        : 'No se pudo crear la cuenta: $message';
  }
}
