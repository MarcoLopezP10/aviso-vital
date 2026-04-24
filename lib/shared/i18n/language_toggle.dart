import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 420;
    final containerHeight = compact ? 52.0 : 60.0;
    final horizontalPadding = compact ? 10.0 : 14.0;
    final iconSize = compact ? 24.0 : 28.0;
    final gap = compact ? 10.0 : 14.0;
    final dividerHeight = compact ? 21.0 : 25.0;
    final buttonVerticalPadding = compact ? 8.0 : 10.0;
    final buttonFontSize = compact ? 19.0 : 22.0;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocaleController.instance.language,
      builder: (context, language, _) {
        return Semantics(
          button: true,
          label: strings.languageTooltip,
          child: Container(
            height: containerHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF121214).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: iconSize,
                ),
                SizedBox(width: gap),
                _LanguageButton(
                  label: 'ES',
                  selected: language == AppLanguage.es,
                  compact: compact,
                  fontSize: buttonFontSize,
                  verticalPadding: buttonVerticalPadding,
                  onTap: () =>
                      AppLocaleController.instance.setLanguage(AppLanguage.es),
                ),
                Container(
                  width: 2,
                  height: dividerHeight,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                _LanguageButton(
                  label: 'EN',
                  selected: language == AppLanguage.en,
                  compact: compact,
                  fontSize: buttonFontSize,
                  verticalPadding: buttonVerticalPadding,
                  onTap: () =>
                      AppLocaleController.instance.setLanguage(AppLanguage.en),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final double fontSize;
  final double verticalPadding;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.fontSize,
    required this.verticalPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(compact ? 6 : 8),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 1 : 2,
          vertical: verticalPadding,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: selected
                ? AppColors.amber
                : Colors.white.withValues(alpha: 0.34),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
