import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_route_args.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/screens/home_admin_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_divider.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_hero_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_password_reset_dialog.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/auth_error_mapper.dart';
import 'package:aviso_vital_2/shared/utils/validators.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'crear_cuenta_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  static const String routeName = AppRoutes.adminLogin;
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
        throw StateError('No se pudo cargar el perfil.');
      }
      if (profile.rol != RolUsuario.administrador) {
        await _authRepository.signOut();
        throw StateError(
          'Esta pantalla es solo para administradores. Usa el acceso de usuario mayor.',
        );
      }
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
      ).showSnackBar(SnackBar(content: Text(AuthErrorMapper.fromLogin(error))));
    }
  }

  void _openSocialLogin(AuthSocialProvider provider) {
    Navigator.pushNamed(
      context,
      AppRoutes.socialAuth,
      arguments: SocialAuthRouteArgs(
        providerId: provider.id,
        roleId: 'admin',
        modeId: 'login',
      ),
    );
  }

  Future<void> _openPasswordReset() {
    return showAuthPasswordResetDialog(
      context,
      authRepository: _authRepository,
      initialEmail: _emailCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
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
            AuthHeroCard(
              eyebrow: strings.adminAccess,
              title: strings.welcomeBack,
              description: strings.adminLoginDescription,
            ),
            SizedBox(height: sectionGap),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthTextField(
                    controller: _emailCtrl,
                    hint: strings.email,
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return strings.enterEmail;
                      }
                      if (!AppValidators.isValidEmail(v)) {
                        return strings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: innerGap),
                  AuthTextField(
                    controller: _passCtrl,
                    hint: strings.password,
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
                        return strings.enterPassword;
                      }
                      if (v.length < 6) return strings.minSixChars;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openPasswordReset,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: Text(
                        strings.forgotPassword,
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
              label: strings.adminSignIn,
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textPrimary,
              height: compact ? 52 : 56,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            SizedBox(height: socialGap),
            const AuthDivider(),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            AuthSocialRow(onProviderTap: _openSocialLogin),
            SizedBox(height: footerGap),
            AuthSwitchLink(
              prompt: strings.noAccountPrompt,
              actionLabel: strings.createAccount,
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
