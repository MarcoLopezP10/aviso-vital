import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
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

import 'user_login_screen.dart';

class UserSignupScreen extends StatefulWidget {
  static const String routeName = AppRoutes.userCrearCuenta;
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  static const _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _linkCodeCtrl = TextEditingController();
  bool _passVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _linkCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authRepository.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        rol: RolUsuario.mayor,
        linkCode: _linkCodeCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeUsuarioScreen.routeName,
        (_) => false,
      );
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
              eyebrow: 'Alta Usuario',
              eyebrowColor: AppColors.amberLight,
              title: 'Crear cuenta\ny vincular',
              description:
                  'Crea tu cuenta y enlázala al administrador usando su código de vinculación.',
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
                    controller: _linkCodeCtrl,
                    hint: 'Código del administrador',
                    icon: Icons.link_rounded,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      final normalized = v
                          ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                          .trim();
                      if (normalized == null || normalized.isEmpty) {
                        return 'Introduce el código del administrador';
                      }
                      if (normalized.length != 6) {
                        return 'El código debe tener 6 caracteres';
                      }
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
                        return 'Introduce una contraseña';
                      }
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _confirmCtrl,
                    hint: 'Confirmar contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_confirmVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirma la contraseña';
                      }
                      if (v != _passCtrl.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Crear cuenta de usuario',
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.textOnAmber,
              isLoading: _isLoading,
              onPressed: _crear,
            ),
            const SizedBox(height: AppSpacing.xl),
            const AuthDivider(),
            const SizedBox(height: AppSpacing.xl),
            const AuthSocialRow(),
            const SizedBox(height: AppSpacing.lg),
            AuthSwitchLink(
              prompt: '¿Ya tienes cuenta? ',
              actionLabel: 'Iniciar sesión',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                UserLoginScreen.routeName,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
