import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

/// Pantalla: Alerta de Cita Médica — flujo Carmen
class AlertaCitaScreen extends StatefulWidget {
  static const String routeName = AppRoutes.alertaCita;
  final String? alertId;
  final String? appointmentId;
  final String? reminderKind;
  final String? reminderInstanceId;

  const AlertaCitaScreen({
    super.key,
    this.alertId,
    this.appointmentId,
    this.reminderKind,
    this.reminderInstanceId,
  });

  @override
  State<AlertaCitaScreen> createState() => _AlertaCitaScreenState();
}

class _AlertaCitaScreenState extends State<AlertaCitaScreen> {
  static const _appointmentsRepository = AppointmentsRepository();
  static const _alertsRepository = AlertsRepository();
  static const _carePlanContextService = CarePlanContextService();
  bool _confirmado = false;
  late Future<_AppointmentAlertData?> _appointmentFuture;
  bool _isSubmitting = false;

  String _tiempoHastaCita(String hora) {
    final strings = AppStrings.current;
    final parts = hora.split(':');
    if (parts.length != 2) return strings.soon;
    final citaMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final diff = citaMin - nowMin;
    if (diff <= 0) return strings.now;
    if (diff < 60) return strings.minutesUntil(diff);
    final h = diff ~/ 60;
    final m = diff % 60;
    return strings.hoursUntil(h, m);
  }

