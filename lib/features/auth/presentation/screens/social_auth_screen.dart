import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/app/router/app_route_args.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/utils/validators.dart';

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
  late String _providerId;
  bool _isLoading = false;
  bool _passVisible = false;
  bool _confirmVisible = false;

  @override
  void initState() {
    super.initState();
    _providerId = widget.providerId;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _linkCodeCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.roleId == 'admin';
  bool get _isSignup => widget.modeId == 'signup';

  RolUsuario get _selectedRole =>
      _isAdmin ? RolUsuario.administrador : RolUsuario.mayor;

  TipoAccesoUsuario get _accessType => switch (_providerId) {
    'apple' => TipoAccesoUsuario.apple,
    'facebook' => TipoAccesoUsuario.facebook,
    _ => TipoAccesoUsuario.google,
  };

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
    final strings = AppStrings.current;
    if (message.contains('Invalid login credentials')) {
      return strings.loginInvalidCredentials;
    }
    if (message.contains('User already registered')) {
      return strings.accountAlreadyExists;
    }
    if (message.contains('Password should be at least')) {
      return strings.passwordTooShort;
    }
    if (message.contains('Email not confirmed')) {
      return strings.emailNotConfirmed;
    }
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    if (error is StateError) return message.replaceFirst('Bad state: ', '');
    return strings.operationFailed(message);
  }

  void _switchProvider(AuthSocialProvider provider) {
    if (provider.id == _providerId) return;
    setState(() {
      _providerId = provider.id;
      _emailCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
      _linkCodeCtrl.clear();
    });
  }

  void _switchMode() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.socialAuth,
      arguments: SocialAuthRouteArgs(
        providerId: _providerId,
        roleId: widget.roleId,
        modeId: _isSignup ? 'login' : 'signup',
      ),
    );
  }

  _AuthViewData get _viewData => _AuthViewData(
    formKey: _formKey,
    emailCtrl: _emailCtrl,
    passCtrl: _passCtrl,
    confirmCtrl: _confirmCtrl,
    linkCodeCtrl: _linkCodeCtrl,
    isSignup: _isSignup,
    isAdmin: _isAdmin,
    isLoading: _isLoading,
    passVisible: _passVisible,
    confirmVisible: _confirmVisible,
    onTogglePass: () => setState(() => _passVisible = !_passVisible),
    onToggleConfirm: () => setState(() => _confirmVisible = !_confirmVisible),
    onSubmit: _submit,
    onSwitchMode: _switchMode,
    onSwitchProvider: _switchProvider,
    currentProviderId: _providerId,
  );

  @override
  Widget build(BuildContext context) {
    final data = _viewData;
    return switch (_providerId) {
      'facebook' => _FacebookAuthView(data: data),
      'apple' => _AppleAuthView(data: data),
      _ => _GoogleAuthView(data: data),
    };
  }
}

String? _validateEmail(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return context.t.enterEmail;
  }
  if (!AppValidators.isValidEmail(value)) {
    return context.t.invalidEmail;
  }
  return null;
}

