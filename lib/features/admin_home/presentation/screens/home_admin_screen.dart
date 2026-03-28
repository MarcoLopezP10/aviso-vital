import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_dashboard_page.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_home_shell.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/admin_alertas_screen.dart';
import 'package:aviso_vital_2/features/appointments/presentation/screens/admin_citas_screen.dart';
import 'package:aviso_vital_2/features/medications/presentation/screens/admin_medicamentos_screen.dart';
import 'actividad_reciente_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  static const String routeName = AppRoutes.homeAdmin;
  final int initialIndex;

  const HomeAdminScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant HomeAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() => _navIndex = widget.initialIndex);
    }
  }

  void _switchTab(int index) => setState(() => _navIndex = index);

  List<Widget> _buildPages() => [
    AdminDashboardPage(
      key: ValueKey('dashboard-$_navIndex'),
      onSwitchTab: _switchTab,
      onOpenRecentActivity: () =>
          Navigator.pushNamed(context, ActividadRecienteScreen.routeName),
    ),
    const AdminMedicamentosScreen(showBackButton: false),
    const AdminCitasScreen(showBackButton: false),
    const AdminAlertasScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminHomeShell(
      selectedIndex: _navIndex,
      onDestinationSelected: _switchTab,
      pages: _buildPages(),
    );
  }
}
