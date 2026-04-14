import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthSocialProvider {
  final String id;
  final IconData icon;
  final String label;

  const AuthSocialProvider({
    required this.id,
    required this.icon,
    required this.label,
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
    ),
    AuthSocialProvider(id: 'apple', icon: Icons.apple_rounded, label: 'Apple'),
    AuthSocialProvider(
      id: 'facebook',
      icon: Icons.facebook_rounded,
      label: 'Facebook',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: providers
          .map(
            (provider) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Semantics(
                button: true,
                label: 'Continuar con ${provider.label}',
                child: InkWell(
                  onTap: onProviderTap == null
                      ? null
                      : () => onProviderTap!(provider),
                  borderRadius: AppRadius.iconLg,
                  child: Ink(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.iconLg,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Icon(
                      provider.icon,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
