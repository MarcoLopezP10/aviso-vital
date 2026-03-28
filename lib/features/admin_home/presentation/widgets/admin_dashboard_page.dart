import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_dashboard_header.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_dashboard_stats_grid.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_device_status_banner.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_quick_nav_cards.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_recent_activity_preview.dart';
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
  static const _medicationsRepository = MedicationsRepository();

  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_DashboardData> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _alertsRepository.fetchAdherenceSummary(),
        _medicationsRepository.fetchLowStock(),
        _appointmentsRepository.fetchAll(),
        _medicationsRepository.fetchAll(),
        _alertsRepository.fetchHistoryTimeline(),
        _medicationsRepository.fetchPendingTodayCount(),
        _medicationsRepository.fetchTodayDoses(),
      ]);

      final adherence = results[0] as ResumenAdherencia;
      final lowStock = results[1] as List<Medicamento>;
      final appointments = results[2] as List<Cita>;
      final medications = results[3] as List<Medicamento>;
      final alerts = results[4] as List<Alerta>;
      final pendingToday = results[5] as int;
      final doses = results[6] as List<Toma>;

      final todayAppointment = appointments
          .where((item) => item.esHoy)
          .firstOrNull;
      final upcomingDose =
          doses.where((item) => item.estado == EstadoToma.pendiente).toList()
            ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
      final upcomingMedication = upcomingDose.isNotEmpty
          ? medications
                .where((item) => item.id == upcomingDose.first.idMedicamento)
                .firstOrNull
          : _medicationsRepository.getUpcoming();

      return _DashboardData(
        adherence: adherence,
        lowStock: lowStock,
        todayAppointment: todayAppointment,
        upcomingMedication: upcomingMedication,
        alerts: alerts,
        pendingToday: pendingToday,
        medicationsCount: medications.length,
        upcomingAppointmentsCount: appointments
            .where((item) => !item.esPasada)
            .length,
        omissionsCount: alerts
            .where(
              (item) =>
                  item.estado == EstadoAlerta.omitida ||
                  item.estado == EstadoAlerta.expirada,
            )
            .length,
      );
    } catch (_) {
      return _DashboardData(
        adherence: _alertsRepository.getAdherenceSummary(),
        lowStock: _medicationsRepository.getLowStock(),
        todayAppointment: _appointmentsRepository.getToday(),
        upcomingMedication: _medicationsRepository.getUpcoming(),
        alerts: _alertsRepository.getRecent(),
        pendingToday: _medicationsRepository.getPendingTodayCount(),
        medicationsCount: _medicationsRepository.getAll().length,
        upcomingAppointmentsCount: _appointmentsRepository.getUpcomingCount(),
        omissionsCount: _alertsRepository.getRecentOmissionsCount(),
      );
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
                    'No se pudo cargar el dashboard: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final future = _loadDashboardData();
                setState(() => _dashboardFuture = future);
                await future;
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isWide ? AppSpacing.xxl : AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminDashboardHeader(),
                    const SizedBox(height: AppSpacing.md),
                    const AdminDeviceStatusBanner(),
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
                    const SectionHeader(title: 'Gestión'),
                    const SizedBox(height: AppSpacing.sm),
                    AdminQuickNavCards(
                      onOpenMedications: () =>
                          widget.onSwitchTab(AdminHomeTabIndex.medicamentos),
                      onOpenAppointments: () =>
                          widget.onSwitchTab(AdminHomeTabIndex.citas),
                      onOpenAlerts: () =>
                          widget.onSwitchTab(AdminHomeTabIndex.alertas),
                      medicationsCount: data.medicationsCount,
                      upcomingAppointmentsCount: data.upcomingAppointmentsCount,
                      omissionsCount: data.omissionsCount,
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
            shape: FormShape.round,
            size: 48,
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
                  '${medicamento.dosis} · ${medicamento.frecuencia.label}',
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
                StatusBadge.pending(small: true),
              ],
            ),
        ],
      ),
    );
  }
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
    required this.omissionsCount,
  });
}
