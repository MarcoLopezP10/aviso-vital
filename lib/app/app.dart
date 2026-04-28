import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aviso_vital_2/app/router/app_router.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/screens/home_admin_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/codigo_manual_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/role_selection_screen.dart';
import 'package:aviso_vital_2/features/user_home/presentation/screens/home_usuario_screen.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

/// Punto de entrada de la aplicación Aviso Vital.
class AvisoVitalApp extends StatelessWidget {
  const AvisoVitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocaleController.instance.language,
      builder: (context, language, _) {
        return MaterialApp(
          key: ValueKey('aviso-vital-${language.locale.languageCode}'),
          title: 'Aviso Vital',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: language.locale,
          supportedLocales: AppLanguage.values
              .map((language) => language.locale)
              .toList(growable: false),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) {
            final scale = MediaQuery.of(context)
                .textScaler
                .scale(1.0)
                .clamp(1.0, 1.3);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            );
          },
          home: const _AppBootstrapScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}

class _AppBootstrapScreen extends StatefulWidget {
  const _AppBootstrapScreen();

  @override
  State<_AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<_AppBootstrapScreen> {
  late Future<Usuario?> _profileFuture;
  StreamSubscription<dynamic>? _authSubscription;

  static const _carePlanContextService = CarePlanContextService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    if (SupabaseService.isReady) {
      _authSubscription = SupabaseService.authStateChanges.listen((_) {
        if (!mounted) return;
        setState(() => _profileFuture = _loadProfile());
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<Usuario?> _loadProfile() async {
    final context = await _carePlanContextService.resolve();
    return context.viewerProfile;
  }

  @override
  Widget build(BuildContext context) {
    final configError = SupabaseService.initializationError;
    if (configError != null) {
      return _ConfigurationErrorScreen(message: configError);
    }

    if (!SupabaseService.isReady) {
      return const RoleSelectionScreen();
    }

    return FutureBuilder<Usuario?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        if (profileSnapshot.hasError) {
          return ErrorRetryView(
            message: context.t.loadErrorMessage,
            onRetry: () => setState(() => _profileFuture = _loadProfile()),
          );
        }

        final profile = profileSnapshot.data;
        if (profile == null) return const RoleSelectionScreen();
        if (profile.rol == RolUsuario.mayor &&
            (profile.idAdministrador == null ||
                profile.idAdministrador!.isEmpty)) {
          return const CodigoManualScreen();
        }

        return profile.rol == RolUsuario.administrador
            ? const HomeAdminScreen()
            : const HomeUsuarioScreen();
      },
    );
  }
}

class _ConfigurationErrorScreen extends StatelessWidget {
  final String message;

  const _ConfigurationErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  strings.supabaseConfigTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  strings.supabaseConfigExample,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
