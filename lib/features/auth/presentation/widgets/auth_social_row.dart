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
    final side = size.shortestSide;
    final stroke = side * 0.22;
    final radius = (side - stroke) / 2 - (side * 0.02);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = muted ? color.withValues(alpha: 0.45) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, _deg(-8), _deg(100), false, arcPaint(_blue));
    canvas.drawArc(rect, _deg(92), _deg(88), false, arcPaint(_green));
    canvas.drawArc(rect, _deg(180), _deg(58), false, arcPaint(_yellow));
    canvas.drawArc(rect, _deg(238), _deg(96), false, arcPaint(_red));

    final innerRadius = radius - stroke / 2;
    final barHeight = stroke * 0.82;
    final barTop = center.dy - (barHeight / 2);
    final barLeft = center.dx - side * 0.01;
    final barRight = center.dx + radius + stroke * 0.10;

    // Barra horizontal + recorte en una capa aislada para que el cutout sea
    // transparente de verdad independientemente del fondo.
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final barPaint = Paint()
      ..color = muted ? _blue.withValues(alpha: 0.45) : _blue
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(barLeft, barTop, barRight, barTop + barHeight),
        Radius.circular(barHeight * 0.14),
      ),
      barPaint,
    );

    // Recorte con BlendMode.dstOut: borra los píxeles de la capa (transparente)
    final cutPaint = Paint()
      ..color = Colors.black
      ..blendMode = BlendMode.dstOut;
    final cutout = Path()
      ..moveTo(center.dx + innerRadius * 0.52, center.dy - stroke * 0.86)
      ..lineTo(center.dx + radius + stroke * 0.22, center.dy - stroke * 0.86)
      ..lineTo(center.dx + radius + stroke * 0.22, center.dy - stroke * 0.12)
      ..lineTo(center.dx + innerRadius * 0.78, center.dy - stroke * 0.12)
      ..close();
    canvas.drawPath(cutout, cutPaint);

    canvas.restore();
  }

  static double _deg(double value) => value * math.pi / 180;

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) =>
      oldDelegate.muted != muted;
}
