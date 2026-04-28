import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aviso_vital_2/core/services/realtime_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/device_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_dashboard_header.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_dashboard_stats_grid.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_recent_activity_preview.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/content_widgets.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminHomeTabIndex {
  static const int medicamentos = 1;
  static const int citas = 2;
  static const int alertas = 3;

  const AdminHomeTabIndex._();
}

class AdminDashboardPage extends StatefulWidget {
  final void Function(int) onSwitchTab;
  final VoidCallback onOpenRecentActivity;

  const AdminDashboardPage({
    super.key,
    required this.onSwitchTab,
    required this.onOpenRecentActivity,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _alertsRepository = AlertsRepository();
  static const _appointmentsRepository = AppointmentsRepository();
  static const _deviceRepository = DeviceRepository();
  static const _medicationsRepository = MedicationsRepository();

  late Future<_DashboardData> _dashboardFuture;
  final _realtimeService = RealtimeService();
  StreamSubscription<RealtimeChangeType>? _realtimeSub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
    _realtimeService.start();
    _realtimeSub = _realtimeService.changes.listen(_onRealtimeChange);
  }

  void _onRealtimeChange(RealtimeChangeType _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final future = _loadDashboardData(forceRefresh: true);
      setState(() {
        _dashboardFuture = future;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _realtimeSub?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<_DashboardData> _loadDashboardData({bool forceRefresh = false}) async {
    try {
      final alertsFuture = _alertsRepository.fetchHistoryTimeline(
        forceRefresh: forceRefresh,
      );
      final medicationSnapshotFuture = _medicationsRepository
          .fetchDailySnapshot(forceRefresh: forceRefresh);
      final appointmentsFuture = _appointmentsRepository.fetchAll(
        forceRefresh: forceRefresh,
      );
      final linkedDeviceFuture = _loadLinkedDeviceStatusSafely();

      final alerts = await alertsFuture;
      final results = await Future.wait([
        medicationSnapshotFuture,
        appointmentsFuture,
        _alertsRepository.fetchAdherenceSummary(historyTimeline: alerts),
        linkedDeviceFuture,
      ]).timeout(AppDurations.networkTimeout);

      final medicationSnapshot = results[0] as MedicationDailySnapshot;
      final appointments = results[1] as List<Cita>;
      final adherence = results[2] as ResumenAdherencia;
      final linkedDevice = results[3] as LinkedDeviceStatus?;
      final medications = medicationSnapshot.medications;
      final lowStock = medications
          .where((item) => item.stockBajo && item.activo)
          .toList(growable: false);

      final todayAppointment = appointments
          .where((item) => item.esHoy)
          .firstOrNull;

      return _DashboardData(
        adherence: adherence,
        lowStock: lowStock,
        todayAppointment: todayAppointment,
        upcomingMedication: medicationSnapshot.upcomingMedication,
        alerts: alerts,
        pendingToday: medicationSnapshot.pendingTodayCount,
        medicationsCount: medications.length,
        upcomingAppointmentsCount: appointments
            .where((item) => !item.esPasada)
            .length,
        linkedUserConnected: linkedDevice?.connected == true,
        linkedUserName: linkedDevice?.displayName,
        omissionsCount: alerts
            .where(
              (item) =>
                  item.estado == EstadoAlerta.omitida ||
                  item.estado == EstadoAlerta.expirada,
            )
            .length,
      );
    } catch (_) {
      final linkedDevice = await _loadLinkedDeviceStatusSafely();
      return _DashboardData(
        adherence: _alertsRepository.getAdherenceSummary(),
        lowStock: _medicationsRepository.getLowStock(),
        todayAppointment: _appointmentsRepository.getToday(),
        upcomingMedication: _medicationsRepository.getUpcoming(),
        alerts: _alertsRepository.getRecent(),
        pendingToday: _medicationsRepository.getPendingTodayCount(),
        medicationsCount: _medicationsRepository.getAll().length,
        upcomingAppointmentsCount: _appointmentsRepository.getUpcomingCount(),
        linkedUserConnected: linkedDevice?.connected == true,
        linkedUserName: linkedDevice?.displayName,
        omissionsCount: _alertsRepository.getRecentOmissionsCount(),
      );
    }
  }

  Future<LinkedDeviceStatus?> _loadLinkedDeviceStatusSafely() async {
    try {
      return await _deviceRepository.getLinkedDeviceStatus();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final sectionGap = isWide ? AppSpacing.xl : AppSpacing.lg;

    return AppBackground(
      variant: PremiumBackgroundVariant.dashboard,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.haloBlue,
      primaryGlowAlignment: const Alignment(0.92, -0.95),
      secondaryGlowAlignment: const Alignment(-0.95, 0.15),
      intensity: 0.46,
      child: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    context.t.isEnglish
                        ? 'Could not load the dashboard: ${snapshot.error}'
                        : 'No se pudo cargar el dashboard: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final future = _loadDashboardData(forceRefresh: true);
                setState(() {
                  _dashboardFuture = future;
                });
                await future;
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.contentMaxWidthWide,
                  ),
                  child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? AppSpacing.xxl : AppSpacing.xl,
                  isWide ? AppSpacing.xxl : AppSpacing.xl,
                  isWide ? AppSpacing.xxl : AppSpacing.xl,
                  isWide
                      ? AppSpacing.xxl
                      : kBottomNavigationBarHeight +
                            MediaQuery.of(context).padding.bottom +
                            AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminDashboardHeader(
                      caredUserName:
                          data.linkedUserName ??
                          context.t.text('Usuario mayor'),
                      isConnected: data.linkedUserConnected,
                    ),
                    SizedBox(height: sectionGap),
                    if (data.upcomingMedication != null ||
                        data.todayAppointment != null) ...[
                      const SectionHeader(title: 'Lo importante de hoy'),
                      const SizedBox(height: AppSpacing.sm),
                      if (data.upcomingMedication != null) ...[
                        _UpcomingMedicationCard(
                          medicamento: data.upcomingMedication!,
                        ),
                        if (data.todayAppointment != null)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                      if (data.todayAppointment != null)
                        AppointmentCard(
                          cita: data.todayAppointment!,
                          onTap: () =>
                              widget.onSwitchTab(AdminHomeTabIndex.citas),
                          compact: true,
                        ),
                      SizedBox(height: sectionGap),
                    ],
                    const SectionHeader(title: 'Resumen general'),
                    const SizedBox(height: AppSpacing.sm),
                    AdminDashboardStatsGrid(
                      adherencia: data.adherence,
                      stockBajoCount: data.lowStock.length,
                      citaHoy: data.todayAppointment,
                      pendientesHoy: data.pendingToday,
                    ),
                    SizedBox(height: sectionGap),
                    if (data.lowStock.isNotEmpty) ...[
                      const SectionHeader(title: 'Stock bajo'),
                      const SizedBox(height: AppSpacing.xs),
                      ...data.lowStock.map(
                        (medication) => MedicationCard(
                          medicamento: medication,
                          compact: true,
                          onTap: () => widget.onSwitchTab(
                            AdminHomeTabIndex.medicamentos,
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                    ],
                    AdminRecentActivityPreview(
                      alertas: data.alerts,
                      onViewAll: widget.onOpenRecentActivity,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpcomingMedicationCard extends StatelessWidget {
  static const _medicationsRepository = MedicationsRepository();

  final Medicamento medicamento;

  const _UpcomingMedicationCard({required this.medicamento});

  @override
  Widget build(BuildContext context) {
    final pendiente = _medicationsRepository.getUpcomingDoseForMedication(
      medicamento.id,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surfaceStrong],
        ),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          PillVisual(
            color: medicamento.colorPastilla,
            shape: _toFormShape(medicamento.formaPastilla),
            size: 36,
            showGlow: true,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicamento.nombre, style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(
                  '${medicamento.dosis} · ${medicamento.resumenTomas}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (pendiente != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pendiente.fechaProgramada.hour.toString().padLeft(2, '0')}:${pendiente.fechaProgramada.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.h4.copyWith(color: AppColors.amber),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge.pending(small: true),
              ],
            ),
        ],
      ),
    );
  }

  FormShape _toFormShape(FormaPastilla shape) => switch (shape) {
    FormaPastilla.redonda => FormShape.round,
    FormaPastilla.ovalada => FormShape.oval,
    FormaPastilla.capsula => FormShape.capsule,
  };
}

class _DashboardData {
  final ResumenAdherencia adherence;
  final List<Medicamento> lowStock;
  final Cita? todayAppointment;
  final Medicamento? upcomingMedication;
  final List<Alerta> alerts;
  final int pendingToday;
  final int medicationsCount;
  final int upcomingAppointmentsCount;
  final bool linkedUserConnected;
  final String? linkedUserName;
  final int omissionsCount;

  const _DashboardData({
    required this.adherence,
    required this.lowStock,
    required this.todayAppointment,
    required this.upcomingMedication,
    required this.alerts,
    required this.pendingToday,
    required this.medicationsCount,
    required this.upcomingAppointmentsCount,
    required this.linkedUserConnected,
    required this.linkedUserName,
    required this.omissionsCount,
  });
}
