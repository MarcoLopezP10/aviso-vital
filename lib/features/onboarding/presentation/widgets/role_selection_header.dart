import 'package:flutter/material.dart';

import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/aviso_vital_logo.dart';

class RoleSelectionHeader extends StatelessWidget {
  const RoleSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AvisoVitalLogo(size: 84, animate: true, showGlow: true),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'AVISO VITAL',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
