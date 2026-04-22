import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/realtime_service.dart';
import 'package:aviso_vital_2/core/services/realtime_simulation_service.dart';
import 'package:aviso_vital_2/features/alerts/presentation/widgets/simulation_notification_widgets.dart';
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

  final _realtimeService = RealtimeService();
  StreamSubscription<RealtimeChangeType>? _realtimeSub;
  LiveSimulationSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;
  int _tick = 0;
  Timer? _timer;
  Timer? _realtimeDebounce;
  late final ValueNotifier<DateTime> _nowNotifier;

  @override
  void initState() {
    super.initState();
    _nowNotifier = ValueNotifier(DateTime.now());
    _simulationService.ensureReminders().catchError((_) {});
    _refreshSnapshot(initial: true, forceRefresh: true);
    _realtimeService.start();
    _realtimeSub = _realtimeService.changes.listen(_onRealtimeChange);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tick += 1;
      _nowNotifier.value = DateTime.now();
      if (_tick % 30 == 0) {
        _refreshSnapshot(forceRefresh: true);
      }
    });
  }

  void _onRealtimeChange(RealtimeChangeType _) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _refreshSnapshot(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    _realtimeService.dispose();
    _timer?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshSnapshot({
    bool initial = false,
    bool forceRefresh = false,
  }) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (initial) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final snapshot = await _simulationService.loadSnapshot(
        forceRefresh: forceRefresh,
      );
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
    await _refreshSnapshot(forceRefresh: true);
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
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _SimulationErrorState(
                message: _loadError!,
                onRetry: () => _refreshSnapshot(initial: true),
              )
            : RefreshIndicator(
                onRefresh: () => _refreshSnapshot(forceRefresh: true),
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
                        _SimulationHintCard(syncedAt: _snapshot?.syncedAt),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: _PhoneFrame(
                            currentTime: now,
                            visibleNotifications: visibleNotifications,
                            onTapNotification: _openNotification,
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

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Sync hint
// ─────────────────────────────────────────────────────────────────────────────

class _SimulationHintCard extends StatelessWidget {
  final DateTime? syncedAt;

  const _SimulationHintCard({required this.syncedAt});

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
        Text('Última actualización: $syncLabel', style: AppTextStyles.caption),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone frame — se adapta tanto al ancho como a la altura visible para que
// el mockup entre completo en la pantalla de simulación.
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneFrame extends StatelessWidget {
  static const _phoneAspectRatio = 17.8 / 9.0;
  final DateTime currentTime;
  final List<LiveNotificationItem> visibleNotifications;
  final Future<void> Function(LiveNotificationItem item) onTapNotification;

  const _PhoneFrame({
    required this.currentTime,
    required this.visibleNotifications,
    required this.onTapNotification,
  });

  static const _frameColor = Color(0xFF0A0A0A);
  static const _frameBorder = Color(0x14FFFFFF);
  static const _buttonColor = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final phoneWidth =
            (availableWidth >= 320.0
                    ? availableWidth.clamp(320.0, 360.0)
                    : availableWidth)
                .toDouble();
        final phoneHeight = phoneWidth * _phoneAspectRatio;

        return SizedBox(
          width: phoneWidth,
          height: phoneHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Phone body ──────────────────────────────────────────────
              Container(
                width: phoneWidth,
                height: phoneHeight,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _frameColor,
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: _frameBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 40,
                      offset: const Offset(0, 24),
                    ),
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.06),
                      blurRadius: 70,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.2, -1.0),
                      end: Alignment(0.2, 1.0),
                      colors: [
                        Color(0xFF1A1A2E),
                        Color(0xFF0D0D1A),
                        Color(0xFF0A0A14),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Column(
                    children: [
                      // ── Dynamic Island ── siempre visible
                      const _StatusBar(),
                      SizedBox(height: 14 * (phoneWidth / 320)),
                      _LockScreenHeader(
                        now: currentTime,
                        scale: phoneWidth / 320,
                      ),
                      SizedBox(height: 18 * (phoneWidth / 320)),
                      // ── Área de notificaciones — ocupa todo el espacio libre ──
                      Expanded(
                        child: visibleNotifications.isEmpty
                            ? const SizedBox.shrink()
                            : _NotificationList(
                                notifications: visibleNotifications,
                                onTap: onTapNotification,
                              ),
                      ),
                      // ── Home indicator ── siempre visible
                      const _HomeIndicator(),
                    ],
                  ),
                ),
              ),

              // ── Left side buttons (mute · vol+ · vol−) ──────────────────
              const Positioned(
                left: -4,
                top: 72,
                child: _SideButton(height: 28, color: _buttonColor),
              ),
              const Positioned(
                left: -4,
                top: 108,
                child: _SideButton(height: 44, color: _buttonColor),
              ),
              const Positioned(
                left: -4,
                top: 164,
                child: _SideButton(height: 44, color: _buttonColor),
              ),

              // ── Right side button (power) ────────────────────────────────
              const Positioned(
                right: -4,
                top: 120,
                child: _SideButton(height: 44, color: _buttonColor),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status bar — Dynamic Island + system icons
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Center(
        child: Container(
          width: 110,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _LockScreenHeader extends StatelessWidget {
  final DateTime now;
  final double scale;

  const _LockScreenHeader({required this.now, required this.scale});

  static const _weekdays = <String>[
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const _months = <String>[
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

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateLabel =
        '${_weekdays[now.weekday - 1]}, ${now.day} de ${_months[now.month - 1]}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Column(
        children: [
          Text(
            timeLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.display1.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 68 * scale,
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
              height: 1,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            dateLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home indicator pill
// ─────────────────────────────────────────────────────────────────────────────

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        width: 120,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Physical side button
// ─────────────────────────────────────────────────────────────────────────────

class _SideButton extends StatelessWidget {
  final double height;
  final Color color;
  const _SideButton({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification list — slide-in desde arriba por tarjeta
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<LiveNotificationItem> notifications;
  final Future<void> Function(LiveNotificationItem) onTap;

  const _NotificationList({required this.notifications, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          for (int i = 0; i < notifications.length; i++) ...[
            TweenAnimationBuilder<double>(
              key: ValueKey(
                '${notifications[i].id}:${notifications[i].scheduledAt.toIso8601String()}:$i',
              ),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 280 + i * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * -20),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              ),
              child: SimulationNotificationCard(
                item: notifications[i],
                onTap: () => onTap(notifications[i]),
              ),
            ),
            if (i < notifications.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
