import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthSwitchLink extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.bodySmall,
            children: [
              TextSpan(
                text: prompt,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              TextSpan(
                text: actionLabel,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
