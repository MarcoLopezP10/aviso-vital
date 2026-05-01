import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/user_login_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_option_card.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_selection_header.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/widgets/role_selection_intro.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/i18n/language_toggle.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/premium_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const String routeName = AppRoutes.roleSelection;

  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.focus,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.orange,
      primaryGlowAlignment: const Alignment(0, -1.04),
      secondaryGlowAlignment: const Alignment(0.95, 0.84),
      intensity: 0.56,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                                const SizedBox(height: AppSpacing.lg),
                                const Center(child: RoleSelectionHeader()),
                                const SizedBox(height: AppSpacing.xl),
                                const Center(child: RoleSelectionIntro()),
                                const Spacer(),
                                Text(
                                  strings.selectProfile,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                RoleOptionCard(
                                  title: strings.userRoleTitle,
                                  subtitle: strings.userRoleSubtitle,
                                  icon: Icons.person_outline_rounded,
                                  accentColor: AppColors.amber,
                                  accentForeground: AppColors.amberLight,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    UserLoginScreen.routeName,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                RoleOptionCard(
                                  title: strings.adminRoleTitle,
                                  subtitle: strings.adminRoleSubtitle,
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
            const Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.md,
              child: LanguageToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
