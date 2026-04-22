import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/app/router/app_transitions.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/screens/actividad_reciente_screen.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/screens/home_admin_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/admin_alertas_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_cita_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/alerta_medicacion_screen.dart';
import 'package:aviso_vital_2/features/alerts/presentation/screens/simulacion_alertas_screen.dart';
import 'package:aviso_vital_2/features/appointments/presentation/screens/admin_citas_screen.dart';
import 'package:aviso_vital_2/features/appointments/presentation/screens/cita_detalle_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/crear_cuenta_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/social_auth_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/user_login_screen.dart';
import 'package:aviso_vital_2/features/auth/presentation/screens/user_signup_screen.dart';
import 'package:aviso_vital_2/features/device_status/presentation/screens/estado_dispositivo_screen.dart';
import 'package:aviso_vital_2/features/medications/presentation/screens/admin_medicamentos_screen.dart';
import 'package:aviso_vital_2/features/medications/presentation/screens/medicamento_detalle_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/codigo_manual_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/conectar_con_admin_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/dispositivo_conectado_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/escaneo_qr_screen.dart';
import 'package:aviso_vital_2/features/onboarding/presentation/screens/role_selection_screen.dart';
import 'package:aviso_vital_2/features/user_home/presentation/screens/home_usuario_screen.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    final page = switch (settings.name) {
      AppRoutes.roleSelection => const RoleSelectionScreen(),
      AppRoutes.conectarAdmin => const ConectarConAdminScreen(),
      AppRoutes.escaneoQr => const EscaneoQrScreen(),
      AppRoutes.codigoManual => const CodigoManualScreen(),
      AppRoutes.dispositivoConectado => const DispositivoConectadoScreen(),
      AppRoutes.estadoDispositivo => const EstadoDispositivoScreen(),
      AppRoutes.adminLogin => const AdminLoginScreen(),
      AppRoutes.crearCuenta => const CrearCuentaScreen(),
      AppRoutes.userLogin => const UserLoginScreen(),
      AppRoutes.userCrearCuenta => const UserSignupScreen(),
      AppRoutes.socialAuth => SocialAuthScreen(
        providerId: args?['providerId'] as String? ?? 'google',
        roleId: args?['roleId'] as String? ?? 'user',
        modeId: args?['modeId'] as String? ?? 'login',
      ),
      AppRoutes.homeAdmin => HomeAdminScreen(
        initialIndex: args?['tab'] as int? ?? 0,
      ),
      AppRoutes.adminMedicamentos => const AdminMedicamentosScreen(),
      AppRoutes.medicamentoDetalle => MedicamentoDetalleScreen(
        medicamentoId: args?['id'] ?? '',
      ),
      AppRoutes.adminCitas => const AdminCitasScreen(),
      AppRoutes.citaDetalle => CitaDetalleScreen(citaId: args?['id'] ?? ''),
      AppRoutes.adminAlertas => const AdminAlertasScreen(),
      AppRoutes.simulacionAlertas => const SimulacionAlertasScreen(),
      AppRoutes.actividadReciente => const ActividadRecienteScreen(),
      AppRoutes.homeUsuario => const HomeUsuarioScreen(),
      AppRoutes.alertaMedicacion => AlertaMedicacionScreen(
        doseId: args?['doseId'] as String?,
      ),
      AppRoutes.alertaCita => AlertaCitaScreen(
        alertId: args?['alertId'] as String?,
        appointmentId: args?['appointmentId'] as String?,
        reminderKind: args?['reminderKind'] as String?,
        reminderInstanceId: args?['reminderInstanceId'] as String?,
      ),
      _ => const RoleSelectionScreen(),
    };

    return AppTransitions.slide(settings, page);
  }
}
