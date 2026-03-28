import 'package:flutter/material.dart';

import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AvisoVitalLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showGlow;

  const AvisoVitalLogo({
    super.key,
    this.size = 72,
    this.animate = false,
    this.showGlow = true,
  });

  @override
  State<AvisoVitalLogo> createState() => _AvisoVitalLogoState();
}

class _AvisoVitalLogoState extends State<AvisoVitalLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.slower,
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AvisoVitalLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amberLight, AppColors.orange],
        ),
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size * 0.72,
            height: widget.size * 0.72,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            size: widget.size * 0.36,
            color: AppColors.amber,
          ),
          Positioned(
            bottom: widget.size * 0.2,
            child: Container(
              width: widget.size * 0.34,
              height: widget.size * 0.1,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
      ),
    );

    return ScaleTransition(scale: _scale, child: logo);
  }
}
