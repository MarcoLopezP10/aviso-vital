import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminSectionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? stats;
  final Widget? filters;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? headerTrailing;
  final bool compactHeader;
  final Color primaryGlowColor;
  final Color secondaryGlowColor;
  final Alignment primaryGlowAlignment;
  final Alignment secondaryGlowAlignment;
  final double intensity;

  const AdminSectionScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.onBack,
    this.stats,
    this.filters,
    this.floatingActionButton,
    this.headerTrailing,
    this.compactHeader = false,
    this.primaryGlowColor = AppColors.amber,
    this.secondaryGlowColor = AppColors.haloSoft,
    this.primaryGlowAlignment = const Alignment(1, -0.95),
    this.secondaryGlowAlignment = const Alignment(-0.95, 0.1),
    this.intensity = 0.68,
  });

  @override
  Widget build(BuildContext context) {
    final headerPadding = compactHeader ? AppSpacing.lg : AppSpacing.xl;
    final titleStyle = compactHeader
        ? AppTextStyles.h3.copyWith(fontSize: 24)
        : AppTextStyles.h2;

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.dashboard,
      primaryGlowColor: primaryGlowColor,
      secondaryGlowColor: secondaryGlowColor,
      primaryGlowAlignment: primaryGlowAlignment,
      secondaryGlowAlignment: secondaryGlowAlignment,
      intensity: intensity,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(headerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onBack != null) ...[
                        AppBackButton(onPressed: onBack),
                        SizedBox(width: compactHeader ? 10 : 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t.text(title), style: titleStyle),
                            const SizedBox(height: 2),
                            Text(
                              context.t.text(subtitle),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (headerTrailing != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        headerTrailing!,
                      ],
                    ],
                  ),
                  if (stats != null) ...[
                    SizedBox(
                      height: compactHeader ? AppSpacing.lg : AppSpacing.xl,
                    ),
                    stats!,
                  ],
                  if (filters != null) ...[
                    SizedBox(
                      height: compactHeader ? AppSpacing.lg : AppSpacing.xl,
                    ),
                    filters!,
                  ],
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: floatingActionButton,
    );
  }
}
