import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/shared/utils/auth_error_mapper.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_hero_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_password_reset_dialog.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aviso_vital_2/features/user_home/presentation/screens/home_usuario_screen.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/validators.dart';
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

      final String target;
      if (profile.rol == RolUsuario.administrador) {
        target = AppRoutes.homeAdmin;
      } else if (profile.idAdministrador == null ||
          profile.idAdministrador!.isEmpty) {
        target = AppRoutes.codigoManual;
      } else {
        target = HomeUsuarioScreen.routeName;
      }
      Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthErrorMapper.fromLogin(error))));
    }
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
    final sectionGap = compact ? AppSpacing.md : AppSpacing.xl;
    final footerGap = compact ? AppSpacing.sm : AppSpacing.lg;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const AppBackButton(),
            SizedBox(height: sectionGap),
            AuthHeroCard(
              eyebrow: strings.userAccess,
              eyebrowColor: AppColors.amberLight,
              title: strings.userLoginTitle,
              description: strings.userLoginDescription,
            ),
            SizedBox(height: sectionGap),
            AuthFormCard(
              child: Column(
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
                  const SizedBox(height: AppSpacing.md),
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
                          color: AppColors.amberLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            PrimaryButton(
              label: strings.userSignIn,
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.textOnAmber,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            SizedBox(height: footerGap),
            AuthSwitchLink(
              prompt: strings.noAccountPrompt,
              actionLabel: strings.createAccount,
              onPressed: () =>
                  Navigator.pushNamed(context, UserSignupScreen.routeName),
            ),
            SizedBox(height: footerGap),
          ],
        ),
      ),
    );
  }
}
