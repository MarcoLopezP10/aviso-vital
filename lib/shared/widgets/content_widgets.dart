import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'shared_widgets.dart';

// ════════════════════════════════════════════════════════════════════
// MEDICATION CARD
// ════════════════════════════════════════════════════════════════════

/// Tarjeta de medicamento — usada en lista de admin y en home usuario
class MedicationCard extends StatelessWidget {
  final Medicamento medicamento;
  final Toma? tomaHoy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;
  final bool forceStockBar;

  const MedicationCard({
    super.key,
    required this.medicamento,
    this.tomaHoy,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.compact = false,
    this.forceStockBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
          vertical: compact ? AppSpacing.sm : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surfaceFloating],
          ),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: medicamento.stockBajo
                ? AppColors.dangerBorder
                : AppColors.surfaceBorder,
          ),
          boxShadow: AppShadows.cardSubtle,
        ),
        child: Row(
          children: [
            // ── Pastilla visual ──
            PillVisual(
              color: medicamento.colorPastilla,
              shape: _toFormShape(medicamento.formaPastilla),
              size: compact ? 34 : 44,
            ),

            const SizedBox(width: AppSpacing.md),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          medicamento.nombre,
                          style: compact
                              ? AppTextStyles.h4.copyWith(fontSize: 17)
                              : AppTextStyles.h3.copyWith(fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (medicamento.stockBajo)
                        StatusBadge.lowStock(small: true),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Text(
                    '${medicamento.dosis} · ${medicamento.frecuencia.label}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if ((!compact || forceStockBar) &&
                      medicamento.horasToma.isNotEmpty) ...[
                    SizedBox(height: compact ? 5 : 6),
                    _StockBar(medicamento: medicamento),
                  ],
                ],
              ),
            ),

            // ── Acciones ──
            if (showActions)
              _ActionsMenu(onEdit: onEdit, onDelete: onDelete)
            else if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textDisabled,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  FormShape _toFormShape(FormaPastilla f) => switch (f) {
    FormaPastilla.redonda => FormShape.round,
    FormaPastilla.ovalada => FormShape.oval,
    FormaPastilla.capsula => FormShape.capsule,
  };
}

class _StockBar extends StatelessWidget {
  final Medicamento med;
  const _StockBar({required this.medicamento}) : med = medicamento;
  final Medicamento medicamento;

  @override
  Widget build(BuildContext context) {
    final ratio = (med.stockActual / (med.stockMinimo * 4)).clamp(0.0, 1.0);
    final color = med.stockBajo ? AppColors.danger : AppColors.success;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.chip,
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${med.stockActual} uds',
          style: AppTextStyles.caption.copyWith(
            color: med.stockBajo ? AppColors.danger : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ActionsMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.surfaceBorder.withValues(alpha: 0.7),
          ),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textTertiary,
          size: 18,
        ),
      ),
      padding: EdgeInsets.zero,
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 10),
                Text(
                  'Editar',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                ),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 10),
                Text(
                  'Eliminar',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// APPOINTMENT CARD
// ════════════════════════════════════════════════════════════════════

/// Tarjeta de cita médica — usada en lista admin y home usuario
class AppointmentCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;

  const AppointmentCard({
    super.key,
    required this.cita,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final esHoy = cita.esHoy;
    final titleStyle = compact
        ? AppTextStyles.h4.copyWith(fontSize: 15.5)
        : AppTextStyles.h4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
          vertical: compact ? AppSpacing.sm : AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surfaceFloating],
          ),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: esHoy ? AppColors.orangeBorder : AppColors.surfaceBorder,
          ),
          boxShadow: AppShadows.cardSubtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fecha badge ──
            _DateBadge(
              fecha: cita.fecha,
              hora: cita.hora,
              esHoy: esHoy,
              compact: compact,
            ),

            const SizedBox(width: AppSpacing.md),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cita.especialidad,
                          style: titleStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (esHoy) StatusBadge.today(small: true),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Text(
                    cita.lugar,
                    style: compact
                        ? AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          )
                        : AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cita.direccion != null) ...[
                    SizedBox(height: compact ? 1 : 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: compact ? 11 : 12,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: compact ? 2 : 3),
                        Expanded(
                          child: Text(
                            cita.direccion!,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: compact ? 11 : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Acciones ──
            if (showActions)
              _ActionsMenuCita(onEdit: onEdit, onDelete: onDelete)
            else if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textDisabled,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime fecha;
  final String hora;
  final bool esHoy;
  final bool compact;

  const _DateBadge({
    required this.fecha,
    required this.hora,
    required this.esHoy,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = esHoy ? AppColors.orange : AppColors.info;
    const meses = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];

    return Container(
      width: compact ? 56 : 62,
      height: compact ? 66 : 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.42),
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.10),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${fecha.day}',
            style: AppTextStyles.h2.copyWith(
              color: color,
              height: 1,
              fontSize: compact ? 23 : 26,
            ),
          ),
          SizedBox(height: compact ? 0 : 1),
          Text(
            meses[fecha.month - 1],
            style: AppTextStyles.overline.copyWith(
              color: color.withValues(alpha: 0.85),
              letterSpacing: compact ? 1.0 : 1.2,
              fontSize: compact ? 9.5 : null,
            ),
          ),
          SizedBox(height: compact ? 2 : 3),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 6,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hora,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 9.5 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsMenuCita extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ActionsMenuCita({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.surfaceBorder.withValues(alpha: 0.7),
          ),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textTertiary,
          size: 18,
        ),
      ),
      padding: EdgeInsets.zero,
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 10),
                Text(
                  'Editar',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                ),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                SizedBox(width: 10),
                Text(
                  'Eliminar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// RECENT ACTIVITY PANEL
// ════════════════════════════════════════════════════════════════════

/// Panel de actividad reciente — reutilizable en home admin y pantalla propia
class RecentActivityPanel extends StatelessWidget {
  final List<Alerta> alertas;
  final int maxItems;
  final VoidCallback? onVerTodo;

  const RecentActivityPanel({
    super.key,
    required this.alertas,
    this.maxItems = 5,
    this.onVerTodo,
  });

  @override
  Widget build(BuildContext context) {
    final items = alertas.take(maxItems).toList();
    if (items.isEmpty) {
      return EmptyStateCard.noActivity();
    }

    return Column(
      children: [
        ...items.map((a) => TimelineEventItem(alerta: a)),
        if (onVerTodo != null)
          TextButton(
            onPressed: onVerTodo,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text(
              'Ver historial',
              style: AppTextStyles.label.copyWith(color: AppColors.amber),
            ),
          ),
      ],
    );
  }
}

/// Item de línea de tiempo para actividad
class TimelineEventItem extends StatelessWidget {
  final Alerta alerta;

  const TimelineEventItem({super.key, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _iconForAlerta(alerta);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (alerta.descripcion != null)
                  Text(
                    alerta.descripcion!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(alerta.fechaHora),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _iconForAlerta(Alerta a) => switch (a.estado) {
    EstadoAlerta.confirmada => (AppColors.success, Icons.check_circle_outline),
    EstadoAlerta.omitida => (AppColors.danger, Icons.cancel_outlined),
    EstadoAlerta.expirada => (AppColors.danger, Icons.timer_off_outlined),
    EstadoAlerta.vista =>
      a.tipo == TipoAlerta.stockBajo
          ? (AppColors.warning, Icons.warning_amber_outlined)
          : (AppColors.info, Icons.notifications_outlined),
    EstadoAlerta.pendiente => (AppColors.warning, Icons.schedule_outlined),
  };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    if (diff.inHours < 24) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Ayer';
  }
}
