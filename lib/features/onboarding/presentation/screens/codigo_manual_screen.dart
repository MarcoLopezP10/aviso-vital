import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/app_link_service.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'dispositivo_conectado_screen.dart';

/// Pantalla: Código manual de vinculación
/// Alternativa real al QR cuando la cámara no funciona o el usuario mayor tiene dificultades
class CodigoManualScreen extends StatefulWidget {
  static const String routeName = AppRoutes.codigoManual;
  const CodigoManualScreen({super.key});

  @override
  State<CodigoManualScreen> createState() => _CodigoManualScreenState();
}

class _CodigoManualScreenState extends State<CodigoManualScreen> {
  static const _userRepository = UserRepository();
  static const _appLinkService = AppLinkService();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _errorCodigo = false;

  String get _codigoCompleto =>
      _controllers.map((c) => c.text.toUpperCase()).join();
  String get _codigoNormalizado =>
      _codigoCompleto.replaceAll('-', '').trim().toUpperCase();

  bool get _codigoLleno => _codigoCompleto.length == 6;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verificar() async {
    if (!_codigoLleno) return;
    setState(() {
      _isLoading = true;
      _errorCodigo = false;
    });

    try {
      final linkedUser = SupabaseService.currentUser == null
          ? await _userRepository.linkMayorByCode(_codigoNormalizado)
          : await _userRepository.linkCurrentMayorToAdminByCode(
              _codigoNormalizado,
            );
      if (!mounted) return;

      if (linkedUser != null) {
        final adminId = linkedUser.idAdministrador ?? linkedUser.id;
        if (!mounted || adminId.isEmpty) {
          throw StateError('No se pudo resolver el administrador vinculado.');
        }
        await _appLinkService.saveLink(
          adminCode: _codigoNormalizado,
          adminId: adminId,
          userId: linkedUser.id,
          displayName: linkedUser.nombre,
        );
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          DispositivoConectadoScreen.routeName,
        );
        return;
      }

      setState(() => _isLoading = false);
      _resetCodeWithError();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      setState(() => _errorCodigo = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'No se pudo verificar el código: $error',
          ),
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {
      _errorCodigo = false;
    });
    if (_codigoLleno) _verificar();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text
        ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (value == null || value.isEmpty) return;

    final chars = value.split('').take(6).toList(growable: false);
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }
    setState(() => _errorCodigo = false);
    if (_codigoLleno) {
      await _verificar();
      return;
    }
    final nextIndex = chars.length >= 5 ? 5 : chars.length;
    _focusNodes[nextIndex].requestFocus();
  }

  void _resetCodeWithError() {
    setState(() => _errorCodigo = true);
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenH * 0.025),
              const AppBackButton(),
              SizedBox(height: screenH * 0.04),

              Text(
                'Código manual',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.amber,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Introduzca el código\nde su administrador',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'El administrador puede encontrarlo en la pantalla de inicio',
                style: AppTextStyles.bodySmall,
              ),

              SizedBox(height: screenH * 0.06),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: _errorCodigo
                        ? AppColors.danger
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato del código',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AV-1234',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.amber,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: List.generate(
                          6,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                              right: i == 1 ? AppSpacing.sm : 0,
                            ),
                            child: _CodeInput(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onDigitChanged(i, v),
                              hasError: _errorCodigo,
                              isFirst: i == 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('Pegar código'),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorCodigo) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Código incorrecto o no disponible. Inténtelo de nuevo.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              PrimaryButton(
                label: 'Verificar código',
                isLoading: _isLoading,
                onPressed: _codigoLleno ? _verificar : null,
              ),

              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'Introduzca el código real de vinculación del perfil en Supabase',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenH * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool isFirst;

  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 64,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        autofocus: isFirst,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        ],
        onChanged: onChanged,
        style: AppTextStyles.h2.copyWith(
          letterSpacing: 0,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceFloating,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.surfaceBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.surfaceBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: const BorderSide(color: AppColors.amber, width: 2),
          ),
        ),
      ),
    );
  }
}
