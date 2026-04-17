import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/realtime_simulation_service.dart';
import 'package:aviso_vital_2/features/alerts/presentation/widgets/simulation_notification_widgets.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class SimulacionAlertasScreen extends StatefulWidget {
  static const String routeName = AppRoutes.simulacionAlertas;

  const SimulacionAlertasScreen({super.key});

  @override
  State<SimulacionAlertasScreen> createState() =>
      _SimulacionAlertasScreenState();
}

class _SimulacionAlertasScreenState extends State<SimulacionAlertasScreen> {
  static const _simulationService = RealtimeSimulationService();

  LiveSimulationSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;
  int _tick = 0;
  Timer? _timer;
  late final ValueNotifier<DateTime> _nowNotifier;

  @override
  void initState() {
    super.initState();
    _nowNotifier = ValueNotifier(DateTime.now());
    // Asegura recordatorios de citas una sola vez al abrir la pantalla.
    // Se lanza sin await para no bloquear la carga inicial del snapshot.
    _simulationService.ensureReminders().catchError((_) {});
    _refreshSnapshot(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tick += 1;
      _nowNotifier.value = DateTime.now(); // reloj visual — sin red
      if (_tick % 30 == 0) {              // datos — cada 30 s
        _refreshSnapshot();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshSnapshot({bool initial = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true; // guard flag — no UI rebuild needed
    if (initial) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final snapshot = await _simulationService.loadSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isRefreshing = false;
        _isLoading = false;
        _loadError = null;
      });
      _nowNotifier.value = DateTime.now();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _openNotification(LiveNotificationItem item) async {
    if (item.type == LiveNotificationType.medication && item.dose != null) {
      await Navigator.pushNamed(
        context,
        AppRoutes.alertaMedicacion,
        arguments: {'doseId': item.dose!.id},
      );
    } else if (item.type == LiveNotificationType.appointment) {
      await Navigator.pushNamed(
        context,
        AppRoutes.alertaCita,
        arguments: {
          'alertId': item.alert?.id,
          'appointmentId': item.appointment?.id,
          'reminderKind': item.reminderKind,
        },
      );
    }

    if (!mounted) return;
    await _refreshSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.dashboard,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.orange,
      primaryGlowAlignment: const Alignment(0.85, -0.96),
      secondaryGlowAlignment: const Alignment(-0.95, 0.1),
      intensity: 0.72,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text('Pantalla de pruebas'),
      ),
      body: SafeArea(
        top: false, // el AppBar ya gestiona la zona de la barra de estado
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _SimulationErrorState(
                message: _loadError!,
                onRetry: () => _refreshSnapshot(initial: true),
              )
            : RefreshIndicator(
                onRefresh: _refreshSnapshot,
                child: ValueListenableBuilder<DateTime>(
                  valueListenable: _nowNotifier,
                  builder: (context, now, _) {
                    final visibleNotifications =
                        _snapshot?.visibleAt(now) ?? const [];

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: [
                        _SimulationHintCard(
                          syncedAt: _snapshot?.syncedAt,
                          visibleCount: visibleNotifications.length,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _PhoneFrame(
                              now: now,
                              visibleNotifications: visibleNotifications,
                              nextNotification: _snapshot?.nextScheduled,
                              onTapNotification: _openNotification,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _SimulationErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SimulationErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warningSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Icon(
                Icons.sync_problem_rounded,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No se pudo cargar la simulación',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La pantalla ya no se queda bloqueada cargando. Puede reintentar ahora.\n\nDetalle: $message',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationHintCard extends StatelessWidget {
  final DateTime? syncedAt;
  final int visibleCount;

  const _SimulationHintCard({
    required this.syncedAt,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    final syncLabel = syncedAt == null
        ? 'sin sincronizar'
        : '${syncedAt!.hour.toString().padLeft(2, '0')}:${syncedAt!.minute.toString().padLeft(2, '0')}:${syncedAt!.second.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sync_rounded, color: AppColors.textTertiary, size: 14),
        const SizedBox(width: 6),
        Text(
          'Última actualización: $syncLabel',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final DateTime now;
  final List<LiveNotificationItem> visibleNotifications;
  final LiveNotificationItem? nextNotification;
  final Future<void> Function(LiveNotificationItem item) onTapNotification;

  const _PhoneFrame({
    required this.now,
    required this.visibleNotifications,
    required this.nextNotification,
    required this.onTapNotification,
  });

  static const _frameColor    = Color(0xFF0A0A12);
  static const _frameBorder   = Color(0xFF3E4559);
  static const _buttonColor   = Color(0xFF252B3A);
  static const _screenGradStart = Color(0xFF151B2A);
  static const _screenGradEnd   = Color(0xFF0D111C);

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(now);
    final hasManyNotifications = visibleNotifications.length > 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // ── Phone body ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _frameColor,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: _frameBorder, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.06),
                blurRadius: 60,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_screenGradStart, _screenGradEnd],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                // ── Status bar + Dynamic Island ──
                _StatusBar(now: now),
                const SizedBox(height: 14),
                // ── Lock screen time ──
                Text(
                  _formatTime(now),
                  style: AppTextStyles.display1.copyWith(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFABABAB),
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // ── Notification area ──
                Container(
                  width: double.infinity,
                  height: 420,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: visibleNotifications.isEmpty
                      ? Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 10, 14, 18),
                          child: _WaitingState(
                              nextNotification: nextNotification),
                        )
                      : Scrollbar(
                          thumbVisibility: hasManyNotifications,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(14, 10, 14, 18),
                            child: Column(
                              children: [
                                if (hasManyNotifications)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      'Deslice para ver más notificaciones',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                for (final item
                                    in visibleNotifications) ...[
                                  SimulationNotificationCard(
                                    item: item,
                                    onTap: () => onTapNotification(item),
                                  ),
                                  if (item != visibleNotifications.last)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
                // ── Home indicator ──
                const _HomeIndicator(),
              ],
            ),
          ),
        ),

        // ── Left side buttons (mute · vol+ · vol−) ──────────────────
        Positioned(
          left: -4,
          top: 72,
          child: _SideButton(height: 24, color: _buttonColor),
        ),
        Positioned(
          left: -4,
          top: 108,
          child: _SideButton(height: 44, color: _buttonColor),
        ),
        Positioned(
          left: -4,
          top: 164,
          child: _SideButton(height: 44, color: _buttonColor),
        ),

        // ── Right side button (power) ────────────────────────────────
        Positioned(
          right: -4,
          top: 120,
          child: _SideButton(height: 64, color: _buttonColor),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime value) {
    const weekdays = [
      'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo',
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${weekdays[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]}';
  }
}

/// Status bar: Dynamic Island pill + clock (left) + system icons (right)
class _StatusBar extends StatelessWidget {
  final DateTime now;
  const _StatusBar({required this.now});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic Island
          Container(
            width: 126,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF05070C),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Left: time
          Positioned(
            left: 0,
            child: Text(
              timeStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Right: signal + wifi + battery
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.signal_cellular_alt_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 4),
                Icon(Icons.wifi_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Icon(Icons.battery_full_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin home indicator pill at the bottom of the screen
class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        width: 120,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Physical side button (volume / power)
class _SideButton extends StatelessWidget {
  final double height;
  final Color color;
  const _SideButton({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _WaitingState extends StatelessWidget {
  final LiveNotificationItem? nextNotification;

  const _WaitingState({required this.nextNotification});

  @override
  Widget build(BuildContext context) {
    final hasNext = nextNotification != null;
    final nextHour = hasNext
        ? formatAlertHour(nextNotification!.scheduledAt)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white70,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (hasNext) ...[
            // Frase introductoria
            Text(
              'Tu próximo aviso será a las',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFFABABAB),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // La hora es el elemento más prominente
            Text(
              nextHour!,
              textAlign: TextAlign.center,
              style: AppTextStyles.userHour.copyWith(
                color: Colors.white,
                fontSize: 56,
              ),
            ),
          ] else ...[
            Text(
              'Sin avisos programados',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando llegue la hora de una toma o cita, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFFABABAB),
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
