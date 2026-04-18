import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
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
    _simulationService.ensureReminders().catchError((_) {});
    _refreshSnapshot(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tick += 1;
      _nowNotifier.value = DateTime.now();
      if (_tick % 30 == 0) {
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
    _isRefreshing = true;
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
        top: false,
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
                          child: _PhoneFrame(
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

// ─────────────────────────────────────────────────────────────────────────────
// Phone frame — tamaño dinámico: 65 % del ancho disponible (máx 400 px)
//               altura = ancho × 19.5/9, máx 720 px
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneFrame extends StatelessWidget {
  final List<LiveNotificationItem> visibleNotifications;
  final Future<void> Function(LiveNotificationItem item) onTapNotification;

  const _PhoneFrame({
    required this.visibleNotifications,
    required this.onTapNotification,
  });

  static const _frameColor  = Color(0xFF0A0A0A);
  static const _frameBorder = Color(0xFF2A2A2A);
  static const _buttonColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final phoneWidth =
            (constraints.maxWidth * 0.65).clamp(280.0, 400.0);
        final phoneHeight =
            (phoneWidth * 19.5 / 9.0).clamp(0.0, 720.0);

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
              border: Border.all(color: _frameBorder, width: 2),
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
                    Color(0xFF16213E),
                    Color(0xFF0F1729),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(36),
              ),
              // Column fills the fixed-height screen exactly
              child: Column(
                children: [
                  // ── Dynamic Island + system icons ── siempre visible
                  const _StatusBar(),
                  // ── Área de notificaciones — ocupa todo el espacio libre ──
                  Expanded(
                    child: visibleNotifications.isEmpty
                        // Estado vacío: solo se ve el wallpaper oscuro
                        ? const SizedBox.shrink()
                        // Estado con notificaciones: slide-in desde arriba
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
            child: _SideButton(height: 24, color: _buttonColor),
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
            child: _SideButton(height: 64, color: _buttonColor),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic Island pill — 100 × 26
          Container(
            width: 100,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Right: signal + wifi + battery
          const Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
        width: 90,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(4),
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
      width: 4,
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

  const _NotificationList({
    required this.notifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          for (int i = 0; i < notifications.length; i++) ...[
            TweenAnimationBuilder<double>(
              key: ValueKey(notifications[i].scheduledAt),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 280 + i * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * -20),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
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
