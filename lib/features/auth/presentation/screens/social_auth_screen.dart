import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';

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
      arguments: {
        'providerId': _providerId,
        'roleId': widget.roleId,
        'modeId': _isSignup ? 'login' : 'signup',
      },
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
                  data.isSignup
                      ? 'Crea tu cuenta con Facebook'
                      : 'Accede con tu cuenta de Facebook',
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
                      hint: 'Correo electrónico o teléfono',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Introduce tu email';
                        }
                        if (!v.contains('@')) return 'Email no válido';
                        return null;
                      },
                    ),
                    if (data.isSignup && !data.isAdmin) ...[
                      const SizedBox(height: 12),
                      _FbField(
                        controller: data.linkCodeCtrl,
                        hint: 'Código del administrador',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          final n = v
                              ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                              .trim();
                          if (n == null || n.isEmpty) {
                            return 'Introduce el código';
                          }
                          if (n.length != 6) {
                            return 'El código debe tener 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    _FbField(
                      controller: data.passCtrl,
                      hint: 'Contraseña',
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
                          return 'Introduce una contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    if (data.isSignup) ...[
                      const SizedBox(height: 12),
                      _FbField(
                        controller: data.confirmCtrl,
                        hint: 'Confirmar contraseña',
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
                            return 'Confirma la contraseña';
                          }
                          if (v != data.passCtrl.text) {
                            return 'Las contraseñas no coinciden';
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
                                data.isSignup ? 'Registrarse' : 'Continuar',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!data.isSignup)
                      const Center(
                        child: Text(
                          '¿Has olvidado tu contraseña?',
                          style: TextStyle(color: _textSub, fontSize: 14),
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
                      'o',
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
                    data.isSignup
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate',
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
                  Text(
                    'Meta',
                    style: TextStyle(color: _textSub, fontSize: 12),
                  ),
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
  static const _textPrimary = Color(0xFF1C1C1E);
  static const _textSub = Color(0xFF6C6C70);

  final _AuthViewData data;
  const _AppleAuthView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _blue,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3C5E),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Aviso Vital',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  data.isSignup
                      ? 'Crea tu cuenta con Apple'
                      : 'Continúa con tu Apple ID',
                  style: const TextStyle(color: _textSub, fontSize: 15),
                ),
              ),
              const SizedBox(height: 36),
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Introduce tu email';
                        }
                        if (!v.contains('@')) return 'Email no válido';
                        return null;
                      },
                    ),
                    if (data.isSignup && !data.isAdmin) ...[
                      const SizedBox(height: 4),
                      _AppleField(
                        controller: data.linkCodeCtrl,
                        label: 'Código del administrador',
                        hint: 'XXXXXX',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          final n = v
                              ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                              .trim();
                          if (n == null || n.isEmpty) {
                            return 'Introduce el código';
                          }
                          if (n.length != 6) {
                            return 'El código debe tener 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                    _AppleField(
                      controller: data.passCtrl,
                      label: 'Contraseña',
                      hint: '',
                      obscure: !data.passVisible,
                      suffix: GestureDetector(
                        onTap: data.onTogglePass,
                        child: Text(
                          data.passVisible ? 'Ocultar' : 'Mostrar',
                          style: const TextStyle(color: _blue, fontSize: 14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Introduce una contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    if (data.isSignup) ...[
                      const SizedBox(height: 4),
                      _AppleField(
                        controller: data.confirmCtrl,
                        label: 'Confirmar contraseña',
                        hint: '',
                        obscure: !data.confirmVisible,
                        suffix: GestureDetector(
                          onTap: data.onToggleConfirm,
                          child: Text(
                            data.confirmVisible ? 'Ocultar' : 'Mostrar',
                            style: const TextStyle(color: _blue, fontSize: 14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma la contraseña';
                          }
                          if (v != data.passCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
                            : const Icon(Icons.apple_rounded, size: 22),
                        label: Text(
                          data.isSignup ? 'Crear cuenta' : 'Iniciar sesión',
                        ),
                        onPressed: data.isLoading ? null : data.onSubmit,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: data.onSwitchMode,
                        child: Text(
                          data.isSignup
                              ? '¿Ya tienes cuenta? Inicia sesión'
                              : '¿No tienes cuenta? Regístrate',
                          style: const TextStyle(color: _blue, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _PrivacyNote(dark: false),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _ProviderSwitcher(
                onSwitchProvider: data.onSwitchProvider,
                currentProviderId: data.currentProviderId,
                dark: false,
              ),
              const SizedBox(height: 28),
            ],
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
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: suffix,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF3B30)),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF3B30), width: 1.5),
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
  static const _bg = Color(0xFFF1F3F4);
  static const _blue = Color(0xFF4285F4);
  static const _textPrimary = Color(0xFF202124);
  static const _textSub = Color(0xFF5F6368);

  final _AuthViewData data;
  const _GoogleAuthView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: _textSub,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: _GoogleLogoWidget()),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          data.isSignup ? 'Crear cuenta' : 'Iniciar sesión',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'con tu cuenta de Google',
                          style: TextStyle(color: _textSub, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: data.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GoogleField(
                              controller: data.emailCtrl,
                              label: 'Correo electrónico o teléfono',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Introduce tu email';
                                }
                                if (!v.contains('@')) return 'Email no válido';
                                return null;
                              },
                            ),
                            if (data.isSignup && !data.isAdmin) ...[
                              const SizedBox(height: 20),
                              _GoogleField(
                                controller: data.linkCodeCtrl,
                                label: 'Código del administrador',
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (v) {
                                  final n = v
                                      ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                                      .trim();
                                  if (n == null || n.isEmpty) {
                                    return 'Introduce el código';
                                  }
                                  if (n.length != 6) {
                                    return 'El código debe tener 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            _GoogleField(
                              controller: data.passCtrl,
                              label: 'Contraseña',
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
                                  data.passVisible ? 'Ocultar' : 'Mostrar',
                                  style: const TextStyle(
                                    color: _blue,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Introduce una contraseña';
                                }
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            if (data.isSignup) ...[
                              const SizedBox(height: 20),
                              _GoogleField(
                                controller: data.confirmCtrl,
                                label: 'Confirmar contraseña',
                                obscure: !data.confirmVisible,
                                suffix: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: data.onToggleConfirm,
                                  child: Text(
                                    data.confirmVisible
                                        ? 'Ocultar'
                                        : 'Mostrar',
                                    style: const TextStyle(
                                      color: _blue,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Confirma la contraseña';
                                  }
                                  if (v != data.passCtrl.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: data.onSwitchMode,
                                  child: Text(
                                    data.isSignup
                                        ? 'Iniciar sesión'
                                        : 'Crear cuenta',
                                    style: const TextStyle(
                                      color: _blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onPressed:
                                        data.isLoading ? null : data.onSubmit,
                                    child: data.isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            data.isSignup
                                                ? 'Registrarse'
                                                : 'Siguiente',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ProviderSwitcher(
                onSwitchProvider: data.onSwitchProvider,
                currentProviderId: data.currentProviderId,
                dark: false,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _PrivacyNote(dark: false),
              ),
              const SizedBox(height: 24),
            ],
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
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffix,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _blue, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD93025)),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD93025), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFD93025), fontSize: 12),
      ),
    );
  }
}

class _GoogleLogoWidget extends StatelessWidget {
  const _GoogleLogoWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEA4335),
              shape: BoxShape.circle,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFBBC05),
              shape: BoxShape.circle,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF34A853),
              shape: BoxShape.circle,
            ),
          ),
        ],
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
    final labelColor = dark
        ? const Color(0xFF8B9BB4)
        : const Color(0xFF9AA0A6);
    final providers = AuthSocialRow.providers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Cambiar de proveedor',
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
                    child: Icon(
                      provider.icon,
                      color: isCurrent
                          ? provider.foreground.withValues(alpha: 0.5)
                          : provider.foreground,
                      size: 24,
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
      'Al continuar aceptas los términos de uso y la política de privacidad de Aviso Vital.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: dark ? const Color(0xFF8B9BB4) : const Color(0xFF9AA0A6),
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
