import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocaleController.instance.language,
      builder: (context, language, _) {
        return Semantics(
          button: true,
          label: strings.languageTooltip,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  size: 28,
                ),
                const SizedBox(width: 14),
                _LanguageButton(
                  label: 'ES',
                  selected: language == AppLanguage.es,
                  onTap: () =>
                      AppLocaleController.instance.setLanguage(AppLanguage.es),
                ),
                Container(
                  width: 2,
                  height: 25,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                _LanguageButton(
                  label: 'EN',
                  selected: language == AppLanguage.en,
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
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: selected
                ? AppColors.amber
                : Colors.white.withValues(alpha: 0.34),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
