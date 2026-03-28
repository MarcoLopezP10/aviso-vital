import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'dispositivo_conectado_screen.dart';

/// Pantalla: Escaneo QR activo
class EscaneoQrScreen extends StatefulWidget {
  static const String routeName = AppRoutes.escaneoQr;
  const EscaneoQrScreen({super.key});

  @override
  State<EscaneoQrScreen> createState() => _EscaneoQrScreenState();
}

class _EscaneoQrScreenState extends State<EscaneoQrScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _onQrDetected() {
    _scanCtrl.stop();
    Navigator.pushReplacementNamed(context, DispositivoConectadoScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final qrSize = screenH * 0.35;

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.focus,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.orange,
      primaryGlowAlignment: const Alignment(0, -0.45),
      secondaryGlowAlignment: const Alignment(0.82, 0.5),
      intensity: 1.02,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: screenH * 0.02),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modo Usuario',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.amber, letterSpacing: 1.5)),
                      Text('Escanear código QR',
                          style: AppTextStyles.h3),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Marco QR
            SizedBox(
              width: qrSize,
              height: qrSize,
              child: Stack(
                children: [
                  // Fondo oscuro
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surfaceOverlay,
                          AppColors.surfaceRaised,
                        ],
                      ),
                      borderRadius: AppRadius.cardLg,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.1),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: qrSize * 0.65,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // Esquinas decorativas
                  CustomPaint(
                    size: Size(qrSize, qrSize),
                    painter: _QrCornerPainter(),
                  ),
                  // Línea de escaneo
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, child) => Positioned(
                      top: qrSize * _scanAnim.value,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.amber.withValues(alpha: 0),
                              AppColors.amber,
                              AppColors.amber.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Coloque el código dentro del escáner',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Botón simular detección (para demo/TFG)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, screenH * 0.04),
              child: PrimaryButton(
                label: 'Simular detección QR',
                icon: Icons.check_circle_outline,
                onPressed: _onQrDetected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const r = 10.0;
    const len = 28.0;
    final corners = [
      [Offset(r, 0), Offset(len, 0), Offset(0, len), Offset(0, r)],
      [Offset(size.width - r, 0), Offset(size.width - len, 0), Offset(size.width, len), Offset(size.width, r)],
      [Offset(0, size.height - r), Offset(0, size.height - len), Offset(len, size.height), Offset(r, size.height)],
      [Offset(size.width - r, size.height), Offset(size.width - len, size.height), Offset(size.width, size.height - len), Offset(size.width, size.height - r)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[2], c[3], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
