import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:aviso_vital_2/core/services/realtime_simulation_service.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';
import 'package:aviso_vital_2/shared/widgets/aviso_vital_logo.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

const Color _notificationBackground = Color(0xFF22232B);
const Color _medicationAccent = Color(0xFFFFC107);
const Color _appointmentAccent = Color(0xFFFF6A00);

class SimulationNotificationCard extends StatefulWidget {
  final LiveNotificationItem item;
  final Future<void> Function() onTap;

  const SimulationNotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<SimulationNotificationCard> createState() =>
      _SimulationNotificationCardState();
}

class _SimulationNotificationCardState extends State<SimulationNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    final curve = CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(begin: 1, end: 0.96).animate(curve);
    _fade = Tween<double>(begin: 1, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_tapController.isAnimating) return;
    await _tapController.forward(from: 0);
    await widget.onTap();
    if (mounted) _tapController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = item.type == LiveNotificationType.medication
        ? _medicationAccent
        : _appointmentAccent;
    final actionLabel = item.type == LiveNotificationType.medication
        ? context.t.viewReminder
        : context.t.viewAppointment;
    final title = _titleFor(item);

    if (item.compactReminder) {
      return Semantics(
        button: true,
        label: title,
        hint: actionLabel,
        child: GestureDetector(
          onTap: _handleTap,
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: _CompactAppointmentReminder(item: item, accent: accent),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: title,
      hint: actionLabel,
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _fade,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _notificationBackground.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _NotificationHeader(),
                      _NotificationBody(item: item, accent: accent),
                      _NotificationActionBar(
                        label: actionLabel,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactAppointmentReminder extends StatelessWidget {
  final LiveNotificationItem item;
  final Color accent;

  const _CompactAppointmentReminder({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(item);
    final time = item.appointment?.hora.trim().isNotEmpty == true
        ? item.appointment!.hora.trim()
        : item.leadingLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _notificationBackground.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: accent.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              const AvisoVitalAppIcon(size: 24, borderRadius: 6),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 30,
                constraints: const BoxConstraints(minWidth: 56),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Text(
                  time,
                  maxLines: 1,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 6),
      child: Row(
        children: [
          const _NotificationAppIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AVISO VITAL',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            context.t.now.toLowerCase(),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _NotificationAppIcon extends StatelessWidget {
  const _NotificationAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A00),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const AvisoVitalAppIcon(size: 20, borderRadius: 5),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  final LiveNotificationItem item;
  final Color accent;

  const _NotificationBody({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isMedication = item.type == LiveNotificationType.medication;
    final location = item.appointment?.lugar.trim() ?? '';
    final title = _titleFor(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 98),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isMedication
                    ? _MedicationVisualIcon(item: item, accent: accent)
                    : _AppointmentVisualIcon(accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AdaptiveNotificationText(
                        title,
                        maxFontSize: isMedication ? 25 : 24,
                        minFontSize: isMedication ? 19 : 17,
                        maxLines: isMedication ? 2 : 1,
                        baseStyle: AppTextStyles.h4.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w800,
                          height: 1.04,
                          letterSpacing: 0,
                        ),
                      ),
                      if (!isMedication && location.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _PlaceLabel(place: location),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMedication ? 9 : 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMedication)
                  Expanded(child: _ExpiryLabel(expiresAt: item.expiresAt))
                else
                  const Spacer(),
                const SizedBox(width: 10),
                _LargeHourLabel(label: item.leadingLabel, accent: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveNotificationText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final double maxFontSize;
  final double minFontSize;
  final int maxLines;

  const _AdaptiveNotificationText(
    this.text, {
    required this.baseStyle,
    required this.maxFontSize,
    required this.minFontSize,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final direction = Directionality.of(context);
        var fontSize = maxFontSize;

        if (maxWidth.isFinite && maxWidth > 0) {
          for (var size = maxFontSize; size >= minFontSize; size -= 0.5) {
            final painter = TextPainter(
              text: TextSpan(
                text: text,
                style: baseStyle.copyWith(fontSize: size),
              ),
              maxLines: maxLines,
              textDirection: direction,
            )..layout(maxWidth: maxWidth);

            if (!painter.didExceedMaxLines) {
              fontSize = size;
              break;
            }

            fontSize = minFontSize;
          }
        }

        return Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(fontSize: fontSize),
        );
      },
    );
  }
}

class _ExpiryLabel extends StatelessWidget {
  final DateTime expiresAt;

  const _ExpiryLabel({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.t.expiresAt(formatAlertHour(expiresAt)),
      style: AppTextStyles.caption.copyWith(
        color: Colors.white.withValues(alpha: 0.34),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }
}

class _PlaceLabel extends StatelessWidget {
  final String place;

  const _PlaceLabel({required this.place});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_rounded,
          color: Colors.white.withValues(alpha: 0.52),
          size: 17,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: _AdaptiveNotificationText(
            place,
            maxFontSize: 16,
            minFontSize: 13,
            maxLines: 1,
            baseStyle: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

class _LargeHourLabel extends StatelessWidget {
  final String label;
  final Color accent;

  const _LargeHourLabel({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: AppTextStyles.h3.copyWith(
          color: accent,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MedicationVisualIcon extends StatelessWidget {
  final LiveNotificationItem item;
  final Color accent;

  const _MedicationVisualIcon({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final medication = item.medication;
    final shape = _toFormShape(medication?.formaPastilla);
    final pillSize = shape == FormShape.capsule ? 25.0 : 30.0;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: PillVisual(
          color: medication?.colorPastilla ?? AppColors.amber,
          shape: shape,
          size: pillSize,
        ),
      ),
    );
  }
}

class _AppointmentVisualIcon extends StatelessWidget {
  final Color accent;

  const _AppointmentVisualIcon({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Icon(Icons.calendar_month_outlined, color: accent, size: 30),
    );
  }
}

class _NotificationActionBar extends StatelessWidget {
  final String label;
  final Color accent;

  const _NotificationActionBar({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 38),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.2))),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelLarge.copyWith(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _titleFor(LiveNotificationItem item) {
  if (item.type == LiveNotificationType.appointment) {
    final specialty = item.appointment?.especialidad.trim();
    if (specialty != null && specialty.isNotEmpty) {
      return specialty;
    }
    return item.title;
  }

  return item.title;
}

FormShape _toFormShape(FormaPastilla? shape) => switch (shape) {
  FormaPastilla.ovalada => FormShape.oval,
  FormaPastilla.capsula => FormShape.capsule,
  _ => FormShape.round,
};
