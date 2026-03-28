import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static SupabaseClient? _client;
  static String? _initializationError;

  const SupabaseService._();

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isReady => _client != null;
  static String? get initializationError => _initializationError;

  static SupabaseClient get client {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase no esta inicializado. Ejecuta la app con '
        '--dart-define=SUPABASE_URL y --dart-define=SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  static User? get currentUser => _client?.auth.currentUser;
  static Session? get currentSession => _client?.auth.currentSession;
  static Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  static Future<void> initialize() async {
    if (_client != null) return;

    if (!isConfigured) {
      _initializationError =
          'Faltan SUPABASE_URL o SUPABASE_ANON_KEY. Ejecuta la app con '
          '--dart-define-from-file=env/dev.json o define ambas variables.';
      if (!isConfigured && kDebugMode) {
        debugPrint(_initializationError);
      }
      return;
    }

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _client = Supabase.instance.client;
      _initializationError = null;
    } catch (error) {
      _initializationError =
          'No se pudo inicializar Supabase: ${error.toString()}';
      rethrow;
    }
  }
}
