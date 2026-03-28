import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/screens/home_admin_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_divider.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_hero_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crear_cuenta_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  static const String routeName = AppRoutes.adminLogin;
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const _authRepository = AuthRepository();
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

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeAdminScreen.routeName,
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final compact = height < 780;
    final topGap = compact ? AppSpacing.xs : AppSpacing.sm;
    final sectionGap = compact ? AppSpacing.lg : AppSpacing.xl;
    final innerGap = compact ? AppSpacing.sm : AppSpacing.md;
    final socialGap = compact ? AppSpacing.lg : AppSpacing.xl;
    final footerGap = compact ? AppSpacing.md : AppSpacing.lg;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topGap),
            const AppBackButton(),
            SizedBox(height: sectionGap),
            const AuthHeroCard(
              eyebrow: 'Acceso Administrador',
              title: 'Bienvenido\nde nuevo',
              description:
                  'Gestiona medicación, citas y alertas desde un panel claro y seguro.',
            ),
            SizedBox(height: sectionGap),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: innerGap),
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
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: Text(
                        '¿Ha olvidado la contraseña?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            PrimaryButton(
              label: 'Iniciar Sesión',
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textPrimary,
              height: compact ? 52 : 56,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            SizedBox(height: socialGap),
            const AuthDivider(),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            const AuthSocialRow(),
            SizedBox(height: footerGap),
            AuthSwitchLink(
              prompt: '¿No tiene cuenta? ',
              actionLabel: 'Crear cuenta',
              onPressed: () =>
                  Navigator.pushNamed(context, CrearCuentaScreen.routeName),
            ),
            SizedBox(height: footerGap),
          ],
        ),
      ),
    );
  }
}
