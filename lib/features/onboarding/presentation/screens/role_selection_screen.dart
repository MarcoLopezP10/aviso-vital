import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/user_login_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_selection_benefits.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_option_card.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_selection_header.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_selection_intro.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/premium_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const String routeName = AppRoutes.roleSelection;

  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.focus,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.orange,
      primaryGlowAlignment: const Alignment(0, -1.04),
      secondaryGlowAlignment: const Alignment(0.95, 0.84),
      intensity: 0.56,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.xxl),
                            const RoleSelectionHeader(),
                            const SizedBox(height: AppSpacing.xl),
                            const RoleSelectionIntro(),
                            const SizedBox(height: AppSpacing.md),
                            const RoleSelectionBenefits(),
                            const Spacer(),
                            Text(
                              'Seleccione su perfil',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RoleOptionCard(
                              title: 'Soy usuario',
                              subtitle: 'Recibo recordatorios y avisos',
                              icon: Icons.favorite_outline_rounded,
                              accentColor: AppColors.amber,
                              accentForeground: AppColors.amberLight,
                              onTap: () => Navigator.pushNamed(
                                context,
                                UserLoginScreen.routeName,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            RoleOptionCard(
                              title: 'Soy administrador',
                              subtitle: 'Gestiono medicación y citas',
                              icon: Icons.admin_panel_settings_outlined,
                              accentColor: AppColors.orange,
                              accentForeground: AppColors.orangeLight,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AdminLoginScreen.routeName,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
