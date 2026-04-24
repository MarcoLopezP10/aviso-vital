import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/alerts_repository.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'package:aviso_vital_2/shared/widgets/content_widgets.dart';

/// Pantalla: Actividad reciente completa
/// Accesible desde home admin — historial completo con agrupación por fecha
class ActividadRecienteScreen extends StatefulWidget {
  static const String routeName = AppRoutes.actividadReciente;
  const ActividadRecienteScreen({super.key});

  @override
  State<ActividadRecienteScreen> createState() =>
      _ActividadRecienteScreenState();
}

class _ActividadRecienteScreenState extends State<ActividadRecienteScreen> {
  static const _alertsRepository = AlertsRepository();
  late Future<List<Alerta>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _alertsRepository.fetchHistoryTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Alerta>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leading: const AppBackButton(),
              title: Text(context.t.text('Actividad reciente')),
            ),
            body: ErrorRetryView(
              useScaffold: false,
              message: context.t.loadErrorMessage,
              onRetry: () {
                setState(
                  () =>
                      _alertsFuture = _alertsRepository.fetchHistoryTimeline(),
                );
              },
            ),
          );
        }

        final alertas = snapshot.data ?? _alertsRepository.getRecent();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            leading: const AppBackButton(),
            title: Text(context.t.text('Actividad reciente')),
          ),
          body: alertas.isEmpty
              ? Center(child: EmptyStateCard.noActivity())
              : RefreshIndicator(
                  onRefresh: () async {
                    final future = _alertsRepository.fetchHistoryTimeline();
                    setState(() => _alertsFuture = future);
                    await future;
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      _GroupSection(
                        label: context.t.today,
                        alertas: alertas.where((a) => a.esHoy).toList(),
                      ),
                      _GroupSection(
                        label: context.t.yesterday,
                        alertas: alertas.where((a) => !a.esHoy).toList(),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String label;
  final List<Alerta> alertas;
  const _GroupSection({required this.label, required this.alertas});

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(
            label,
            style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
          ),
        ),
        ...alertas.map((a) => TimelineEventItem(alerta: a)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
