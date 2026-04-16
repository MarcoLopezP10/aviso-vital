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
    _refreshSnapshot(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tick += 1;
      _nowNotifier.value = DateTime.now();
      if (_tick % 5 == 0) {
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(),
        title: const Text('Pantalla de pruebas'),
      ),
      body: SafeArea(
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

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(now);
    final hasManyNotifications = visibleNotifications.length > 2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF3E4559), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF151B2A), Color(0xFF0D111C)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 132,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF05070C),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _formatTime(now),
              style: AppTextStyles.display1.copyWith(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w700,
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
            Container(
              width: double.infinity,
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              clipBehavior: Clip.antiAlias,
              child: visibleNotifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                      child: _WaitingState(nextNotification: nextNotification),
                    )
                  : Scrollbar(
                      thumbVisibility: hasManyNotifications,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        child: Column(
                          children: [
                            if (hasManyNotifications)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'Deslice para ver más notificaciones',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            for (final item in visibleNotifications) ...[
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
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime value) {
    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${weekdays[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]}';
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
