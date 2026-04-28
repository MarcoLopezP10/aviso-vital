import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/core/services/realtime_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/daily_progress_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_appointment_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/next_medication_card.dart';
import 'package:aviso_vital_2/features/user_home/presentation/widgets/user_home_header.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
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

  final _realtimeService = RealtimeService();
  late Future<_UserHomeViewData> _viewDataFuture;
  StreamSubscription<RealtimeChangeType>? _realtimeSub;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _viewDataFuture = _buildViewData();
    _realtimeService.start();
    _realtimeSub = _realtimeService.changes.listen(_scheduleReload);
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _realtimeSub?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                message: context.t.isEnglish
                    ? 'Could not load the user home: ${snapshot.error}'
                    : 'No se pudo cargar el inicio del usuario: ${snapshot.error}',
              );
            }

            return _buildLoadedState(data: snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState({required String message}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  Widget _buildLoadedState({required _UserHomeViewData data}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < AppBreakpoints.mobile
        ? AppSpacing.lg
        : AppSpacing.xxl;

    return RefreshIndicator(
      onRefresh: () => _reloadViewData(forceRefresh: true),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.contentMaxWidthNarrow,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── ZONA A: Header ──────────────────────────────────────
                  UserHomeHeader(
                    greeting: data.greeting,
                    dateLabel: data.dateLabel,
                    avatarInitial: data.avatarInitial,
                    trailing: _LogoutButton(onPressed: _handleUserAreaBack),
                  ),

                  if (data.totalCount > 0) ...[
                    const SizedBox(height: AppSpacing.lg),
                    DailyProgressCard(
                      confirmed: data.confirmedCount,
                      total: data.totalCount,
                      pending: data.pendingCount,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // ── ZONA B: Próxima medicación ──────────────────────────
                  _SectionLabel(context.t.nextMedication),
                  const SizedBox(height: AppSpacing.sm),
                  if (data.nextMedication != null)
                    NextMedicationCard(
                      medication: data.nextMedication!,
                      timeLabel: data.nextMedicationTime,
                    )
                  else
                    const _EmptyMedicationCard(),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── ZONA C: Próxima cita (solo si existe) ───────────────
                  if (data.todayAppointment != null) ...[
                    _SectionLabel(context.t.nextAppointment),
                    const SizedBox(height: AppSpacing.sm),
                    NextAppointmentCard(appointment: data.todayAppointment),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── ZONA D: Botón simulador ─────────────────────────────
                  _SimulationButtonCard(onTap: _openSimulation),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
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
    navigator.pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
  }

  void _scheduleReload(RealtimeChangeType _) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _reloadViewData(forceRefresh: true);
    });
  }

  Future<_UserHomeViewData> _reloadViewData({bool forceRefresh = false}) {
    final future = _buildViewData(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() => _viewDataFuture = future);
    }
    return future;
  }

  Future<void> _openSimulation() async {
    await Navigator.pushNamed(context, AppRoutes.simulacionAlertas);
    if (!mounted) return;
    await _reloadViewData(forceRefresh: true);
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
    ]).timeout(AppDurations.networkTimeout);

    final medicationSnapshot = results[0] as MedicationDailySnapshot;
    final appointments = results[1] as List<Cita>;
    final sortedUpcoming =
        appointments.where((c) => !c.esPasada).toList(growable: false)
          ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    final nextAppointment = sortedUpcoming.firstOrNull;
    final profile =
        contextData.careRecipientProfile ?? contextData.viewerProfile;
    final now = DateTime.now();
    final strings = AppStrings.current;
    final firstName = (profile?.nombre ?? '').split(' ').first;
    final greeting = firstName.isEmpty || firstName.toLowerCase() == 'usuario'
        ? strings.greetingForHour(now.hour)
        : '${strings.greetingForHour(now.hour)}, $firstName';

    final doses = medicationSnapshot.doses;
    final confirmedCount =
        doses.where((d) => d.estado == EstadoToma.confirmada).length;
    final pendingCount =
        doses.where((d) => d.estado == EstadoToma.pendiente).length;

    return _UserHomeViewData(
      greeting: greeting,
      dateLabel: strings.fullDate(now),
      avatarInitial: firstName.isNotEmpty ? firstName[0] : null,
      nextMedication: medicationSnapshot.upcomingMedication,
      nextMedicationTime: medicationSnapshot.upcomingTime,
      todayAppointment: nextAppointment,
      confirmedCount: confirmedCount,
      totalCount: confirmedCount + pendingCount,
      pendingCount: pendingCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserHomeViewData {
  final String greeting;
  final String dateLabel;
  final String? avatarInitial;
  final Medicamento? nextMedication;
  final String nextMedicationTime;
  final Cita? todayAppointment;
  final int confirmedCount;
  final int totalCount;
  final int pendingCount;

  const _UserHomeViewData({
    required this.greeting,
    required this.dateLabel,
    this.avatarInitial,
    required this.nextMedication,
    required this.nextMedicationTime,
    required this.todayAppointment,
    required this.confirmedCount,
    required this.totalCount,
    required this.pendingCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textTertiary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMedicationCard extends StatelessWidget {
  const _EmptyMedicationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFloating,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        context.t.noMedicationToday,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 18,
          height: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SimulationButtonCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SimulationButtonCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.smartphone_rounded, size: 18, color: AppColors.info),
        label: Text(
          context.t.mobileSimulationSubtitle,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _LogoutButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.t.logout,
      button: true,
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, size: 20),
        color: AppColors.textTertiary,
        tooltip: context.t.logout,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.all(10),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
