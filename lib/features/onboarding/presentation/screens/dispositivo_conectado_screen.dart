import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'package:aviso_vital_2/features/user_home/presentation/screens/home_usuario_screen.dart';

/// Pantalla: Dispositivo conectado — estado de éxito del onboarding
class DispositivoConectadoScreen extends StatefulWidget {
  static const String routeName = AppRoutes.dispositivoConectado;
  const DispositivoConectadoScreen({super.key});

  @override
  State<DispositivoConectadoScreen> createState() =>
      _DispositivoConectadoScreenState();
}

class _DispositivoConectadoScreenState extends State<DispositivoConectadoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: PremiumScreenScaffold(
        variant: PremiumBackgroundVariant.focus,
        primaryGlowColor: AppColors.success,
        secondaryGlowColor: AppColors.amber,
        primaryGlowAlignment: const Alignment(0, -0.52),
        secondaryGlowAlignment: const Alignment(0.86, 0.82),
        intensity: 0.98,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              children: [
                SizedBox(height: screenH * 0.12),

                // ── Check animado ──
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.successSubtle,
                      border: Border.all(
                        color: AppColors.successBorder,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                ),

                SizedBox(height: screenH * 0.04),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        context.t.text('Dispositivo conectado'),
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.t.text(
                          'Su cuidador ya puede ayudarle a gestionar medicamentos y citas médicas',
                        ),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenH * 0.05),

                      // ── Qué pasa ahora ──
                      _WhatNextCard(),
                    ],
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: context.t.text('Continuar'),
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          HomeUsuarioScreen.routeName,
                          (_) => false,
                        ),
                      ),
                      SizedBox(height: screenH * 0.04),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatNextCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceOverlay, AppColors.surfaceRaised],
        ),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.text('¿Qué ocurrirá ahora?'),
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _NextItem(
            icon: Icons.notifications_active_rounded,
            color: AppColors.amber,
            text: context.t.text(
              'Recibirá avisos cuando sea la hora de tomar su medicación',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _NextItem(
            icon: Icons.event_rounded,
            color: AppColors.orange,
            text: context.t.text(
              'Le recordaremos sus citas médicas con antelación',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _NextItem(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            text: context.t.text(
              'Solo tendrá que pulsar un botón para confirmar',
            ),
          ),
        ],
      ),
    );
  }
}

class _NextItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _NextItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.icon,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
