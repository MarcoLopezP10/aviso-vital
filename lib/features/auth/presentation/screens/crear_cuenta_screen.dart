import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
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
import 'admin_login_screen.dart';

class CrearCuentaScreen extends StatefulWidget {
  static const String routeName = AppRoutes.crearCuenta;
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  static const _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _passVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authRepository.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        rol: RolUsuario.administrador,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente.')),
      );
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

  void _openSocialSignup(AuthSocialProvider provider) {
    Navigator.pushNamed(
      context,
      AppRoutes.socialAuth,
      arguments: {
        'providerId': provider.id,
        'roleId': 'admin',
        'modeId': 'signup',
      },
    );
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
              eyebrowColor: AppColors.orangeLight,
              title: 'Crear una\ncuenta',
              description:
                  'Crea tu acceso para gestionar medicación, citas y alertas con la misma claridad visual del panel.',
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
                        return 'Introduce una contraseña';
                      }
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  SizedBox(height: innerGap),
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
                  const SizedBox(height: AppSpacing.md),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        const TextSpan(text: 'Al crear una cuenta acepta las '),
                        TextSpan(
                          text: 'Políticas de Privacidad',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            PrimaryButton(
              label: 'Crear Cuenta',
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textPrimary,
              height: compact ? 52 : 56,
              isLoading: _isLoading,
              onPressed: _crear,
            ),
            SizedBox(height: socialGap),
            const AuthDivider(),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            AuthSocialRow(onProviderTap: _openSocialSignup),
            SizedBox(height: footerGap),
            AuthSwitchLink(
              prompt: '¿Ya tiene cuenta? ',
              actionLabel: 'Iniciar sesión',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AdminLoginScreen.routeName,
              ),
            ),
            SizedBox(height: footerGap),
          ],
        ),
      ),
    );
  }
}
