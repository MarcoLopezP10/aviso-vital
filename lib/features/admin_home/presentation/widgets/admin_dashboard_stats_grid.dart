import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminDashboardStatsGrid extends StatelessWidget {
  final ResumenAdherencia adherencia;
  final int stockBajoCount;
  final Cita? citaHoy;
  final int pendientesHoy;

  const AdminDashboardStatsGrid({
    super.key,
    required this.adherencia,
    required this.stockBajoCount,
    required this.citaHoy,
    required this.pendientesHoy,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (adherencia.adherencia * 100).round();
    final adherenciaColor = pct >= 80
        ? AppColors.success
        : (pct >= 50 ? AppColors.warning : AppColors.danger);

    final cards = [
      SummaryStatCard(
        title: 'Adherencia',
        value: '$pct%',
        icon: Icons.trending_up_rounded,
        color: adherenciaColor,
        subtitle: 'Hoy',
      ),
      SummaryStatCard(
        title: 'Pendientes hoy',
        value: '$pendientesHoy',
        icon: Icons.schedule_rounded,
        color: AppColors.orange,
        subtitle: pendientesHoy > 0 ? 'Sin confirmar' : 'En orden',
      ),
      SummaryStatCard(
        title: 'Stock bajo',
        value: '$stockBajoCount',
        icon: Icons.warning_amber_rounded,
        color: stockBajoCount > 0 ? AppColors.danger : AppColors.success,
        subtitle: stockBajoCount > 0 ? 'Reposición' : 'Correcto',
      ),
      SummaryStatCard(
        title: 'Cita hoy',
        value: citaHoy != null ? citaHoy!.hora : '—',
        icon: Icons.event_rounded,
        color: citaHoy != null ? AppColors.info : AppColors.textTertiary,
        subtitle: citaHoy?.especialidad ?? 'Sin citas',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 360;
        final spacing = isSingleColumn ? AppSpacing.sm : AppSpacing.md;
        final cardWidth = isSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}
