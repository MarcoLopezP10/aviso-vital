import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    final socials = [
      Icons.g_mobiledata_rounded,
      Icons.apple_rounded,
      Icons.facebook_rounded,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socials
          .map(
            (icon) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.iconLg,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 24),
              ),
            ),
          )
          .toList(),
    );
  }
}
