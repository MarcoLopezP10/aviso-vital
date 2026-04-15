import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
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
          return const AppDetailScaffold(
            content: Center(
              child: Text(
                'Medicamento no encontrado',
                style: TextStyle(color: Colors.white),
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
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).pop('edit'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: 'Eliminar',
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
              icon: Icons.delete_outline_rounded,
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Eliminar medicamento',
                message:
                    '¿Seguro que desea eliminar ${medicamento.nombre}? Esta acción no se puede deshacer.',
                confirmLabel: 'Eliminar',
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
            title: 'Información',
            items: [
              _InfoItem(label: 'Tomas al dia', value: medicamento.resumenTomas),
              _InfoItem(
                label: 'Horario',
                value: medicamento.horasToma.join(' · '),
              ),
              if (medicamento.instrucciones != null)
                _InfoItem(
                  label: 'Instrucciones',
                  value: medicamento.instrucciones!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _StockSection(medicamento: medicamento),
          const SizedBox(height: AppSpacing.xl),
          if (medicamento.notas != null) ...[
            _InfoSection(
              title: 'Notas',
              items: [_InfoItem(label: '', value: medicamento.notas!)],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          _InfoSection(
            title: 'Registro',
            items: [
              _InfoItem(
                label: 'Añadido',
                value: _formatDate(medicamento.fechaCreacion),
              ),
              if (medicamento.ultimaEdicion != null)
                _InfoItem(
                  label: 'Última edición',
                  value: _formatDate(medicamento.ultimaEdicion!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
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
          'STOCK',
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
                    '${medicamento.stockActual} unidades',
                    style: AppTextStyles.h3,
                  ),
                  Text(
                    'Mínimo: ${medicamento.stockMinimo}',
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
                      'Stock bajo — recuerda reponerlo pronto',
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
