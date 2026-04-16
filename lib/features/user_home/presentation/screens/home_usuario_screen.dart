import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_cita_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_medicacion_screen.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_appointment_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_medication_card.dart';
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
  static const _authRepository = AuthRepository();
  static const _appointmentsRepository = AppointmentsRepository();
  static const _medicationsRepository = MedicationsRepository();
  static const _carePlanContextService = CarePlanContextService();

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
              return _buildErrorState(
                screenH: screenH,
                message:
                    'No se pudo cargar el inicio del usuario: ${snapshot.error}',
              );
            }

            final data = snapshot.data!;
            return _buildLoadedState(screenH: screenH, data: data);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState({required double screenH, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: math.max(screenH * 0.05, AppSpacing.minSection)),
          AppBackButton(onPressed: _handleUserAreaBack),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState({
    required double screenH,
    required _UserHomeViewData data,
  }) {
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
              SizedBox(height: math.max(screenH * 0.05, AppSpacing.minSection)),
              AppBackButton(onPressed: _handleUserAreaBack),
              SizedBox(
                height: math.max(screenH * 0.028, AppSpacing.minSection * 0.7),
              ),
              UserHomeHeader(
                greeting: data.greeting,
                dateLabel: data.dateLabel,
                avatarInitial: data.avatarInitial,
              ),
              SizedBox(height: math.max(screenH * 0.05, AppSpacing.minSection)),
              if (data.nextMedication != null) ...[
                NextMedicationCard(
                  medication: data.nextMedication!,
                  timeLabel: data.nextMedicationTime,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AlertaMedicacionScreen.routeName,
                  ),
                ),
                SizedBox(
                  height: math.max(screenH * 0.04, AppSpacing.minSection),
                ),
              ],
              if (data.todayAppointment != null) ...[
                NextAppointmentCard(
                  appointment: data.todayAppointment,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AlertaCitaScreen.routeName,
                    arguments: {'appointmentId': data.todayAppointment!.id},
                  ),
                ),
                SizedBox(
                  height: math.max(screenH * 0.04, AppSpacing.minSection),
                ),
              ],
              PrimaryButton.large(
                label: 'Ver mi móvil en pruebas',
                icon: Icons.smartphone_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.simulacionAlertas),
              ),
              SizedBox(height: math.max(screenH * 0.05, AppSpacing.minSection)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUserAreaBack() async {
    final navigator = Navigator.of(context);
    if (await navigator.maybePop()) return;
    final contextData = await _carePlanContextService.resolve();
    if (!mounted) return;
    final viewerIsAdmin =
        contextData.viewerProfile?.rol == RolUsuario.administrador;
    if (viewerIsAdmin) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.homeAdmin, (_) => false);
      return;
    }

    await _authRepository.signOut();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.adminLogin, (_) => false);
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
    ]).timeout(AppDurations.networkTimeout);

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
