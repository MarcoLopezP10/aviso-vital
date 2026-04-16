import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AuthSocialProvider {
  final String id;
  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final Color textColor;

  const AuthSocialProvider({
    required this.id,
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.textColor,
  });

  Widget buildLogo({
    required double size,
    bool muted = false,
    bool onDark = false,
  }) {
    switch (id) {
      case 'google':
        return GoogleLogoMark(size: size, muted: muted);
      case 'apple':
        return AppleLogoMark(
          size: size,
          color: muted
              ? foreground.withValues(alpha: 0.5)
              : (onDark ? Colors.white : const Color(0xFF111111)),
        );
      case 'facebook':
        return Icon(
          Icons.facebook_rounded,
          color: muted ? foreground.withValues(alpha: 0.5) : foreground,
          size: size,
        );
      default:
        return Icon(
          Icons.circle,
          color: muted ? foreground.withValues(alpha: 0.5) : foreground,
          size: size,
        );
    }
  }
}

class AuthSocialRow extends StatelessWidget {
  final ValueChanged<AuthSocialProvider>? onProviderTap;

  const AuthSocialRow({super.key, this.onProviderTap});

  static const providers = [
    AuthSocialProvider(
      id: 'google',
      label: 'Google',
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF4285F4),
      border: Color(0xFFE0E3E7),
      textColor: Color(0xFF1F1F1F),
    ),
    AuthSocialProvider(
      id: 'apple',
      label: 'Apple',
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF111111),
      border: Color(0xFFE2E2E7),
      textColor: Color(0xFF111111),
    ),
    AuthSocialProvider(
      id: 'facebook',
      label: 'Facebook',
      background: Color(0xFFF3F7FF),
      foreground: Color(0xFF1877F2),
      border: Color(0xFFD6E6FF),
      textColor: Color(0xFF12315B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final labelColor = Colors.white;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorderSoft),
      ),
      child: Row(
        children: providers
            .asMap()
            .entries
            .expand(
              (entry) => [
                if (entry.key > 0) const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Continuar con ${entry.value.label}',
                    child: InkWell(
                      onTap: onProviderTap == null
                          ? null
                          : () => onProviderTap!(entry.value),
                      borderRadius: AppRadius.card,
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: entry.value.foreground.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: entry.value.border.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: entry.value.foreground.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: entry.value.buildLogo(
                                  size: 28,
                                  onDark: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              entry.value.label,
                              style: AppTextStyles.label.copyWith(
                                color: labelColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
            .toList(),
      ),
    );
  }
}

class AppleLogoMark extends StatelessWidget {
  final double size;
  final Color color;

  const AppleLogoMark({
    super.key,
    required this.size,
    this.color = const Color(0xFF111111),
  });

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: size, color: color);
  }
}

class GoogleLogoMark extends StatelessWidget {
  final double size;
  final bool muted;

  const GoogleLogoMark({super.key, required this.size, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(muted: muted),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final bool muted;

  const _GoogleLogoPainter({required this.muted});

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final canvasSize = size.shortestSide;
    final padding = canvasSize * 0.06;
    final outerRadius = (canvasSize / 2) - padding;
    final thickness = canvasSize * 0.22;
    final innerRadius = outerRadius - thickness;
    final center = Offset(size.width / 2, size.height / 2);

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final colors = [
      muted ? _red.withValues(alpha: 0.45) : _red,
      muted
          ? const Color(0xFFFF7A00).withValues(alpha: 0.45)
          : const Color(0xFFFF7A00),
      muted ? _yellow.withValues(alpha: 0.45) : _yellow,
      muted ? _green.withValues(alpha: 0.45) : _green,
      muted
          ? const Color(0xFF10B7E8).withValues(alpha: 0.45)
          : const Color(0xFF10B7E8),
      muted ? _blue.withValues(alpha: 0.45) : _blue,
      muted ? _red.withValues(alpha: 0.45) : _red,
    ];

    final ringPaint = Paint()
      ..shader = SweepGradient(
        startAngle: _deg(-38),
        endAngle: _deg(322),
        colors: colors,
        stops: const [0.0, 0.15, 0.32, 0.56, 0.73, 0.90, 1.0],
      ).createShader(outerRect)
      ..style = PaintingStyle.fill;

    final ringPath = Path()
      ..arcTo(outerRect, _deg(-38), _deg(320), false)
      ..arcTo(innerRect, _deg(282), _deg(-320), false)
      ..close();
    canvas.drawPath(ringPath, ringPaint);

    final gapPaint = Paint()..color = Colors.white;
    final notchPath = Path()
      ..moveTo(center.dx + innerRadius * 0.72, center.dy - thickness * 1.05)
      ..lineTo(center.dx + outerRadius * 1.02, center.dy - thickness * 0.88)
      ..lineTo(center.dx + outerRadius * 1.02, center.dy - thickness * 0.08)
      ..lineTo(center.dx + innerRadius * 0.88, center.dy - thickness * 0.12)
      ..close();
    canvas.drawPath(notchPath, gapPaint);

    final barHeight = thickness * 0.92;
    final barTop = center.dy - (barHeight / 2);
    final barLeft = center.dx + innerRadius * 0.08;
    final barRight = center.dx + outerRadius * 0.95;
    final barPaint = Paint()
      ..color = muted ? _blue.withValues(alpha: 0.45) : _blue
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(barLeft, barTop, barRight, barTop + barHeight),
        Radius.circular(barHeight * 0.08),
      ),
      barPaint,
    );
  }

  static double _deg(double value) => value * math.pi / 180;

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) =>
      oldDelegate.muted != muted;
}
