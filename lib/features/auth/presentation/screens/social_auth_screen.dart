import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class SocialAuthScreen extends StatefulWidget {
  final String providerId;
  final String roleId;
  final String modeId;

  const SocialAuthScreen({
    super.key,
    required this.providerId,
    required this.roleId,
    required this.modeId,
  });

  @override
  State<SocialAuthScreen> createState() => _SocialAuthScreenState();
}

class _SocialAuthScreenState extends State<SocialAuthScreen> {
  static const _authRepository = AuthRepository();
  static const _userRepository = UserRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _linkCodeCtrl = TextEditingController();
  bool _isLoading = false;
  bool _passVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _linkCodeCtrl.dispose();
    super.dispose();
  }

  _ProviderUi get _provider {
    return switch (widget.providerId) {
      'apple' => const _ProviderUi(
        id: 'apple',
        label: 'Apple',
        icon: Icons.apple_rounded,
        accent: Color(0xFFC8D7F1),
        glow: Color(0xFF90A9D6),
        panel: Color(0xFF161D2A),
      ),
      'facebook' => const _ProviderUi(
        id: 'facebook',
        label: 'Facebook',
        icon: Icons.facebook_rounded,
        accent: Color(0xFF7CB5FF),
        glow: Color(0xFF2D6CDF),
        panel: Color(0xFF12294B),
      ),
      _ => const _ProviderUi(
        id: 'google',
        label: 'Google',
        icon: Icons.g_mobiledata_rounded,
        accent: Color(0xFFFFC83D),
        glow: Color(0xFFE0A800),
        panel: Color(0xFF2A2310),
      ),
    };
  }

  bool get _isAdmin => widget.roleId == 'admin';
  bool get _isSignup => widget.modeId == 'signup';

  RolUsuario get _selectedRole =>
      _isAdmin ? RolUsuario.administrador : RolUsuario.mayor;

  TipoAccesoUsuario get _accessType => switch (_provider.id) {
    'apple' => TipoAccesoUsuario.apple,
    'facebook' => TipoAccesoUsuario.facebook,
    _ => TipoAccesoUsuario.google,
  };

  String get _roleLabel => _isAdmin ? 'administrador' : 'usuario';

  String get _title => _isSignup
      ? 'Crear cuenta con\n${_provider.label}'
      : 'Iniciar sesion con\n${_provider.label}';

  String get _description => _isSignup
      ? 'Completa el alta dentro de la app y el perfil se guardara con auth_provider ${_accessType.name}.'
      : 'Accede desde la propia app con una pantalla inspirada en ${_provider.label}, pero usando tu cuenta guardada aqui.';

  String get _switchPrompt => _isSignup
      ? '¿Ya tienes cuenta con ${_provider.label}?'
      : '¿Aun no tienes cuenta con ${_provider.label}?';

  String get _switchLabel => _isSignup ? 'Iniciar sesion' : 'Crear cuenta';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignup) {
        await _authRepository.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          rol: _selectedRole,
          accessType: _accessType,
          linkCode: _isAdmin ? null : _linkCodeCtrl.text.trim(),
        );
      } else {
        await _authRepository.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          expectedAccessType: _accessType,
        );
      }

      final profile = await _userRepository.getSignedInUserProfile(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        _targetRoute(profile),
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

  String _targetRoute(Usuario? profile) {
    if (profile?.rol == RolUsuario.administrador) return AppRoutes.homeAdmin;
    if (profile == null) return AppRoutes.roleSelection;
    return profile.idAdministrador == null || profile.idAdministrador!.isEmpty
        ? AppRoutes.codigoManual
        : AppRoutes.homeUsuario;
  }

  String _mapAuthError(Object error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (message.contains('User already registered')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña no cumple la longitud mínima requerida.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return 'No se pudo completar la operación: $message';
  }

  void _switchProvider(AuthSocialProvider provider) {
    if (provider.id == _provider.id) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.socialAuth,
      arguments: {
        'providerId': provider.id,
        'roleId': widget.roleId,
        'modeId': widget.modeId,
      },
    );
  }

  void _switchMode() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.socialAuth,
      arguments: {
        'providerId': widget.providerId,
        'roleId': widget.roleId,
        'modeId': _isSignup ? 'login' : 'signup',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      variant: _isAdmin
          ? PremiumBackgroundVariant.dashboard
          : PremiumBackgroundVariant.warm,
      primaryGlowColor: _provider.glow,
      secondaryGlowColor: _provider.accent,
      primaryGlowAlignment: const Alignment(0.15, -0.78),
      secondaryGlowAlignment: const Alignment(0.98, 0.92),
      intensity: 0.86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
          const SizedBox(height: AppSpacing.lg),
          _ProviderHero(
            provider: _provider,
            isSignup: _isSignup,
            roleLabel: _roleLabel,
            title: _title,
            description: _description,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BottomProviderPanel(
            provider: _provider,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _isSignup ? 'Crear cuenta' : 'Iniciar sesion',
                        style: AppTextStyles.h4,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _provider.accent.withValues(alpha: 0.14),
                          borderRadius: AppRadius.chip,
                          border: Border.all(
                            color: _provider.accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          _accessType.label,
                          style: AppTextStyles.caption.copyWith(
                            color: _provider.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isSignup
                        ? 'Este acceso quedara guardado como ${_accessType.name} en Supabase.'
                        : 'Solo podras entrar aqui con cuentas creadas o asignadas a ${_accessType.label}.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _emailCtrl,
                    hint: 'Email',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduzca su email';
                      }
                      if (!value.contains('@')) return 'Email no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isSignup && !_isAdmin) ...[
                    AuthTextField(
                      controller: _linkCodeCtrl,
                      hint: 'Código del administrador',
                      icon: Icons.link_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        final normalized = value
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
                  ],
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Introduce una contraseña';
                      }
                      if (value.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  if (_isSignup) ...[
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _confirmCtrl,
                      hint: 'Confirmar contraseña',
                      icon: Icons.verified_user_outlined,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma la contraseña';
                        }
                        if (value != _passCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _isSignup
                        ? 'Crear con ${_provider.label}'
                        : 'Entrar con ${_provider.label}',
                    backgroundColor: _provider.glow,
                    foregroundColor: AppColors.textPrimary,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Volver',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text(
                          _switchPrompt,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: _switchMode,
                          child: Text(
                            _switchLabel,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _provider.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Cambiar de proveedor',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(child: AuthSocialRow(onProviderTap: _switchProvider)),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProviderUi {
  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final Color glow;
  final Color panel;

  const _ProviderUi({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.glow,
    required this.panel,
  });
}

class _ProviderHero extends StatelessWidget {
  final _ProviderUi provider;
  final bool isSignup;
  final String roleLabel;
  final String title;
  final String description;

  const _ProviderHero({
    required this.provider,
    required this.isSignup,
    required this.roleLabel,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            provider.panel,
            provider.panel.withValues(alpha: 0.92),
            AppColors.surfaceRaised,
          ],
        ),
        borderRadius: AppRadius.modal,
        border: Border.all(color: provider.accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: provider.glow.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: provider.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: provider.accent.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  provider.icon,
                  color: provider.accent,
                  size: provider.id == 'google' ? 44 : 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignup
                          ? 'Alta ${provider.label}'
                          : 'Acceso ${provider.label}',
                      style: AppTextStyles.overline.copyWith(
                        color: provider.accent,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel == 'administrador'
                          ? 'Panel profesional'
                          : 'Cuenta personal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomProviderPanel extends StatelessWidget {
  final _ProviderUi provider;
  final Widget child;

  const _BottomProviderPanel({required this.provider, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.modal,
        border: Border.all(color: provider.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: provider.accent.withValues(alpha: 0.36),
                borderRadius: AppRadius.chip,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