  Future<void> _confirmar(_AppointmentAlertData data) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    if (data.alertId != null) {
      await _alertsRepository.confirmAlert(data.alertId!);
    }
    if (widget.appointmentId != null &&
        widget.appointmentId!.isNotEmpty &&
        widget.reminderKind != null &&
        widget.reminderKind!.isNotEmpty) {
      _alertsRepository.markAppointmentReminderHandled(
        appointmentId: widget.appointmentId!,
        reminderKind: widget.reminderKind!,
        instanceId: widget.reminderInstanceId,
      );
    }
    setState(() {
      _confirmado = true;
      _isSubmitting = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    super.initState();
    _appointmentFuture = _loadAppointmentData();
  }

  Future<void> _handleBack() async {
    final navigator = Navigator.of(context);
    if (await navigator.maybePop()) return;
    final contextData = await _carePlanContextService.resolve();
    if (!mounted) return;
    final fallbackRoute =
        contextData.viewerProfile?.rol == RolUsuario.administrador
        ? AppRoutes.homeAdmin
        : AppRoutes.homeUsuario;
    navigator.pushNamedAndRemoveUntil(fallbackRoute, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.focus,
      primaryGlowColor: AppColors.orange,
      secondaryGlowColor: AppColors.amber,
      primaryGlowAlignment: const Alignment(0, -0.78),
      secondaryGlowAlignment: const Alignment(0.9, 0.72),
      intensity: 0.82,
      body: SafeArea(
        child: FutureBuilder<_AppointmentAlertData?>(
          future: _appointmentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _AppointmentUnavailableView(
                message: context.t.appointmentLoadError(
                  snapshot.error.toString(),
                ),
                onBack: _handleBack,
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return _AppointmentUnavailableView(
                message: context.t.noUpcomingAppointments,
                onBack: _handleBack,
              );
            }

            final tiempoLabel = _tiempoHastaCita(data.appointment.hora);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _confirmado
                  ? const _ConfirmadoView(key: ValueKey('ok'))
                  : _CitaAlertaView(
                      key: const ValueKey('cita'),
                      cita: data.appointment,
                      tiempoLabel: tiempoLabel,
                      isReadOnly: data.isReminderHandled,
                      onClose: _handleBack,
                      onConfirm: () => _confirmar(data),
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<_AppointmentAlertData?> _loadAppointmentData() async {
    final contextData = await _carePlanContextService.resolve();
    final ownerId = contextData.ownerUserId;
    Cita? appointment;

    if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
      appointment = await _appointmentsRepository.fetchById(
        widget.appointmentId!,
      );
    } else {
      final appointments = await _appointmentsRepository.fetchAll(
        userId: ownerId,
      );
      appointment = appointments.where((item) => !item.esPasada).firstOrNull;
    }

    if (appointment == null) return null;
    final reminderKind = widget.reminderKind?.trim();
    final appointmentId = widget.appointmentId?.trim();
    final isHandledLocally =
        appointmentId != null &&
        appointmentId.isNotEmpty &&
        reminderKind != null &&
        reminderKind.isNotEmpty &&
        _alertsRepository.isAppointmentReminderHandled(
          appointmentId: appointmentId,
          reminderKind: reminderKind,
          instanceId: widget.reminderInstanceId,
        );
    return _AppointmentAlertData(
      appointment: appointment,
      alertId: widget.alertId,
      isReminderHandled: isHandledLocally,
    );
  }
}

class _AppointmentAlertData {
  final Cita appointment;
  final String? alertId;
  final bool isReminderHandled;

  const _AppointmentAlertData({
    required this.appointment,
    this.alertId,
    this.isReminderHandled = false,
  });
}

class _AppointmentUnavailableView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _AppointmentUnavailableView({
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBackButton(onPressed: onBack),
          const Spacer(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    size: 52,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: context.t.back,
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Vista principal de la alerta ────────────────────────────────────

class _CitaAlertaView extends StatelessWidget {
  final dynamic cita;
  final String tiempoLabel;
  final bool isReadOnly;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const _CitaAlertaView({
    super.key,
    required this.cita,
    required this.tiempoLabel,
    required this.isReadOnly,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        final veryCompact = constraints.maxHeight < 700;
        final horizontalPadding = constraints.maxWidth < 360
            ? AppSpacing.lg
            : AppSpacing.xl;
        final titleSize = veryCompact ? 26.0 : (compact ? 29.0 : 32.0);
        final iconSize = veryCompact ? 70.0 : (compact ? 78.0 : 88.0);
        final strings = context.t;
        final stateColor = isReadOnly ? AppColors.success : AppColors.orange;
        final stateSubtle = isReadOnly
            ? AppColors.successSubtle
            : AppColors.orangeSubtle;
        final stateBorder = isReadOnly
            ? AppColors.successBorder
            : AppColors.orangeBorder;
        final title = isReadOnly
            ? strings.appointmentReminderConfirmed
            : strings.appointmentAlertTitle(tiempoLabel);
        final chipLabel = isReadOnly
            ? strings.appointmentTiming(tiempoLabel)
            : strings.appointmentReminderChip;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            veryCompact ? AppSpacing.sm : AppSpacing.md,
            horizontalPadding,
            compact ? AppSpacing.lg : AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight -
                  (compact ? AppSpacing.lg : AppSpacing.xl),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 44),
                          Text(
                            'Aviso Vital',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceFloating,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surfaceBorder,
                                ),
                                boxShadow: AppShadows.cardSubtle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: stateSubtle,
                        borderRadius: AppRadius.chip,
                        border: Border.all(color: stateBorder),
                      ),
                      child: Text(
                        chipLabel,
                        style: AppTextStyles.label.copyWith(color: stateColor),
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stateSubtle,
                        border: Border.all(color: stateBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: stateColor.withValues(alpha: 0.12),
                            blurRadius: compact ? 18 : 24,
                            spreadRadius: compact ? 1 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isReadOnly
                            ? Icons.check_circle_rounded
                            : Icons.event_rounded,
                        color: stateColor,
                        size: compact ? 32 : 38,
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                    Text(
                      title,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: titleSize,
                        height: 1.08,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        compact ? AppSpacing.lg : AppSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surfaceFloating,
                            AppColors.surface,
                          ],
                        ),
                        borderRadius: AppRadius.cardLg,
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            cita.especialidad,
                            style: AppTextStyles.h2.copyWith(
                              fontSize: compact ? 23 : 25,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: compact ? AppSpacing.sm : AppSpacing.md,
                          ),
                          _CitaRow(
                            Icons.access_time_rounded,
                            cita.hora,
                            AppColors.orange,
                            grande: true,
                            compact: compact,
                          ),
                          SizedBox(
                            height: compact ? AppSpacing.xs : AppSpacing.sm,
                          ),
                          _CitaRow(
                            Icons.location_on_rounded,
                            cita.lugar,
                            AppColors.textSecondary,
                            compact: compact,
                          ),
                          if (cita.direccion != null) ...[
                            SizedBox(
                              height: compact ? AppSpacing.xs : AppSpacing.sm,
                            ),
                            _CitaRow(
                              Icons.map_outlined,
                              cita.direccion!,
                              AppColors.textTertiary,
                              compact: compact,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                    if (isReadOnly)
                      SecondaryButton(
                        label: context.t.back,
                        icon: Icons.arrow_back_rounded,
                        height: compact ? 48 : 52,
                        onPressed: onClose,
                      )
                    else
                      PrimaryButton(
                        label: context.t.confirmReminder,
                        icon: Icons.thumb_up_alt_rounded,
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.textPrimary,
                        height: compact ? 52 : 56,
                        onPressed: onConfirm,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Vista de confirmación ───────────────────────────────────────────

class _ConfirmadoView extends StatelessWidget {
  const _ConfirmadoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successSubtle,
                border: Border.all(color: AppColors.successBorder, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              context.t.noted,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.success,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.t.appointmentRememberDocuments,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget fila cita ────────────────────────────────────────────────

class _CitaRow extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;
  final bool grande;
  final bool compact;

  const _CitaRow(
    this.icon,
    this.texto,
    this.color, {
    this.grande = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        icon,
        color: color,
        size: grande ? (compact ? 20 : 22) : (compact ? 15 : 16),
      ),
      SizedBox(width: compact ? 6 : 8),
      Flexible(
        child: Text(
          texto,
          style: grande
              ? AppTextStyles.h3.copyWith(
                  color: color,
                  fontSize: compact ? 20 : null,
                )
              : AppTextStyles.body.copyWith(
                  color: color,
                  fontSize: compact ? 15 : null,
                ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
