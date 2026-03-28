import 'package:flutter/material.dart';

import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class RoleSelectionIntro extends StatelessWidget {
  const RoleSelectionIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Elige cómo quieres acceder a Aviso Vital.',
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    );
  }
}
