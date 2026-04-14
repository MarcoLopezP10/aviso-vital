import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthSocialProvider {
  final String id;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const AuthSocialProvider({
    required this.id,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });
}

class AuthSocialRow extends StatelessWidget {
  final ValueChanged<AuthSocialProvider>? onProviderTap;

  const AuthSocialRow({super.key, this.onProviderTap});

  static const providers = [
    AuthSocialProvider(
      id: 'google',
      icon: Icons.g_mobiledata_rounded,
      label: 'Google',
      background: Color(0xFFF7F1D1),
      foreground: Color(0xFFE7B824),
      border: Color(0x66E7B824),
    ),
    AuthSocialProvider(
      id: 'apple',
      icon: Icons.apple_rounded,
      label: 'Apple',
      background: Color(0xFFE9EEF7),
      foreground: Color(0xFFC8D7F1),
      border: Color(0x66C8D7F1),
    ),
    AuthSocialProvider(
      id: 'facebook',
      icon: Icons.facebook_rounded,
      label: 'Facebook',
      background: Color(0xFF1E3A6D),
      foreground: Color(0xFF7CB5FF),
      border: Color(0x667CB5FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorderSoft),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: providers
            .map(
              (provider) => Semantics(
                button: true,
                label: 'Continuar con ${provider.label}',
                child: InkWell(
                  onTap: onProviderTap == null
                      ? null
                      : () => onProviderTap!(provider),
                  borderRadius: AppRadius.card,
                  child: Ink(
                    width: 96,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: provider.background,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: provider.border),
                      boxShadow: [
                        BoxShadow(
                          color: provider.foreground.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.icon,
                          color: provider.foreground,
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.label,
                          style: AppTextStyles.label.copyWith(
                            color: provider.id == 'facebook'
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
