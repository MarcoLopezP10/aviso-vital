import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class UserHomeHeader extends StatelessWidget {
  final String greeting;
  final String dateLabel;
  final String? avatarInitial;
  final Widget? trailing;

  const UserHomeHeader({
    super.key,
    required this.greeting,
    required this.dateLabel,
    this.avatarInitial,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (avatarInitial != null && avatarInitial!.isNotEmpty) ...[
          _AvatarCircle(initial: avatarInitial!),
          const SizedBox(width: AppSpacing.md),
        ],
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

class _AvatarCircle extends StatelessWidget {
  final String initial;
  const _AvatarCircle({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.h3.copyWith(
            color: AppColors.amber,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