String? _validateLinkCode(BuildContext context, String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return context.t.enterAdminCode;
  }
  if (!AppValidators.isValidLinkCode(raw)) {
    return context.t.adminCodeLength;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Data container
// ---------------------------------------------------------------------------

class _AuthViewData {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController linkCodeCtrl;
  final bool isSignup;
  final bool isAdmin;
  final bool isLoading;
  final bool passVisible;
  final bool confirmVisible;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final ValueChanged<AuthSocialProvider> onSwitchProvider;
  final String currentProviderId;

  const _AuthViewData({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.linkCodeCtrl,
    required this.isSignup,
    required this.isAdmin,
    required this.isLoading,
    required this.passVisible,
    required this.confirmVisible,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.onSwitchProvider,
    required this.currentProviderId,
  });
}

// ---------------------------------------------------------------------------
// Facebook view
// ---------------------------------------------------------------------------

class _FacebookAuthView extends StatelessWidget {
  static const _bg = Color(0xFF1A2430);
  static const _blue = Color(0xFF1877F2);
  static const _fieldBorder = Color(0xFF3A4F66);
  static const _textSub = Color(0xFF8B9BB4);

  final _AuthViewData data;
  const _FacebookAuthView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'f',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Facebook',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  context.t.text(
                    data.isSignup
                        ? 'Cree su cuenta con Facebook'
                        : 'Acceda con su cuenta de Facebook',
                  ),
                  style: const TextStyle(color: _textSub, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: data.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FbField(
                      controller: data.emailCtrl,
                      hint: context.t.text('Correo electrónico o teléfono'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => _validateEmail(context, v),
                    ),
                    if (data.isSignup && !data.isAdmin) ...[
                      const SizedBox(height: 12),
                      _FbField(
                        controller: data.linkCodeCtrl,
                        hint: context.t.text('Código del administrador'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => _validateLinkCode(context, v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _FbField(
                      controller: data.passCtrl,
                      hint: context.t.password,
                      obscure: !data.passVisible,
                      suffix: IconButton(
                        icon: Icon(
                          data.passVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _textSub,
                          size: 20,
                        ),
                        onPressed: data.onTogglePass,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return context.t.createPassword;
                        }
                        if (v.length < 6) return context.t.minSixChars;
                        return null;
                      },
                    ),
                    if (data.isSignup) ...[
                      const SizedBox(height: 12),
                      _FbField(
                        controller: data.confirmCtrl,
                        hint: context.t.confirmPassword,
                        obscure: !data.confirmVisible,
                        suffix: IconButton(
                          icon: Icon(
                            data.confirmVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _textSub,
                            size: 20,
                          ),
                          onPressed: data.onToggleConfirm,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return context.t.confirmPasswordError;
                          }
                          if (v != data.passCtrl.text) {
                            return context.t.passwordsDontMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: data.isLoading ? null : data.onSubmit,
                        child: data.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.t.text(
                                  data.isSignup ? 'Registrarse' : 'Continuar',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!data.isSignup)
                      Center(
                        child: Text(
                          context.t.text('¿Ha olvidado su contraseña?'),
                          style: const TextStyle(color: _textSub, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider(color: _fieldBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      context.t.or,
                      style: const TextStyle(color: _textSub),
                    ),
                  ),
                  const Expanded(child: Divider(color: _fieldBorder)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: data.onSwitchMode,
                  child: Text(
                    context.t.text(
                      data.isSignup
                          ? '¿Ya tiene cuenta? Inicie sesión'
                          : '¿No tiene cuenta? Regístrese',
                    ),
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ProviderSwitcher(
                onSwitchProvider: data.onSwitchProvider,
                currentProviderId: data.currentProviderId,
                dark: true,
              ),
              const SizedBox(height: 20),
              const _PrivacyNote(dark: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.all_inclusive_rounded, color: _textSub, size: 14),
                  SizedBox(width: 6),
                  Text('Meta', style: TextStyle(color: _textSub, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FbField extends StatelessWidget {
  static const _fieldFill = Color(0xFF22303C);
  static const _fieldBorder = Color(0xFF3A4F66);
  static const _textSub = Color(0xFF8B9BB4);

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _FbField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSub, fontSize: 15),
        filled: true,
        fillColor: _fieldFill,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Apple view
// ---------------------------------------------------------------------------

class _AppleAuthView extends StatelessWidget {
  static const _blue = Color(0xFF007AFF);
  static const _surfaceBorder = Color(0xFFE4E6EB);
  static const _textPrimary = Color(0xFF1C1C1E);
  static const _textSub = Color(0xFF6C6C70);
  static const _maxContentWidth = 520.0;

  final _AuthViewData data;
  const _AppleAuthView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA), Color(0xFFEFF1F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SurfaceBackButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconColor: _textPrimary,
                        borderColor: _surfaceBorder,
                        backgroundColor: Colors.white.withValues(alpha: 0.94),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: _surfaceBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: AppleLogoMark(
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Center(
                            child: Text(
                              'Aviso Vital',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              context.t.text(
                                data.isSignup
                                    ? 'Cree su cuenta con Apple'
                                    : 'Continúe con su Apple ID',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textSub,
                                fontSize: 16,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F8),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _surfaceBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: _textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.t.text('Acceso seguro con Apple'),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Form(
                            key: data.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AppleField(
                                  controller: data.emailCtrl,
                                  label: 'Apple ID',
                                  hint: 'nombre@icloud.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => _validateEmail(context, v),
                                ),
                                if (data.isSignup && !data.isAdmin) ...[
                                  const SizedBox(height: 14),
                                  _AppleField(
                                    controller: data.linkCodeCtrl,
                                    label: context.t.text(
                                      'Código del administrador',
                                    ),
                                    hint: 'XXXXXX',
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    validator: (v) =>
                                        _validateLinkCode(context, v),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _AppleField(
                                  controller: data.passCtrl,
                                  label: context.t.password,
                                  hint: '',
                                  obscure: !data.passVisible,
                                  suffix: GestureDetector(
                                    onTap: data.onTogglePass,
                                    child: Text(
                                      context.t.text(
                                        data.passVisible
                                            ? 'Ocultar'
                                            : 'Mostrar',
                                      ),
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return context.t.createPassword;
                                    }
                                    if (v.length < 6) {
                                      return context.t.minSixChars;
                                    }
                                    return null;
                                  },
                                ),
                                if (data.isSignup) ...[
                                  const SizedBox(height: 14),
                                  _AppleField(
                                    controller: data.confirmCtrl,
                                    label: context.t.confirmPassword,
                                    hint: '',
                                    obscure: !data.confirmVisible,
                                    suffix: GestureDetector(
                                      onTap: data.onToggleConfirm,
                                      child: Text(
                                        data.confirmVisible
                                            ? context.t.text('Ocultar')
                                            : context.t.text('Mostrar'),
                                        style: const TextStyle(
                                          color: _blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return context.t.confirmPasswordError;
                                      }
                                      if (v != data.passCtrl.text) {
                                        return context.t.passwordsDontMatch;
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 26),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: data.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const AppleLogoMark(
                                            size: 22,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      data.isSignup
                                          ? context.t.text('Crear cuenta')
                                          : context.t.text('Iniciar sesión'),
                                    ),
                                    onPressed: data.isLoading
                                        ? null
                                        : data.onSubmit,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: GestureDetector(
                                    onTap: data.onSwitchMode,
                                    child: Text(
                                      data.isSignup
                                          ? context.t.text(
                                              '¿Ya tiene cuenta? Inicie sesión',
                                            )
                                          : context.t.text(
                                              '¿No tiene cuenta? Regístrese',
                                            ),
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ProviderSwitcher(
                      onSwitchProvider: data.onSwitchProvider,
                      currentProviderId: data.currentProviderId,
                      dark: false,
                    ),
                    const SizedBox(height: 18),
                    const _PrivacyNote(dark: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleField extends StatelessWidget {
  static const _textPrimary = Color(0xFF1C1C1E);
  static const _textSub = Color(0xFF6C6C70);
  static const _blue = Color(0xFF007AFF);
  static const _divider = Color(0xFFD1D1D6);

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AppleField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      cursorColor: _blue,
      style: const TextStyle(color: _textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(color: _textSub),
        labelStyle: const TextStyle(color: _textSub),
        floatingLabelStyle: const TextStyle(color: _blue, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF3B30)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google view
// ---------------------------------------------------------------------------

class _GoogleAuthView extends StatelessWidget {
  static const _blue = Color(0xFF4285F4);
  static const _surfaceBorder = Color(0xFFE2E7F0);
  static const _textPrimary = Color(0xFF202124);
  static const _textSub = Color(0xFF5F6368);
  static const _maxContentWidth = 520.0;

  final _AuthViewData data;
  const _GoogleAuthView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFD), Color(0xFFEEF3FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SurfaceBackButton(
                        icon: Icons.arrow_back_rounded,
                        iconColor: _textPrimary,
                        borderColor: _surfaceBorder,
                        backgroundColor: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactHeader = constraints.maxWidth < 420;
                          final stackedActions = constraints.maxWidth < 420;
                          final title = data.isSignup
                              ? context.t.text('Crear cuenta')
                              : context.t.text('Iniciar sesión');
                          final subtitle = data.isSignup
                              ? context.t.text(
                                  'con Google para sincronizar su cuenta de Aviso Vital',
                                )
                              : context.t.text(
                                  'con Google para seguir con sus recordatorios',
                                );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (compactHeader)
                                Column(
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _surfaceBorder,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _blue.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: GoogleLogoMark(size: 38),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _textSub,
                                        fontSize: 15,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _surfaceBorder,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _blue.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: GoogleLogoMark(size: 34),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            subtitle,
                                            style: const TextStyle(
                                              color: _textSub,
                                              fontSize: 15,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F9FF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFDCE8FF),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: _blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        context.t.text(
                                          'Acceso seguro y sincronización de medicación, citas y alertas.',
                                        ),
                                        style: const TextStyle(
                                          color: _textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 26),
                              Form(
                                key: data.formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _GoogleField(
                                      controller: data.emailCtrl,
                                      label: context.t.text(
                                        'Correo electrónico o teléfono',
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) =>
                                          _validateEmail(context, v),
                                    ),
                                    if (data.isSignup && !data.isAdmin) ...[
                                      const SizedBox(height: 16),
                                      _GoogleField(
                                        controller: data.linkCodeCtrl,
                                        label: context.t.text(
                                          'Código del administrador',
                                        ),
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        validator: (v) =>
                                            _validateLinkCode(context, v),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _GoogleField(
                                      controller: data.passCtrl,
                                      label: context.t.password,
                                      obscure: !data.passVisible,
                                      suffix: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: data.onTogglePass,
                                        child: Text(
                                          data.passVisible
                                              ? context.t.text('Ocultar')
                                              : context.t.text('Mostrar'),
                                          style: const TextStyle(
                                            color: _blue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return context.t.createPassword;
                                        }
                                        if (v.length < 6) {
                                          return context.t.minSixChars;
                                        }
                                        return null;
                                      },
                                    ),
                                    if (data.isSignup) ...[
                                      const SizedBox(height: 16),
                                      _GoogleField(
                                        controller: data.confirmCtrl,
                                        label: context.t.confirmPassword,
                                        obscure: !data.confirmVisible,
                                        suffix: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: data.onToggleConfirm,
                                          child: Text(
                                            data.confirmVisible
                                                ? context.t.text('Ocultar')
                                                : context.t.text('Mostrar'),
                                            style: const TextStyle(
                                              color: _blue,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return context
                                                .t
                                                .confirmPasswordError;
                                          }
                                          if (v != data.passCtrl.text) {
                                            return context.t.passwordsDontMatch;
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 26),
                                    if (stackedActions) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _blue,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: data.isLoading
                                              ? null
                                              : data.onSubmit,
                                          child: data.isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Text(
                                                  data.isSignup
                                                      ? context.t.text(
                                                          'Registrarse',
                                                        )
                                                      : context.t.text(
                                                          'Siguiente',
                                                        ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Center(
                                        child: TextButton(
                                          onPressed: data.onSwitchMode,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            data.isSignup
                                                ? context.t.text(
                                                    'Iniciar sesión',
                                                  )
                                                : context.t.text(
                                                    'Crear cuenta',
                                                  ),
                                            style: const TextStyle(
                                              color: _blue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: data.onSwitchMode,
                                                style: TextButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10,
                                                      ),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: Text(
                                                  data.isSignup
                                                      ? context.t.text(
                                                          'Iniciar sesión',
                                                        )
                                                      : context.t.text(
                                                          'Crear cuenta',
                                                        ),
                                                  style: const TextStyle(
                                                    color: _blue,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _blue,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(0, 48),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 26,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                elevation: 0,
                                              ),
                                              onPressed: data.isLoading
                                                  ? null
                                                  : data.onSubmit,
                                              child: data.isLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : Text(
                                                      context.t.text(
                                                        data.isSignup
                                                            ? 'Registrarse'
                                                            : 'Siguiente',
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProviderSwitcher(
                      onSwitchProvider: data.onSwitchProvider,
                      currentProviderId: data.currentProviderId,
                      dark: false,
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: _PrivacyNote(dark: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleField extends StatelessWidget {
  static const _blue = Color(0xFF4285F4);
  static const _textPrimary = Color(0xFF202124);
  static const _textSub = Color(0xFF5F6368);

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _GoogleField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      cursorColor: _blue,
      style: const TextStyle(color: _textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSub, fontSize: 16),
        floatingLabelStyle: const TextStyle(color: _blue, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD93025)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.8),
        ),
        errorStyle: const TextStyle(color: Color(0xFFD93025), fontSize: 12),
      ),
    );
  }
}

class _SurfaceBackButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const _SurfaceBackButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: provider switcher
// ---------------------------------------------------------------------------

class _ProviderSwitcher extends StatelessWidget {
  final ValueChanged<AuthSocialProvider> onSwitchProvider;
  final String currentProviderId;
  final bool dark;

  const _ProviderSwitcher({
    required this.onSwitchProvider,
    required this.currentProviderId,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? const Color(0xFF8B9BB4) : const Color(0xFF9AA0A6);
    final providers = AuthSocialRow.providers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            context.t.text('Cambiar de proveedor'),
            style: TextStyle(color: labelColor, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: providers.map((provider) {
              final isCurrent = provider.id == currentProviderId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: isCurrent ? null : () => onSwitchProvider(provider),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? provider.background.withValues(alpha: 0.5)
                          : provider.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? provider.border.withValues(alpha: 0.8)
                            : provider.border,
                        width: isCurrent ? 2.0 : 1.0,
                      ),
                    ),
                    child: provider.buildLogo(
                      size: 24,
                      muted: isCurrent,
                      onDark: provider.id == 'facebook',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: privacy note
// ---------------------------------------------------------------------------

class _PrivacyNote extends StatelessWidget {
  final bool dark;
  const _PrivacyNote({this.dark = true});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.t.text(
        'Al continuar aceptas los términos de uso y la política de privacidad de Aviso Vital.',
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: dark ? const Color(0xFF8B9BB4) : const Color(0xFF9AA0A6),
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
