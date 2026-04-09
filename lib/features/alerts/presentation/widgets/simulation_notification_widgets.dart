import 'package:aviso_vital_2/core/services/realtime_simulation_service.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/alert_formatters.dart';
import 'package:flutter/material.dart';

const Color _cardBackground = Color(0xFF1E1E24);
const Color _cardBorder = Color(0x14FFFFFF);
const Color _primaryText = Color(0xFFFFFFFF);
const Color _secondaryText = Color(0xFFABABAB);
const Color _medicationAccent = Color(0xFFF5C518);
const Color _appointmentAccent = Color(0xFFFF6B35);

class SimulationNotificationCard extends StatelessWidget {
  final LiveNotificationItem item;
  final VoidCallback onTap;

  const SimulationNotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.type == LiveNotificationType.medication
        ? _medicationAccent
        : _appointmentAccent;
    final icon = item.type == LiveNotificationType.medication
        ? Icons.medication_rounded
        : Icons.event_rounded;

    return Semantics(
      button: true,
      label: item.title,
      hint: item.actionLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: EdgeInsets.all(item.compactReminder ? 12 : 16),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
            ),
            child: item.compactReminder
                ? _CollapsedAppointmentRow(
                    accent: accent,
                    icon: icon,
                    title: item.title,
                    hour: item.leadingLabel,
                  )
                : _ExpandedNotificationContent(
                    item: item,
                    accent: accent,
                    icon: icon,
                  ),
          ),
        ),
      ),
    );
  }
}

class SimulationNotificationActionBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const SimulationNotificationActionBadge({
    super.key,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: accent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _ExpandedNotificationContent extends StatelessWidget {
  final LiveNotificationItem item;
  final Color accent;
  final IconData icon;

  const _ExpandedNotificationContent({
    required this.item,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final eyebrow = item.type == LiveNotificationType.medication
        ? 'Aviso Vital · Medicación'
        : 'Aviso Vital · Cita médica';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(accent: accent, icon: icon, compact: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eyebrow,
                style: AppTextStyles.labelLarge.copyWith(
                  color: _secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item.leadingLabel,
              style: AppTextStyles.labelLarge.copyWith(
                color: _secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              item.title,
              style: AppTextStyles.h1.copyWith(
                color: _primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            if ((item.keyValue ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.keyValue!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: _secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Expira a las ${formatAlertHour(item.expiresAt)}',
                style: AppTextStyles.body.copyWith(
                  color: _secondaryText,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SimulationNotificationActionBadge(
              label: item.actionLabel,
              accent: accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _CollapsedAppointmentRow extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String hour;

  const _CollapsedAppointmentRow({
    required this.accent,
    required this.icon,
    required this.title,
    required this.hour,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NotificationIcon(accent: accent, icon: icon, compact: true),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h2.copyWith(
              color: _primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          hour,
          style: AppTextStyles.labelLarge.copyWith(
            color: _secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final bool compact;

  const _NotificationIcon({
    required this.accent,
    required this.icon,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 40 : 44,
      height: compact ? 40 : 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 14 : 15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: accent, size: compact ? 20 : 22),
    );
  }
}
