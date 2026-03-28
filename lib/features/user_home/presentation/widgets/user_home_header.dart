import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class UserHomeHeader extends StatelessWidget {
  final String greeting;
  final String dateLabel;
  final Widget? trailing;

  const UserHomeHeader({
    super.key,
    required this.greeting,
    required this.dateLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(dateLabel, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}
