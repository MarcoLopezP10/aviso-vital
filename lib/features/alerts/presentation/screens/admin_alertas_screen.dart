import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_section_scaffold.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

/// Pantalla: Historial de Alertas
/// Tabs: Medicación / Citas · Métricas de adherencia · Agrupado por fecha
class AdminAlertasScreen extends StatefulWidget {
  static const String routeName = AppRoutes.adminAlertas;
  final bool showBackButton;

  const AdminAlertasScreen({super.key, this.showBackButton = true});

  @override
  State<AdminAlertasScreen> createState() => _AdminAlertasScreenState();
}

class _AdminAlertasScreenState extends State<AdminAlertasScreen>
    with SingleTickerProviderStateMixin {
  static const _alertsRepository = AlertsRepository();
  static const _userRepository = UserRepository();
  late final TabController _tabCtrl;
  late Future<_AlertsScreenData> _screenDataFuture;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _screenDataFuture = _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<_AlertsScreenData> _loadData() async {
    final alertas = await _alertsRepository.fetchHistoryTimeline();
    final adherencia = await _alertsRepository.fetchAdherenceSummary(
      historyTimeline: alertas,
    );
    return _AlertsScreenData(adherencia: adherencia, alertas: alertas);
  }

  @override
  Widget build(BuildContext context) {
    final user = _userRepository.getCurrentUser();
    return FutureBuilder<_AlertsScreenData>(
      future: _screenDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
            snapshot.data ??
            _AlertsScreenData(
              adherencia: _alertsRepository.getAdherenceSummary(),
              alertas: _alertsRepository.getRecent(),
            );
        final medicacion = data.alertas
            .where(
              (a) =>
                  a.tipo == TipoAlerta.medicacion ||
                  a.tipo == TipoAlerta.stockBajo,
            )
            .toList();
        final citas = data.alertas
            .where((a) => a.tipo == TipoAlerta.cita)
            .toList();

        return AdminSectionScaffold(
          title: 'Historial de alertas',
          subtitle: user.nombre,
          onBack: widget.showBackButton
              ? () => Navigator.maybePop(context)
              : null,
          compactHeader: true,
          stats: _AdherenciaPanel(adherencia: data.adherencia),
          filters: TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(height: 34, text: 'Medicación'),
              Tab(height: 34, text: 'Citas'),
            ],
            padding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _AlertasList(alertas: medicacion),
              _AlertasList(alertas: citas),
            ],
          ),
          primaryGlowColor: AppColors.amber,
          secondaryGlowColor: AppColors.orange,
          primaryGlowAlignment: const Alignment(1, -0.92),
          secondaryGlowAlignment: const Alignment(-0.95, 0.18),
          intensity: 0.64,
        );
      },
    );
  }
}

class _AlertsScreenData {
  final ResumenAdherencia adherencia;
  final List<Alerta> alertas;

  const _AlertsScreenData({required this.adherencia, required this.alertas});
}

class _AdherenciaPanel extends StatelessWidget {
  final ResumenAdherencia adherencia;
  const _AdherenciaPanel({required this.adherencia});

  @override
  Widget build(BuildContext context) {
    final pct = (adherencia.adherencia * 100).round();
    final color = pct >= 80
        ? AppColors.success
        : pct >= 60
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adherencia esta semana',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.h3.copyWith(color: color, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.chip,
            child: LinearProgressIndicator(
              value: adherencia.adherencia,
              minHeight: 6,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatPill(
                label: '${adherencia.tomasConfirmadas} confirmadas',
                color: AppColors.success,
              ),
              _StatPill(
                label: '${adherencia.tomasOmitidas} omitidas',
                color: AppColors.danger,
              ),
              _StatPill(
                label: '${adherencia.tomasPendientes} pendientes',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.chip,
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    ),
  );
}

class _AlertasList extends StatelessWidget {
  final List<Alerta> alertas;
  const _AlertasList({required this.alertas});

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: EmptyStateCard.noAlerts(),
      );
    }

    // Agrupar por fecha
    final hoy = alertas.where((a) => a.esHoy).toList();
    final ayer = alertas.where((a) => !a.esHoy).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        if (hoy.isNotEmpty) ...[
          _GroupLabel('Hoy'),
          ...hoy.map((a) => _AlertaCard(alerta: a)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (ayer.isNotEmpty) ...[
          _GroupLabel('Ayer'),
          ...ayer.map((a) => _AlertaCard(alerta: a)),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.overline.copyWith(letterSpacing: 1.2, fontSize: 11),
    ),
  );
}

class _AlertaCard extends StatelessWidget {
  final Alerta alerta;
  const _AlertaCard({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                ),
                if (alerta.descripcion != null)
                  Text(
                    alerta.descripcion!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatHora(alerta.fechaHora),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              _estadoBadge(),
            ],
          ),
        ],
      ),
    );
  }

  (Color, IconData) _style() => switch (alerta.estado) {
    EstadoAlerta.confirmada => (AppColors.success, Icons.check_circle_outline),
    EstadoAlerta.omitida => (AppColors.danger, Icons.cancel_outlined),
    EstadoAlerta.expirada => (AppColors.danger, Icons.timer_off_outlined),
    EstadoAlerta.vista =>
      alerta.tipo == TipoAlerta.stockBajo
          ? (AppColors.warning, Icons.warning_amber_outlined)
          : (AppColors.info, Icons.notifications_outlined),
    EstadoAlerta.pendiente => (AppColors.warning, Icons.schedule_outlined),
  };

  Widget _estadoBadge() => switch (alerta.estado) {
    EstadoAlerta.confirmada => StatusBadge.confirmed(small: true),
    EstadoAlerta.omitida => StatusBadge.missed(small: true),
    EstadoAlerta.expirada => StatusBadge.expired(small: true),
    EstadoAlerta.pendiente => StatusBadge.pending(small: true),
    _ => const SizedBox.shrink(),
  };

  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
