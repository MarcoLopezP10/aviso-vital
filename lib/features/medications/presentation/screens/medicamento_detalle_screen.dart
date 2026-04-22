import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/layout/app_detail_scaffold.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class MedicamentoDetalleScreen extends StatefulWidget {
  static const String routeName = AppRoutes.medicamentoDetalle;
  final String medicamentoId;
  const MedicamentoDetalleScreen({super.key, required this.medicamentoId});

  @override
  State<MedicamentoDetalleScreen> createState() =>
      _MedicamentoDetalleScreenState();
}

class _MedicamentoDetalleScreenState extends State<MedicamentoDetalleScreen> {
  static const _medicationsRepository = MedicationsRepository();
  late final Future<Medicamento?> _medicationFuture;

  @override
  void initState() {
    super.initState();
    _medicationFuture = _medicationsRepository.fetchById(widget.medicamentoId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Medicamento?>(
      future: _medicationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppDetailScaffold(
            content: Center(child: CircularProgressIndicator()),
            scrollable: false,
          );
        }

        final med = snapshot.data;
        if (med == null) {
          return AppDetailScaffold(
            content: Center(
              child: Text(
                context.t.text('Medicamento no encontrado'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            scrollable: false,
          );
        }

        return _MedicamentoDetalleView(medicamento: med);
      },
    );
  }
}

class _MedicamentoDetalleView extends StatelessWidget {
  static const _medicationsRepository = MedicationsRepository();
  final Medicamento medicamento;
  const _MedicamentoDetalleView({required this.medicamento});

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      header: _MedicationDetailHero(medicamento: medicamento),
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
                title: context.t.text('Eliminar medicamento'),
                message: context.t.medicationDeleteDetailMessage(
                  medicamento.nombre,
                ),
                confirmLabel: context.t.text('Eliminar'),
                isDestructive: true,
                onConfirm: () async {
                  await _medicationsRepository.delete(medicamento.id);
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
          Row(
            children: [
              Expanded(
                child: Text(medicamento.nombre, style: AppTextStyles.h1),
              ),
              if (medicamento.stockBajo) StatusBadge.lowStock(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            medicamento.dosis,
            style: AppTextStyles.h3.copyWith(color: AppColors.amber),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _InfoSection(
            title: context.t.text('Información'),
            items: [
              _InfoItem(
                label: context.t.text('Tomas'),
                value: medicamento.resumenTomas,
              ),
              _InfoItem(
                label: context.t.text('Patrón'),
                value: _frecuenciaLabel(context, medicamento),
              ),
              _InfoItem(
                label: context.t.text('Horario'),
                value: medicamento.horasToma.isEmpty
                    ? '—'
                    : medicamento.horasToma.join(' · '),
              ),
              if (medicamento.instrucciones != null)
                _InfoItem(
                  label: context.t.text('Instrucciones'),
                  value: medicamento.instrucciones!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _StockSection(medicamento: medicamento),
          const SizedBox(height: AppSpacing.xl),
          if (medicamento.notas != null) ...[
            _InfoSection(
              title: context.t.text('Notas'),
              items: [_InfoItem(label: '', value: medicamento.notas!)],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          _InfoSection(
            title: context.t.text('Registro'),
            items: [
              _InfoItem(
                label: context.t.text('Añadido'),
                value: _formatDate(medicamento.fechaCreacion),
              ),
              if (medicamento.ultimaEdicion != null)
                _InfoItem(
                  label: context.t.text('Última edición'),
                  value: _formatDate(medicamento.ultimaEdicion!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => AppStrings.current.shortNumericDate(dt);

  String _frecuenciaLabel(BuildContext context, Medicamento med) {
    return switch (med.frecuencia) {
      FrecuenciaMed.cadaDias => context.t.everyDays(med.intervaloDias),
      FrecuenciaMed.diasSemana =>
        med.diasSemana.isEmpty
            ? context.t.text('Días específicos')
            : _diasSemanaLabel(context, med.diasSemana),
      _ => context.t.text(med.frecuencia.label),
    };
  }

  String _diasSemanaLabel(BuildContext context, List<int> days) {
    final sorted = List<int>.from(days)..sort();
    return sorted.map(context.t.shortWeekday).join(' · ');
  }
}

class _MedicationDetailHero extends StatelessWidget {
  final Medicamento medicamento;

  const _MedicationDetailHero({required this.medicamento});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            medicamento.colorPastilla.withValues(alpha: 0.15),
            AppColors.background,
          ],
        ),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorderSoft),
      ),
      child: Center(
        child: PillVisual(
          color: medicamento.colorPastilla,
          shape: _toFormShape(medicamento.formaPastilla),
          size: 80,
          showGlow: true,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.overline.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

FormShape _toFormShape(FormaPastilla shape) => switch (shape) {
  FormaPastilla.redonda => FormShape.round,
  FormaPastilla.ovalada => FormShape.oval,
  FormaPastilla.capsula => FormShape.capsule,
};

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          value,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _StockSection extends StatelessWidget {
  final Medicamento medicamento;
  const _StockSection({required this.medicamento});

  @override
  Widget build(BuildContext context) {
    final ratio = (medicamento.stockActual / (medicamento.stockMinimo * 4))
        .clamp(0.0, 1.0);
    final color = medicamento.stockBajo ? AppColors.danger : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.text('STOCK'),
          style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: AppRadius.card,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.t.units(medicamento.stockActual),
                    style: AppTextStyles.h3,
                  ),
                  Text(
                    context.t.minimumStock(medicamento.stockMinimo),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadius.chip,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              if (medicamento.stockBajo) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.t.text('Stock bajo — recuerda reponerlo pronto'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
