import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum PremiumBackgroundVariant { soft, focus, dashboard, warm, neutral, calm }

class AppBackground extends StatelessWidget {
  final Widget child;
  final PremiumBackgroundVariant variant;
  final Alignment primaryGlowAlignment;
  final Alignment secondaryGlowAlignment;
  final Color? primaryGlowColor;
  final Color? secondaryGlowColor;
  final double intensity;
  final bool showTopSheen;
  final bool showVignette;
  final bool showTexture;

  const AppBackground({
    super.key,
    required this.child,
    this.variant = PremiumBackgroundVariant.calm,
    this.primaryGlowAlignment = const Alignment(0, -0.9),
    this.secondaryGlowAlignment = const Alignment(0.9, 0.8),
    this.primaryGlowColor,
    this.secondaryGlowColor,
    this.intensity = 1,
    this.showTopSheen = true,
    this.showVignette = true,
    this.showTexture = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _BackgroundConfig.forVariant(variant);
    final primaryColor = primaryGlowColor ?? config.primaryGlowColor;
    final secondaryColor = secondaryGlowColor ?? config.secondaryGlowColor;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: config.baseGradient),
      child: Stack(
        children: [
          // Static background layers cached as a separate compositing layer so
          // body content rebuilds never trigger a repaint of the gradients.
          RepaintBoundary(
            child: Stack(
              children: [
                if (showTexture)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.ambientFog.withValues(
                                alpha: 0.05 * config.overlayOpacity,
                              ),
                              Colors.transparent,
                              AppColors.ambientFog.withValues(
                                alpha: 0.02 * config.overlayOpacity,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.ambientSheen.withValues(
                            alpha: 0.04 * config.overlayOpacity * intensity,
                          ),
                          Colors.transparent,
                          AppColors.haloBlue.withValues(
                            alpha: 0.18 * config.overlayOpacity * intensity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _AmbientCloud(
                  alignment: config.cloudAlignment,
                  color: AppColors.ambientFog.withValues(
                    alpha: config.cloudOpacity * intensity,
                  ),
                  width: config.cloudWidth,
                  height: config.cloudHeight,
                ),
                _GlowOrb(
                  alignment: primaryGlowAlignment,
                  color: primaryColor.withValues(
                    alpha: config.primaryGlowOpacity * intensity,
                  ),
                  width: config.primaryGlowWidth,
                  height: config.primaryGlowHeight,
                ),
                _GlowOrb(
                  alignment: secondaryGlowAlignment,
                  color: secondaryColor.withValues(
                    alpha: config.secondaryGlowOpacity * intensity,
                  ),
                  width: config.secondaryGlowWidth,
                  height: config.secondaryGlowHeight,
                ),
                if (showTopSheen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.28, 1],
                            colors: [
                              AppColors.ambientSheen.withValues(
                                alpha: 0.08 * config.overlayOpacity,
                              ),
                              AppColors.atmosphericLine.withValues(
                                alpha: 0.12 * config.overlayOpacity,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showVignette)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: config.vignetteRadius,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              AppColors.vignette.withValues(
                                alpha: config.vignetteOpacity,
                              ),
                            ],
                            stops: const [0, 0.68, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlowBackground extends StatelessWidget {
  final PremiumBackgroundVariant variant;
  final Alignment primaryGlowAlignment;
  final Alignment secondaryGlowAlignment;
  final Color? primaryGlowColor;
  final Color? secondaryGlowColor;
  final double intensity;

  const GlowBackground({
    super.key,
    this.variant = PremiumBackgroundVariant.focus,
    this.primaryGlowAlignment = const Alignment(0, -0.8),
    this.secondaryGlowAlignment = const Alignment(0.85, 0.9),
    this.primaryGlowColor,
    this.secondaryGlowColor,
    this.intensity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      variant: variant,
      primaryGlowAlignment: primaryGlowAlignment,
      secondaryGlowAlignment: secondaryGlowAlignment,
      primaryGlowColor: primaryGlowColor,
      secondaryGlowColor: secondaryGlowColor,
      intensity: intensity,
      child: const SizedBox.expand(),
    );
  }
}

class PremiumScreenScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final PremiumBackgroundVariant variant;
  final Alignment primaryGlowAlignment;
  final Alignment secondaryGlowAlignment;
  final Color? primaryGlowColor;
  final Color? secondaryGlowColor;
  final double intensity;

  const PremiumScreenScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.variant = PremiumBackgroundVariant.calm,
    this.primaryGlowAlignment = const Alignment(0, -0.9),
    this.secondaryGlowAlignment = const Alignment(0.9, 0.8),
    this.primaryGlowColor,
    this.secondaryGlowColor,
    this.intensity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final content = body;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: AppBackground(
        variant: variant,
        primaryGlowAlignment: primaryGlowAlignment,
        secondaryGlowAlignment: secondaryGlowAlignment,
        primaryGlowColor: primaryGlowColor,
        secondaryGlowColor: secondaryGlowColor,
        intensity: intensity,
        child: content,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double width;
  final double height;

  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width),
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: color.a * 0.18),
                Colors.transparent,
              ],
              stops: const [0, 0.28, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundConfig {
  final LinearGradient baseGradient;
  final Color primaryGlowColor;
  final Color secondaryGlowColor;
  final double primaryGlowOpacity;
  final double secondaryGlowOpacity;
  final double primaryGlowWidth;
  final double primaryGlowHeight;
  final double secondaryGlowWidth;
  final double secondaryGlowHeight;
  final Alignment cloudAlignment;
  final double cloudWidth;
  final double cloudHeight;
  final double cloudOpacity;
  final double vignetteOpacity;
  final double vignetteRadius;
  final double overlayOpacity;

  const _BackgroundConfig({
    required this.baseGradient,
    required this.primaryGlowColor,
    required this.secondaryGlowColor,
    required this.primaryGlowOpacity,
    required this.secondaryGlowOpacity,
    required this.primaryGlowWidth,
    required this.primaryGlowHeight,
    required this.secondaryGlowWidth,
    required this.secondaryGlowHeight,
    required this.cloudAlignment,
    required this.cloudWidth,
    required this.cloudHeight,
    required this.cloudOpacity,
    required this.vignetteOpacity,
    required this.vignetteRadius,
    required this.overlayOpacity,
  });

  factory _BackgroundConfig.forVariant(PremiumBackgroundVariant variant) {
    return switch (variant) {
      PremiumBackgroundVariant.soft ||
      PremiumBackgroundVariant.calm => const _BackgroundConfig(
        baseGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCharcoal,
            AppColors.backgroundCalm,
            AppColors.backgroundInk,
            AppColors.backgroundDeep,
          ],
        ),
        primaryGlowColor: AppColors.haloGold,
        secondaryGlowColor: AppColors.haloBlue,
        primaryGlowOpacity: 0.24,
        secondaryGlowOpacity: 0.12,
        primaryGlowWidth: 520,
        primaryGlowHeight: 440,
        secondaryGlowWidth: 420,
        secondaryGlowHeight: 360,
        cloudAlignment: Alignment(-0.12, -0.42),
        cloudWidth: 920,
        cloudHeight: 520,
        cloudOpacity: 0.1,
        vignetteOpacity: 0.42,
        vignetteRadius: 1.24,
        overlayOpacity: 0.52,
      ),
      PremiumBackgroundVariant.focus ||
      PremiumBackgroundVariant.warm => const _BackgroundConfig(
        baseGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundWarm,
            AppColors.backgroundCharcoal,
            AppColors.backgroundInk,
            AppColors.backgroundDeep,
          ],
        ),
        primaryGlowColor: AppColors.haloGold,
        secondaryGlowColor: AppColors.haloOrange,
        primaryGlowOpacity: 0.3,
        secondaryGlowOpacity: 0.14,
        primaryGlowWidth: 620,
        primaryGlowHeight: 500,
        secondaryGlowWidth: 440,
        secondaryGlowHeight: 380,
        cloudAlignment: Alignment(0.04, -0.54),
        cloudWidth: 980,
        cloudHeight: 560,
        cloudOpacity: 0.1,
        vignetteOpacity: 0.48,
        vignetteRadius: 1.2,
        overlayOpacity: 0.58,
      ),
      PremiumBackgroundVariant.dashboard ||
      PremiumBackgroundVariant.neutral => const _BackgroundConfig(
        baseGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundNeutral,
            AppColors.backgroundCharcoal,
            AppColors.backgroundCanvas,
            AppColors.backgroundDeep,
          ],
        ),
        primaryGlowColor: AppColors.haloGold,
        secondaryGlowColor: AppColors.haloBlue,
        primaryGlowOpacity: 0.1,
        secondaryGlowOpacity: 0.08,
        primaryGlowWidth: 440,
        primaryGlowHeight: 320,
        secondaryGlowWidth: 360,
        secondaryGlowHeight: 280,
        cloudAlignment: Alignment(0.18, -0.9),
        cloudWidth: 1040,
        cloudHeight: 360,
        cloudOpacity: 0.08,
        vignetteOpacity: 0.44,
        vignetteRadius: 1.14,
        overlayOpacity: 0.46,
      ),
    };
  }
}

class _AmbientCloud extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double width;
  final double height;

  const _AmbientCloud({
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width),
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: color.a * 0.28),
                Colors.transparent,
              ],
              stops: const [0, 0.34, 1],
            ),
          ),
        ),
      ),
    );
  }
}
