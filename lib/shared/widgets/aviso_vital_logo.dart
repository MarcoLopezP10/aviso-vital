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

class AvisoVitalAppIcon extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AvisoVitalAppIcon({
    super.key,
    required this.size,
    this.borderRadius = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SvgPicture.asset(
        'assets/images/aviso_vital_logo.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class AvisoVitalGlyph extends StatelessWidget {
  final double size;
  final Color bellColor;
  final Color heartColor;
  final bool showHeart;

  const AvisoVitalGlyph({
    super.key,
    required this.size,
    this.bellColor = const Color(0xCC000000),
    this.heartColor = Colors.white,
    this.showHeart = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AvisoVitalGlyphPainter(
          bellColor: bellColor,
          heartColor: heartColor,
          showHeart: showHeart,
        ),
      ),
    );
  }
}

class _AvisoVitalGlyphPainter extends CustomPainter {
  final Color bellColor;
  final Color heartColor;
  final bool showHeart;

  const _AvisoVitalGlyphPainter({
    required this.bellColor,
    required this.heartColor,
    required this.showHeart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 200;
    final dx = (size.width - size.shortestSide) / 2;
    final dy = (size.height - size.shortestSide) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final bellPath = Path()
      ..moveTo(48, 91)
      ..lineTo(48, 74)
      ..quadraticBezierTo(48, 34, 83, 28)
      ..quadraticBezierTo(83, 17, 100, 17)
      ..quadraticBezierTo(117, 17, 117, 28)
      ..quadraticBezierTo(152, 34, 152, 74)
      ..lineTo(152, 91)
      ..quadraticBezierTo(152, 105, 159, 114)
      ..lineTo(166, 124)
      ..quadraticBezierTo(169, 129, 165, 133)
      ..lineTo(35, 133)
      ..quadraticBezierTo(31, 129, 34, 124)
      ..lineTo(41, 114)
      ..quadraticBezierTo(48, 105, 48, 91)
      ..close();

    final heartPath = Path()
      ..moveTo(100, 110)
      ..cubicTo(95, 95, 81, 88, 71, 93)
      ..cubicTo(59, 98, 59, 114, 71, 122)
      ..cubicTo(81, 130, 100, 141, 100, 141)
      ..cubicTo(100, 141, 119, 130, 129, 122)
      ..cubicTo(141, 114, 141, 98, 129, 93)
      ..cubicTo(119, 88, 105, 95, 100, 110)
      ..close();

    final bellPaint = Paint()..color = bellColor;
    canvas.drawPath(bellPath, bellPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 152), width: 24, height: 14),
      bellPaint,
    );
    if (showHeart) {
      canvas.drawPath(heartPath, Paint()..color = heartColor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvisoVitalGlyphPainter oldDelegate) {
    return oldDelegate.bellColor != bellColor ||
        oldDelegate.heartColor != heartColor ||
        oldDelegate.showHeart != showHeart;
  }
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
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

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
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.50),
                  blurRadius: 60,
                  spreadRadius: 10,
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
