import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/realtime_simulation_service.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
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
  int _tick = 0;
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _tick += 1;
        _now = DateTime.now();
      });
      if (_tick % 5 == 0) {
        _refreshSnapshot();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSnapshot({bool initial = false}) async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      if (initial) _isLoading = true;
    });

    final snapshot = await _simulationService.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isRefreshing = false;
      _isLoading = false;
      _now = DateTime.now();
    });
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
        },
      );
    }

    if (!mounted) return;
    await _refreshSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotifications = _snapshot?.visibleAt(_now) ?? const [];

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
        title: const Text('Simulación en tiempo real'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshSnapshot,
                child: ListView(
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
                          now: _now,
                          visibleNotifications: visibleNotifications,
                          nextNotification: _snapshot?.nextScheduled,
                          onTapNotification: _openNotification,
                        ),
                      ),
                    ),
                  ],
                ),
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.amberSubtle,
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              visibleCount > 0
                  ? 'Las notificaciones activas permanecen visibles durante 5 minutos y se actualizan con la hora real. Última sincronización: $syncLabel.'
                  : 'Esta pantalla simula el móvil de la persona mayor. Cuando llegue la hora real de una toma o recordatorio, aparecerá aquí. Última sincronización: $syncLabel.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
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
                color: Colors.white70,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 420),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: visibleNotifications.isEmpty
                  ? _WaitingState(nextNotification: nextNotification)
                  : Column(
                      children: [
                        for (final item in visibleNotifications) ...[
                          _LockNotificationCard(
                            item: item,
                            now: now,
                            onTap: () => onTapNotification(item),
                          ),
                          if (item != visibleNotifications.last)
                            const SizedBox(height: 12),
                        ],
                      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: Colors.white70,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Esperando la próxima notificación',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            nextNotification == null
                ? 'Cuando llegue la hora de una toma o cita programada, aparecerá aquí automáticamente.'
                : 'Siguiente aviso previsto a las ${_formatTime(nextNotification!.scheduledAt)}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _LockNotificationCard extends StatelessWidget {
  final LiveNotificationItem item;
  final DateTime now;
  final VoidCallback onTap;

  const _LockNotificationCard({
    required this.item,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.type == LiveNotificationType.medication
        ? AppColors.amber
        : AppColors.orange;
    final icon = item.type == LiveNotificationType.medication
        ? Icons.medication_rounded
        : Icons.event_rounded;
    final remaining = item.expiresAt.difference(now);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(item.compactReminder ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: item.compactReminder
              ? Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recordatorio de cita · ${item.appointment?.especialidad ?? ''} · ${item.appointment?.hora ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.appointment?.hora ?? item.leadingLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.type == LiveNotificationType.medication
                                ? 'Aviso Vital · Medicación'
                                : 'Aviso Vital · Cita médica',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          item.leadingLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 22,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: AppRadius.chip,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            'Pulse para abrir',
                            style: AppTextStyles.caption.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Disponible ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
