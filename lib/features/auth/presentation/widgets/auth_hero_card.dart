import 'package:flutter/material.dart';

import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:aviso_vital_2/features/auth/presentation/widgets/auth_header.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Color eyebrowColor;

  const AuthHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.eyebrowColor = AppColors.orangeLight,
  });

  @override
  Widget build(BuildContext context) {
    return AuthFormCard(
      child: AuthHeader(
        eyebrow: eyebrow,
        eyebrowColor: eyebrowColor,
        title: title,
        description: description,
      ),
    );
  }
}
