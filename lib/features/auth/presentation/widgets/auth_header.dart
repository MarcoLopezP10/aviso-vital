import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final Color eyebrowColor;

  const AuthHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.eyebrowColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.overline.copyWith(
            color: eyebrowColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: AppTextStyles.h1),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description!,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
