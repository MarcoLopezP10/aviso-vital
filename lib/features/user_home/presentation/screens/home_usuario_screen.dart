import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/app_link_service.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_cita_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_medicacion_screen.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/daily_progress_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_appointment_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_medication_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/quick_actions_strip.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/user_home_header.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class HomeUsuarioScreen extends StatefulWidget {
  static const String routeName = AppRoutes.homeUsuario;
  const HomeUsuarioScreen({super.key});

  @override
  State<HomeUsuarioScreen> createState() => _HomeUsuarioScreenState();
}

class _HomeUsuarioScreenState extends State<HomeUsuarioScreen> {
  static const _appointmentsRepository = AppointmentsRepository();
  static const _medicationsRepository = MedicationsRepository();
  static const _carePlanContextService = CarePlanContextService();
  static const _appLinkService = AppLinkService();
  static const _authRepository = AuthRepository();

  late Future<_UserHomeViewData> _viewDataFuture;

  @override
  void initState() {
    super.initState();
    _viewDataFuture = _buildViewData();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.soft,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.haloSoft,
      primaryGlowAlignment: const Alignment(0, -0.86),
      secondaryGlowAlignment: const Alignment(0.95, 0.78),
      body: SafeArea(
        child: FutureBuilder<_UserHomeViewData>(
          future: _viewDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No se pudo cargar el inicio del usuario: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final future = _buildViewData(forceRefresh: true);
                setState(() => _viewDataFuture = future);
                await future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenH * 0.04),
                      UserHomeHeader(
                        greeting: data.greeting,
                        dateLabel: data.dateLabel,
                        avatarInitial: data.avatarInitial,
                        trailing: _UserHomeExitButton(
                          onTap: () => ConfirmDialog.show(
                            context,
                            title: 'Volver al inicio',
                            message:
                                'Puede volver a la selección principal cuando quiera.',
                            confirmLabel: 'Volver',
                            onConfirm: () async {
                              await _appLinkService.clear();
                              if (SupabaseService.currentUser != null) {
                                await _authRepository.signOut();
                              }
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.roleSelection,
                                (_) => false,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: screenH * 0.03),
                      DailyProgressCard(
                        confirmed: data.confirmedToday,
                        total: data.totalToday,
                        pending: data.pendingToday,
                      ),
                      SizedBox(height: screenH * 0.03),
                      WeeklyAdherenceStrip(weekDoses: data.weekDoses),
                      SizedBox(height: screenH * 0.04),
                      if (data.nextMedication != null) ...[
                        _SectionLabel('Próxima medicación'),
                        const SizedBox(height: 10),
                        NextMedicationCard(
                          medication: data.nextMedication!,
                          timeLabel: data.nextMedicationTime,
                          statusLabel: data.pendingToday > 0
                              ? 'Pendiente'
                              : 'Al día',
                          statusColor: data.pendingToday > 0
                              ? AppColors.warning
                              : AppColors.success,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AlertaMedicacionScreen.routeName,
                          ),
                        ),
                        SizedBox(height: screenH * 0.035),
                      ],
                      const _SectionLabel('Próxima cita médica'),
                      const SizedBox(height: 10),
                      NextAppointmentCard(
                        appointment: data.todayAppointment,
                        onTap: data.todayAppointment == null
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                AlertaCitaScreen.routeName,
                                arguments: {
                                  'appointmentId': data.todayAppointment!.id,
                                },
                              ),
                      ),
                      SizedBox(height: screenH * 0.04),
                      PrimaryButton.large(
                        label: 'Simulación en tiempo real',
                        icon: Icons.smartphone_rounded,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.simulacionAlertas,
                        ),
                      ),
                      SizedBox(height: screenH * 0.028),
                      QuickActionsStrip(pendingCount: data.pendingToday),
                      SizedBox(height: screenH * 0.04),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_UserHomeViewData> _buildViewData({bool forceRefresh = false}) async {
    final contextData = await _carePlanContextService.resolve();
    final ownerId = contextData.ownerUserId;
    final results = await Future.wait([
      _medicationsRepository.fetchDailySnapshot(
        userId: ownerId,
        forceRefresh: forceRefresh,
      ),
      _appointmentsRepository.fetchAll(
        userId: ownerId,
        forceRefresh: forceRefresh,
      ),
      _medicationsRepository.fetchWeekDoses(userId: ownerId),
    ]);

    final medicationSnapshot = results[0] as MedicationDailySnapshot;
    final appointments = results[1] as List<Cita>;
    final weekDoses = results[2] as List<Toma>;
    final sortedUpcomingAppointments =
        appointments.where((item) => !item.esPasada).toList(growable: false)
          ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    final todayAppointment = sortedUpcomingAppointments.firstOrNull;
    final pendingToday = medicationSnapshot.pendingTodayCount;
    final dosesToday = medicationSnapshot.doses;
    final profile =
        contextData.careRecipientProfile ?? contextData.viewerProfile;
    final confirmedToday = dosesToday
        .where((dose) => dose.estado == EstadoToma.confirmada)
        .length;
    final totalToday = dosesToday.length;
    final now = DateTime.now();
    final firstName = (profile?.nombre ?? '').split(' ').first;
    final greeting = firstName.isEmpty || firstName.toLowerCase() == 'usuario'
        ? _greetingForHour(now.hour)
        : '${_greetingForHour(now.hour)}, $firstName';

    return _UserHomeViewData(
      greeting: greeting,
      dateLabel: _formatDate(now),
      avatarInitial: firstName.isNotEmpty ? firstName[0] : null,
      nextMedication: medicationSnapshot.upcomingMedication,
      nextMedicationTime: medicationSnapshot.upcomingTime,
      todayAppointment: todayAppointment,
      pendingToday: pendingToday,
      confirmedToday: confirmedToday,
      totalToday: totalToday,
      weekDoses: weekDoses,
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatDate(DateTime date) {
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
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UserHomeExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UserHomeExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Volver',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceFloating,
            borderRadius: AppRadius.icon,
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: AppShadows.cardSubtle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _UserHomeViewData {
  final String greeting;
  final String dateLabel;
  final String? avatarInitial;
  final Medicamento? nextMedication;
  final String nextMedicationTime;
  final Cita? todayAppointment;
  final int pendingToday;
  final int confirmedToday;
  final int totalToday;
  final List<Toma> weekDoses;

  const _UserHomeViewData({
    required this.greeting,
    required this.dateLabel,
    this.avatarInitial,
    required this.nextMedication,
    required this.nextMedicationTime,
    required this.todayAppointment,
    required this.pendingToday,
    required this.confirmedToday,
    required this.totalToday,
    required this.weekDoses,
  });
}
