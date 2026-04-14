import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_divider.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_hero_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aviso_vital_2/features/user_home/presentation/screens/home_usuario_screen.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

import 'user_signup_screen.dart';

class UserLoginScreen extends StatefulWidget {
  static const String routeName = AppRoutes.userLogin;
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  static const _authRepository = AuthRepository();
  static const _userRepository = UserRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final profile = await _userRepository.getSignedInUserProfile();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (profile == null) {
        throw StateError('No se pudo cargar el perfil del usuario.');
      }
      if (profile.rol != RolUsuario.mayor) {
        throw StateError(
          'Esta pantalla es solo para usuarios mayores. Usa el acceso de administrador.',
        );
      }

      final target =
          profile.idAdministrador == null || profile.idAdministrador!.isEmpty
          ? AppRoutes.codigoManual
          : HomeUsuarioScreen.routeName;
      Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error))));
    }
  }

  String _mapAuthError(Object error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return 'No se pudo iniciar sesión: $message';
  }

  void _openSocialLogin(AuthSocialProvider provider) {
    Navigator.pushNamed(
      context,
      AppRoutes.socialAuth,
      arguments: {'providerId': provider.id, 'roleId': 'user'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const AppBackButton(),
            const SizedBox(height: AppSpacing.xl),
            const AuthHeroCard(
              eyebrow: 'Acceso Usuario',
              eyebrowColor: AppColors.amberLight,
              title: 'Tu espacio\nde avisos',
              description:
                  'Accede a tus recordatorios y a la simulación en tiempo real con tu cuenta.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthFormCard(
              child: Column(
                children: [
                  AuthTextField(
                    controller: _emailCtrl,
                    hint: 'Email',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Introduzca su email';
                      }
                      if (!v.contains('@')) return 'Email no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _passCtrl,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_passVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _passVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _passVisible = !_passVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Introduzca su contraseña';
                      }
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Entrar como usuario',
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.textOnAmber,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.xl),
            const AuthDivider(),
            const SizedBox(height: AppSpacing.xl),
            AuthSocialRow(onProviderTap: _openSocialLogin),
            const SizedBox(height: AppSpacing.lg),
            AuthSwitchLink(
              prompt: '¿No tienes cuenta? ',
              actionLabel: 'Crear cuenta',
              onPressed: () =>
                  Navigator.pushNamed(context, UserSignupScreen.routeName),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
