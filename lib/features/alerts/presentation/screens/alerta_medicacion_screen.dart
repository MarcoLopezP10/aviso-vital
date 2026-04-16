import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

/// Pantalla: Alerta de Medicación — flujo principal de Carmen
/// Rediseñada para máxima claridad, contraste y foco táctil.
class AlertaMedicacionScreen extends StatefulWidget {
  static const String routeName = AppRoutes.alertaMedicacion;
  final String? doseId;

  const AlertaMedicacionScreen({super.key, this.doseId});

  @override
  State<AlertaMedicacionScreen> createState() => _AlertaMedicacionScreenState();
}

class _AlertaMedicacionScreenState extends State<AlertaMedicacionScreen>
    with SingleTickerProviderStateMixin {
  static const _medicationsRepository = MedicationsRepository();
  static const _carePlanContextService = CarePlanContextService();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late Future<_MedicationAlertData?> _alertFuture;
  bool _confirmado = false;
  bool _pospuesto = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: AppDurations.pulse)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _alertFuture = _loadAlertData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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

  Future<void> _confirmar(_MedicationAlertData data) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _medicationsRepository.confirmDose(data.dose.id);
    _pulseCtrl.stop();
    setState(() {
      _confirmado = true;
      _isSubmitting = false;
    });
    Future.delayed(AppDurations.success, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _posponer(_MedicationAlertData data) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _medicationsRepository.snoozeDose(data.dose.id);
    if (!mounted) return;
    setState(() {
      _pospuesto = true;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se lo recordaremos de nuevo en 15 minutos'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: PremiumScreenScaffold(
        variant: PremiumBackgroundVariant.focus,
        primaryGlowColor: AppColors.amber,
        secondaryGlowColor: AppColors.haloBlue,
        primaryGlowAlignment: const Alignment(0, -0.56),
        secondaryGlowAlignment: const Alignment(0.88, 0.92),
        intensity: 0.72,
        body: SafeArea(
          child: FutureBuilder<_MedicationAlertData?>(
            future: _alertFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _AlertUnavailableView(
                  message:
                      'No se pudo cargar la medicación pendiente. ${snapshot.error}',
                  onBack: _handleBack,
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return _AlertUnavailableView(
                  message: 'No hay medicación pendiente.',
                  onBack: _handleBack,
                );
              }

              return AnimatedSwitcher(
                duration: AppDurations.normal,
                child: _confirmado
                    ? const _ConfirmedMedicationView(key: ValueKey('confirmed'))
                    : _MedicationAlertView(
                        key: const ValueKey('alert'),
                        med: data.medication,
                        horaActual: data.currentHour,
                        nextDose: data.nextDoseLabel,
                        userFirstName: data.userFirstName,
                        pulseAnim: _pulseAnim,
                        pospuesto: _pospuesto,
                        isSubmitting: _isSubmitting,
                        onClose: _handleBack,
                        onConfirm: () => _confirmar(data),
                        onSnooze: () => _posponer(data),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_MedicationAlertData?> _loadAlertData() async {
    final contextData = await _carePlanContextService.resolve();
    final ownerId = contextData.ownerUserId;
    Toma? dose;
    Medicamento? med;

    if (widget.doseId != null && widget.doseId!.isNotEmpty) {
      dose = await _medicationsRepository.fetchDoseById(widget.doseId!);
      if (dose != null) {
        med = await _medicationsRepository.fetchById(dose.idMedicamento);
      }
    } else {
      final snapshot = await _medicationsRepository.fetchDailySnapshot(
        userId: ownerId,
      );
      med = snapshot.upcomingMedication;
      if (med != null) {
        final pendingDoses = snapshot.doses
            .where((item) => item.idMedicamento == med!.id)
            .where(
              (item) =>
                  item.estado == EstadoToma.pendiente ||
                  item.estado == EstadoToma.pospuesta,
            )
            .toList(growable: false);
        pendingDoses.sort(
          (a, b) => a.fechaProgramada.compareTo(b.fechaProgramada),
        );
        dose = pendingDoses.firstOrNull;
      }
    }

    if (med == null || dose == null) return null;

    final currentHour = formatAlertHour(DateTime.now());

    final now = DateTime.now();
    return _MedicationAlertData(
      dose: dose,
      medication: med,
      currentHour: currentHour,
      nextDoseLabel: _formatNextDose(_nextDoseDatetime(med, now), now),
      userFirstName:
          (contextData.careRecipientProfile ?? contextData.viewerProfile)
              ?.nombre
              .split(' ')
              .first ??
          '',
    );
  }

  /// Finds the next scheduled DateTime for [medication] after [from].
  DateTime? _nextDoseDatetime(Medicamento medication, DateTime from) {
    final horas =
        medication.horasToma
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty)
            .toList(growable: true)
          ..sort((a, b) => _minutesForHour(a) - _minutesForHour(b));
    if (horas.isEmpty) return null;

    final fromMinutes = from.hour * 60 + from.minute;
    final today = DateTime(from.year, from.month, from.day);

    // Remaining hours today (only if today is a scheduled day)
    if (_shouldTakeOnDay(medication, from)) {
      for (final hour in horas) {
        if (_minutesForHour(hour) > fromMinutes) {
          return _dateForHour(today, hour);
        }
      }
    }

    // Search up to 14 days ahead
    for (var i = 1; i <= 14; i++) {
      final candidate = from.add(Duration(days: i));
      if (_shouldTakeOnDay(medication, candidate)) {
        return _dateForHour(
          DateTime(candidate.year, candidate.month, candidate.day),
          horas.first,
        );
      }
    }

    return null;
  }

  bool _shouldTakeOnDay(Medicamento medication, DateTime date) {
    return switch (medication.frecuencia) {
      FrecuenciaMed.diasSemana =>
        medication.diasSemana.isEmpty
            ? true
            : medication.diasSemana.contains(date.weekday),
      FrecuenciaMed.cadaDias => () {
        if (medication.intervaloDias <= 1) return true;
        final anchor = DateTime(
          medication.fechaCreacion.year,
          medication.fechaCreacion.month,
          medication.fechaCreacion.day,
        );
        final target = DateTime(date.year, date.month, date.day);
        final diff = target.difference(anchor).inDays;
        return diff >= 0 && diff % medication.intervaloDias == 0;
      }(),
      _ => true,
    };
  }

  String _formatNextDose(DateTime? next, DateTime now) {
    if (next == null) return '--:--';
    final hourStr =
        '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
    final isToday =
        next.year == now.year && next.month == now.month && next.day == now.day;
    if (isToday) return 'Hoy a las $hourStr';
    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return '${weekdays[next.weekday - 1]} ${next.day} a las $hourStr';
  }

  DateTime _dateForHour(DateTime date, String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.firstOrNull ?? '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int _minutesForHour(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }
}

class _MedicationAlertData {
  final Toma dose;
  final Medicamento medication;
  final String currentHour;
  final String nextDoseLabel;
  final String userFirstName;

  const _MedicationAlertData({
    required this.dose,
    required this.medication,
    required this.currentHour,
    required this.nextDoseLabel,
    required this.userFirstName,
  });
}

class _AlertUnavailableView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _AlertUnavailableView({required this.message, required this.onBack});

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
                    Icons.medication_outlined,
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
                    label: 'Volver',
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

class _MedicationAlertView extends StatelessWidget {
  final Medicamento med;
  final String horaActual;
  final String nextDose;
  final String userFirstName;
  final Animation<double> pulseAnim;
  final bool pospuesto;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  final VoidCallback onSnooze;

  const _MedicationAlertView({
    super.key,
    required this.med,
    required this.horaActual,
    required this.nextDose,
    required this.userFirstName,
    required this.pulseAnim,
    this.pospuesto = false,
    this.isSubmitting = false,
    required this.onClose,
    required this.onConfirm,
    required this.onSnooze,
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
        final titleSize = veryCompact ? 24.0 : (compact ? 28.0 : 32.0);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  veryCompact ? AppSpacing.sm : AppSpacing.md,
                  horizontalPadding,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AlertTopBar(onClose: onClose),
                        SizedBox(height: veryCompact ? 10 : 14),
                        _GlowHeaderIcon(
                          pulseAnim: pulseAnim,
                          color: AppColors.amberLight,
                          shape: _toFormShape(med.formaPastilla),
                          compact: true,
                        ),
                        const SizedBox(height: 14),
                        _MedicationDetailHeader(
                          userFirstName: userFirstName,
                          titleSize: titleSize,
                        ),
                        const SizedBox(height: 16),
                        _MedicationAlertCard(
                          med: med,
                          horaActual: horaActual,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sm,
                  horizontalPadding,
                  AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _MedicationBottomActions(
                    medication: med,
                    nextDose: nextDose,
                    compact: compact,
                    isSubmitting: isSubmitting,
                    pospuesto: pospuesto,
                    onConfirm: onConfirm,
                    onSnooze: onSnooze,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertTopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _AlertTopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Text(
            'Aviso Vital',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceFloating.withValues(alpha: 0.92),
              shape: BoxShape.circle,
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
      ],
    );
  }
}

class _GlowHeaderIcon extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Color color;
  final FormShape shape;
  final bool compact;

  const _GlowHeaderIcon({
    required this.pulseAnim,
    required this.color,
    required this.shape,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final outerSize = compact ? 94.0 : 116.0;
    final innerSize = compact ? 68.0 : 82.0;
    final pillSize = compact ? 28.0 : 32.0;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) =>
          Transform.scale(scale: pulseAnim.value, child: child),
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: RadialGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.12),
              AppColors.amber.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceElevated, AppColors.surfaceStrong],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: compact ? 12 : 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: PillVisual(
                color: color,
                shape: shape,
                size: pillSize,
                showGlow: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationDetailHeader extends StatelessWidget {
  final String userFirstName;
  final double titleSize;

  const _MedicationDetailHeader({
    required this.userFirstName,
    required this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.amberSubtle.withValues(alpha: 0.9),
            borderRadius: AppRadius.chip,
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: Text(
            'Recordatorio de medicación',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.amberLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$userFirstName, es hora de su medicación',
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(
            fontSize: titleSize,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Revise la toma con calma y confirme cuando la haya tomado.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: const Color(0xFFABABAB),
            fontSize: 16,
            height: 1.32,
          ),
        ),
      ],
    );
  }
}

class _MedicationAlertCard extends StatelessWidget {
  final Medicamento med;
  final String horaActual;
  final bool compact;

  const _MedicationAlertCard({
    required this.med,
    required this.horaActual,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surfaceStrong],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surfaceBorderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberSubtle.withValues(alpha: 0.82),
                  borderRadius: AppRadius.chip,
                  border: Border.all(color: AppColors.amberBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.amberLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      horaActual,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.amberLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            med.nombre,
            style: AppTextStyles.userMedName.copyWith(
              fontSize: compact ? 26 : 30,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatMedicationDose(med.dosis),
            style: AppTextStyles.userMedDose.copyWith(
              fontSize: 22,
              color: AppColors.amberLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _CardInfoRow(
            icon: Icons.water_drop_outlined,
            text: med.instrucciones ?? 'Tómela con agua',
            compact: compact,
          ),
          if (med.resumenTomas.isNotEmpty) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            _CardInfoRow(
              icon: Icons.repeat_rounded,
              text: med.resumenTomas,
              subtle: true,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool subtle;
  final bool compact;

  const _CardInfoRow({
    required this.icon,
    required this.text,
    this.subtle = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = subtle ? AppColors.textSecondary : AppColors.textPrimary;

    return Row(
      children: [
        Container(
          width: compact ? 36 : 40,
          height: compact ? 36 : 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(
            icon,
            color: AppColors.amberLight,
            size: compact ? 18 : 20,
          ),
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: subtle ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationBottomActions extends StatelessWidget {
  final Medicamento medication;
  final String nextDose;
  final bool compact;
  final bool isSubmitting;
  final bool pospuesto;
  final VoidCallback onConfirm;
  final VoidCallback onSnooze;

  const _MedicationBottomActions({
    required this.medication,
    required this.nextDose,
    required this.compact,
    required this.isSubmitting,
    required this.pospuesto,
    required this.onConfirm,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryAlertButton(
            onPressed: isSubmitting ? null : onConfirm,
            label: isSubmitting ? 'Guardando...' : 'Ya la he tomado',
            compact: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SecondarySnoozeButton(
            onPressed: isSubmitting || pospuesto ? null : onSnooze,
            label: pospuesto
                ? 'Recordatorio en 10 min'
                : 'Recordármelo en 10 min',
            compact: compact,
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              Text(
                nextDose == '--:--'
                    ? 'Sin tomas programadas'
                    : 'Siguiente: $nextDose',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(
                  color: const Color(0xFFABABAB),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${medication.nombre} · ${medication.dosis}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryAlertButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  const _PrimaryAlertButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 56 : 64,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          disabledBackgroundColor: AppColors.amber.withValues(alpha: 0.45),
          foregroundColor: AppColors.textOnAmber,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
          ),
          shadowColor: AppColors.amber.withValues(alpha: 0.16),
        ),
        icon: Icon(Icons.check_circle_rounded, size: compact ? 24 : 28),
        label: Text(
          label,
          style: AppTextStyles.buttonLarge.copyWith(
            fontSize: compact ? 18 : 22,
            color: AppColors.textOnAmber,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SecondarySnoozeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  const _SecondarySnoozeButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 52 : 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceStrong.withValues(alpha: 0.94),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceBorderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        icon: Icon(
          Icons.schedule_rounded,
          size: compact ? 20 : 22,
          color: AppColors.textSecondary,
        ),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ConfirmedMedicationView extends StatelessWidget {
  const _ConfirmedMedicationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successSubtle,
                border: Border.all(color: AppColors.successBorder),
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
                size: 58,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Perfecto',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.success,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La toma ha quedado registrada.\nPuedes continuar con tranquilidad.',
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

FormShape _toFormShape(FormaPastilla shape) => switch (shape) {
  FormaPastilla.redonda => FormShape.round,
  FormaPastilla.ovalada => FormShape.oval,
  FormaPastilla.capsula => FormShape.capsule,
};
