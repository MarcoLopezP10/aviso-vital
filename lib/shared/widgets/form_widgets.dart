import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool compact;
  final bool secondary;

  const AppFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.compact = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: secondary ? AppColors.textTertiary : AppColors.textSecondary,
            fontSize: compact ? 12 : null,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: maxLines > 1
                  ? (compact ? 14 : 16)
                  : (compact ? 14 : 18),
            ),
          ),
        ),
      ],
    );
  }
}

class AppFormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;

  const AppFormSection({
    super.key,
    required this.title,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: compact ? 0.8 : 1.0,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        child,
      ],
    );
  }
}

class AppPickerButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;

  const AppPickerButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            fontSize: compact ? 12 : null,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: compact ? 50 : 54,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.input,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textTertiary,
                  size: compact ? 17 : 18,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 14 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AppSwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;

  const AppSwitchRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    this.compact = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : null,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 11 : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.orange,
        ),
      ],
    );
  }
}
