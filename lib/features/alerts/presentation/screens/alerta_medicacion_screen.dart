import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/care_plan_context_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
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

  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
        content: Text('Se lo recordaremos de nuevo en 10 minutos'),
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

              final data = snapshot.data;
              if (data == null) {
                return const Center(
                  child: Text('No hay medicación pendiente.'),
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
                        onClose: () => Navigator.maybePop(context),
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
      med = await _medicationsRepository.fetchUpcoming(userId: ownerId);
      if (med != null) {
        dose = await _medicationsRepository.fetchUpcomingDoseForMedication(
          med.id,
          userId: ownerId,
        );
      }
    }

    if (med == null || dose == null) return null;

    final currentHour = _formatHora(DateTime.now());

    return _MedicationAlertData(
      dose: dose,
      medication: med,
      currentHour: currentHour,
      nextDoseLabel: _nextDoseLabel(med, currentHour),
      userFirstName:
          (contextData.careRecipientProfile ?? contextData.viewerProfile)
              ?.nombre
              .split(' ')
              .first ??
          '',
    );
  }

  String _nextDoseLabel(Medicamento medication, String currentHour) {
    final horas = _expandedHours(medication);
    if (horas.isEmpty) return '--:--';
    final current = _minutesForHour(currentHour);
    final ordered = horas.toList()
      ..sort((a, b) => _minutesForHour(a) - _minutesForHour(b));
    for (final hour in ordered) {
      if (_minutesForHour(hour) > current) return hour;
    }
    return ordered.first;
  }

  int _minutesForHour(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  List<String> _expandedHours(Medicamento medication) {
    final baseHours = medication.horasToma
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (baseHours.isEmpty) return const <String>[];

    final shouldExpand =
        (medication.frecuencia == FrecuenciaMed.cada8h ||
            medication.frecuencia == FrecuenciaMed.cada12h) &&
        baseHours.length == 1;

    if (!shouldExpand) return baseHours;

    final interval = medication.frecuencia == FrecuenciaMed.cada8h ? 8 : 12;
    final startMinutes = _minutesForHour(baseHours.first);
    final values = <String>[];
    for (var offset = 0; offset < 24 * 60; offset += interval * 60) {
      final totalMinutes = startMinutes + offset;
      if (totalMinutes >= 24 * 60) break;
      values.add(
        '${(totalMinutes ~/ 60).toString().padLeft(2, '0')}:${(totalMinutes % 60).toString().padLeft(2, '0')}',
      );
    }
    return values;
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

class _MedicationAlertView extends StatelessWidget {
  final Medicamento med;
  final String horaActual;
  final String nextDose;
  final String userFirstName;
  final Animation<double> pulseAnim;
  final bool pospuesto;
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
        final titleSize = veryCompact ? 25.0 : (compact ? 28.0 : 34.0);
        final sectionGap = veryCompact
            ? AppSpacing.lg
            : (compact ? AppSpacing.xl : AppSpacing.xxl);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            veryCompact
                ? AppSpacing.sm
                : (compact ? AppSpacing.md : AppSpacing.lg),
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
                    _AlertTopBar(onClose: onClose),
                    SizedBox(
                      height: veryCompact
                          ? AppSpacing.sm
                          : (compact ? AppSpacing.md : AppSpacing.xl),
                    ),
                    _GlowHeaderIcon(
                      pulseAnim: pulseAnim,
                      color: AppColors.amberLight,
                      shape: _toFormShape(med.formaPastilla),
                      compact: compact,
                    ),
                    SizedBox(
                      height: veryCompact
                          ? AppSpacing.md
                          : (compact ? AppSpacing.lg : AppSpacing.xl),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amberSubtle.withValues(alpha: 0.82),
                        borderRadius: AppRadius.chip,
                        border: Border.all(color: AppColors.amberBorder),
                      ),
                      child: Text(
                        'Recordatorio de medicación',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amberLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: veryCompact ? AppSpacing.md : AppSpacing.lg,
                    ),
                    Text(
                      '$userFirstName, es hora\nde su medicación',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: titleSize,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Vaya paso a paso. Revise su medicación y confirme cuando la haya tomado.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.38,
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _MedicationAlertCard(
                      med: med,
                      horaActual: horaActual,
                      compact: compact,
                    ),
                    SizedBox(height: sectionGap),
                    _PrimaryAlertButton(
                      onPressed: onConfirm,
                      label: 'Ya la he tomado',
                      compact: compact,
                    ),
                    SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                    _SecondarySnoozeButton(
                      onPressed: pospuesto ? null : onSnooze,
                      label: pospuesto
                          ? 'Recordatorio en 10 min'
                          : 'Recordármelo en 10 min',
                      compact: compact,
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                    Text(
                      'Siguiente toma a las $nextDose',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.35,
                      ),
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

class _AlertTopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _AlertTopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
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
            width: 44,
            height: 44,
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
    final outerSize = compact ? 116.0 : 136.0;
    final innerSize = compact ? 82.0 : 96.0;
    final pillSize = compact ? 32.0 : 36.0;

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
                  blurRadius: 18,
                  offset: const Offset(0, 10),
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
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.amberLight,
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
            med.dosis,
            style: AppTextStyles.userMedDose.copyWith(
              fontSize: compact ? 22 : 26,
              color: AppColors.amberLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _CardInfoRow(
            icon: Icons.water_drop_outlined,
            text: med.instrucciones ?? 'Tómela con agua',
            compact: compact,
          ),
          if (med.frecuencia.label.isNotEmpty) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            _CardInfoRow(
              icon: Icons.repeat_rounded,
              text: med.frecuencia.label,
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
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorderSoft),
          ),
          child: Icon(
            icon,
            color: AppColors.amberLight,
            size: compact ? 16 : 18,
          ),
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontSize: compact ? 17 : null,
              fontWeight: subtle ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAlertButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
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
      height: compact ? 64 : 78,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
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
            fontSize: compact ? 20 : 24,
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
      height: compact ? 56 : 64,
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
            fontSize: compact ? 16 : 18,
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
