import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'codigo_manual_screen.dart';

/// Pantalla: Conectar con administrador mediante código real
class ConectarConAdminScreen extends StatelessWidget {
  static const String routeName = AppRoutes.conectarAdmin;

  const ConectarConAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.focus,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.orange,
      primaryGlowAlignment: const Alignment(0, -0.58),
      secondaryGlowAlignment: const Alignment(0.9, 0.75),
      intensity: 0.94,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenH * 0.025),
              const AppBackButton(),
              SizedBox(height: screenH * 0.03),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t.text('Modo Usuario'),
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.amber,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t.text('Conéctese con su\nadministrador'),
                        style: AppTextStyles.h1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t.text(
                          'La vinculación real entre administrador y usuario se hace siempre con el código manual de Aviso Vital.',
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                      SizedBox(height: screenH * 0.05),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.surfaceOverlay,
                              AppColors.surfaceRaised,
                            ],
                          ),
                          borderRadius: AppRadius.cardLg,
                          border: Border.all(color: AppColors.amberBorder),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepRow(
                              index: '1',
                              text:
                                  'Pida al administrador su código de vinculación.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _StepRow(
                              index: '2',
                              text:
                                  'Introduzca ese código en la siguiente pantalla.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _StepRow(
                              index: '3',
                              text:
                                  'A partir de ahí verá sus recordatorios en tiempo real.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: context.t.text('Introducir código del administrador'),
                icon: Icons.password_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, CodigoManualScreen.routeName),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  context.t.text(
                    'El acceso por QR queda desactivado para evitar vinculaciones de prueba.',
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
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

class _StepRow extends StatelessWidget {
  final String index;
  final String text;

  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.amberSubtle,
            borderRadius: AppRadius.icon,
          ),
          child: Center(
            child: Text(
              index,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.amber),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            context.t.text(text),
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
