import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/content_widgets.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminRecentActivityPreview extends StatelessWidget {
  final List<Alerta> alertas;
  final VoidCallback onViewAll;

  const AdminRecentActivityPreview({
    super.key,
    required this.alertas,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Actividad reciente',
          actionLabel: 'Ver todo',
          onAction: onViewAll,
        ),
        const SizedBox(height: AppSpacing.md),
        RecentActivityPanel(
          alertas: alertas,
          maxItems: 3,
          onVerTodo: onViewAll,
        ),
      ],
    );
  }
}
