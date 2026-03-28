import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool usePremiumBackground;
  final PremiumBackgroundVariant variant;
  final Color primaryGlowColor;
  final Color secondaryGlowColor;
  final Alignment primaryGlowAlignment;
  final Alignment secondaryGlowAlignment;
  final double intensity;

  const AuthScaffold({
    super.key,
    required this.child,
    this.usePremiumBackground = true,
    this.variant = PremiumBackgroundVariant.warm,
    this.primaryGlowColor = AppColors.orange,
    this.secondaryGlowColor = AppColors.amber,
    this.primaryGlowAlignment = const Alignment(0.28, -0.56),
    this.secondaryGlowAlignment = const Alignment(0.96, 0.74),
    this.intensity = 0.78,
  });

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 780;
        final horizontalPadding = isCompactHeight
            ? AppSpacing.lg
            : AppSpacing.xl;
        final topPadding = isCompactHeight ? AppSpacing.md : AppSpacing.lg;
        final bottomPadding = isCompactHeight ? AppSpacing.xl : AppSpacing.xxl;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );

    if (usePremiumBackground) {
      return PremiumScreenScaffold(
        variant: variant,
        primaryGlowColor: primaryGlowColor,
        secondaryGlowColor: secondaryGlowColor,
        primaryGlowAlignment: primaryGlowAlignment,
        secondaryGlowAlignment: secondaryGlowAlignment,
        intensity: intensity,
        body: body,
      );
    }

    return Scaffold(backgroundColor: AppColors.background, body: body);
  }
}
