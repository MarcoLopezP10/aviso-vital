import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/layout/app_detail_scaffold.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class CitaDetalleScreen extends StatefulWidget {
  static const String routeName = AppRoutes.citaDetalle;
  final String citaId;
  const CitaDetalleScreen({super.key, required this.citaId});

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  static const _appointmentsRepository = AppointmentsRepository();
  late final Future<Cita?> _appointmentFuture;

  @override
  void initState() {
    super.initState();
    _appointmentFuture = _appointmentsRepository.fetchById(widget.citaId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cita?>(
      future: _appointmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppDetailScaffold(
            content: Center(child: CircularProgressIndicator()),
            scrollable: false,
          );
        }

        final cita = snapshot.data;
        if (cita == null) {
          return AppDetailScaffold(
            content: Center(
              child: Text(
                context.t.text('Cita no encontrada'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            scrollable: false,
          );
        }
        return _CitaDetalleView(cita: cita);
      },
    );
  }
}

class _CitaDetalleView extends StatelessWidget {
  static const _appointmentsRepository = AppointmentsRepository();
  final Cita cita;
  const _CitaDetalleView({required this.cita});

  @override
  Widget build(BuildContext context) {
    final color = cita.esHoy ? AppColors.orange : AppColors.info;
    return AppDetailScaffold(
      title: context.t.text('Detalle de cita'),
      actions: [
        if (cita.esHoy)
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: StatusBadge.today(),
          ),
      ],
      header: _AppointmentDetailHeader(cita: cita, color: color),
      bottomAction: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: context.t.text('Editar'),
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).pop('edit'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: context.t.text('Eliminar'),
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
              icon: Icons.delete_outline_rounded,
              onPressed: () => ConfirmDialog.show(
                context,
                title: context.t.text('Eliminar cita'),
                message: context.t.isEnglish
                    ? 'Are you sure you want to delete this appointment?'
                    : '¿Seguro que desea eliminar esta cita?',
                confirmLabel: context.t.text('Eliminar'),
                isDestructive: true,
                onConfirm: () async {
                  await _appointmentsRepository.delete(cita.id);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            items: [
              _Row(
                icon: Icons.local_hospital_outlined,
                label: context.t.text('Centro'),
                value: cita.lugar,
              ),
              if (cita.direccion != null)
                _Row(
                  icon: Icons.location_on_outlined,
                  label: context.t.text('Dirección'),
                  value: cita.direccion!,
                ),
              if (cita.telefono != null)
                _Row(
                  icon: Icons.phone_outlined,
                  label: context.t.text('Teléfono'),
                  value: cita.telefono!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.t.text('RECORDATORIOS'),
            style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            items: [
              _Row(
                icon: cita.recordatorio24h
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                label: context.t.text('24 horas antes'),
                value: cita.recordatorio24h
                    ? context.t.text('Activo')
                    : context.t.text('Desactivado'),
                valueColor: cita.recordatorio24h
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
              _Row(
                icon: cita.recordatorio3h
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                label: context.t.text('3 horas antes'),
                value: cita.recordatorio3h
                    ? context.t.text('Activo')
                    : context.t.text('Desactivado'),
                valueColor: cita.recordatorio3h
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ],
          ),
          if (cita.notas != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.t.text('NOTAS'),
              style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                cita.notas!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentDetailHeader extends StatelessWidget {
  final Cita cita;
  final Color color;

  const _AppointmentDetailHeader({required this.cita, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_rounded, color: color, size: 48),
          const SizedBox(height: 14),
          Text(
            cita.especialidad,
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t.isEnglish
                ? '${context.t.month(cita.fecha.month)} ${cita.fecha.day} · ${cita.hora}'
                : '${cita.fecha.day} de ${context.t.month(cita.fecha.month)} · ${cita.hora}',
            style: AppTextStyles.h3.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_Row> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.card,
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Column(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Column(
              children: [
                e.value,
                if (e.key < items.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.label)),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(color: valueColor),
        ),
      ],
    ),
  );
}
