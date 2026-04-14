import 'package:flutter/material.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_hero_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_social_row.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class SocialAuthScreen extends StatefulWidget {
  final String providerId;
  final String roleId;

  const SocialAuthScreen({
    super.key,
    required this.providerId,
    required this.roleId,
  });

  @override
  State<SocialAuthScreen> createState() => _SocialAuthScreenState();
}

class _SocialAuthScreenState extends State<SocialAuthScreen> {
  bool _isLoading = false;

  _ProviderUi get _provider {
    return switch (widget.providerId) {
      'apple' => const _ProviderUi(
        id: 'apple',
        label: 'Apple',
        icon: Icons.apple_rounded,
        accent: Color(0xFFE8EEF8),
        glow: Color(0xFF92A8D1),
      ),
      'facebook' => const _ProviderUi(
        id: 'facebook',
        label: 'Facebook',
        icon: Icons.facebook_rounded,
        accent: Color(0xFF7CB5FF),
        glow: Color(0xFF2D6CDF),
      ),
      _ => const _ProviderUi(
        id: 'google',
        label: 'Google',
        icon: Icons.g_mobiledata_rounded,
        accent: Color(0xFFFFD166),
        glow: AppColors.amber,
      ),
    };
  }

  bool get _isAdmin => widget.roleId == 'admin';

  String get _roleLabel => _isAdmin ? 'administrador' : 'usuario';

  Future<void> _simulateAccess() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pantalla de ${_provider.label} preparada como simulación visual para acceso de $_roleLabel.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      variant: _isAdmin
          ? PremiumBackgroundVariant.dashboard
          : PremiumBackgroundVariant.warm,
      primaryGlowColor: _provider.glow,
      secondaryGlowColor: _isAdmin ? AppColors.orange : AppColors.amber,
      primaryGlowAlignment: const Alignment(0.2, -0.62),
      secondaryGlowAlignment: const Alignment(0.92, 0.84),
      intensity: 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const AppBackButton(),
          const SizedBox(height: AppSpacing.xl),
          AuthHeroCard(
            eyebrow: 'Acceso con ${_provider.label}',
            eyebrowColor: _provider.accent,
            title: 'Continúa con\n${_provider.label}',
            description:
                'Hemos preparado una pantalla intermedia para que el acceso social se sienta más real y claro antes de conectar la integración definitiva.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _provider.accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _provider.accent.withValues(alpha: 0.42),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _provider.glow.withValues(alpha: 0.18),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _provider.icon,
                      size: _provider.id == 'google' ? 58 : 42,
                      color: _provider.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Simulación de proveedor', style: AppTextStyles.h4),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Esta pantalla representa el paso externo de $_roleLabel con ${_provider.label}. Más adelante podremos conectar el flujo real sin cambiar esta experiencia visual.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _InfoChip(
                  icon: Icons.verified_user_outlined,
                  text: 'Proveedor: ${_provider.label}',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  text: 'Acceso preparado para $_roleLabel',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.motion_photos_auto_rounded,
                  text: 'Modo visual tipo simulación',
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Simular acceso con ${_provider.label}',
                  backgroundColor: _provider.glow,
                  foregroundColor: AppColors.textPrimary,
                  isLoading: _isLoading,
                  onPressed: _simulateAccess,
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Volver al inicio de sesión',
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'También puedes cambiar de proveedor aquí',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AuthSocialRow(
              onProviderTap: (provider) {
                if (provider.id == _provider.id) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SocialAuthScreen(
                      providerId: provider.id,
                      roleId: widget.roleId,
                    ),
                  ),
                );
              },
            ),
          ),
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

  const _ProviderUi({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.glow,
  });
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
