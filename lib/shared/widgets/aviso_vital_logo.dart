import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.32),
                  blurRadius: 24,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          'assets/images/aviso_vital_logo.svg',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      ),
    );

    return ScaleTransition(scale: _scale, child: logo);
  }
}

