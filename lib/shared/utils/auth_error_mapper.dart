import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps authentication errors to user-facing Spanish messages.
abstract class AuthErrorMapper {
  /// For login screens (user and admin).
  static String fromLogin(Object error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme su email antes de iniciar sesión.';
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return 'No se pudo iniciar sesión: $message';
  }

  /// For the sign-up screen.
  static String fromSignup(Object error) {
    final message = error.toString();
    if (message.contains('User already registered')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña no cumple la longitud mínima requerida.';
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return 'No se pudo crear la cuenta: $message';
  }
}
