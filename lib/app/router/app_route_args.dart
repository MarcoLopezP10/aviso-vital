class HomeAdminRouteArgs {
  final int tab;

  const HomeAdminRouteArgs({this.tab = 0});

  static HomeAdminRouteArgs from(Object? args) {
    if (args is HomeAdminRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return HomeAdminRouteArgs(tab: args['tab'] as int? ?? 0);
    }
    return const HomeAdminRouteArgs();
  }
}

class SocialAuthRouteArgs {
  final String providerId;
  final String roleId;
  final String modeId;

  const SocialAuthRouteArgs({
    this.providerId = 'google',
    this.roleId = 'user',
    this.modeId = 'login',
  });

  static SocialAuthRouteArgs from(Object? args) {
    if (args is SocialAuthRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return SocialAuthRouteArgs(
        providerId: args['providerId'] as String? ?? 'google',
        roleId: args['roleId'] as String? ?? 'user',
        modeId: args['modeId'] as String? ?? 'login',
      );
    }
    return const SocialAuthRouteArgs();
  }
}

class MedicamentoDetalleRouteArgs {
  final String id;

  const MedicamentoDetalleRouteArgs({required this.id});

  static MedicamentoDetalleRouteArgs from(Object? args) {
    if (args is MedicamentoDetalleRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return MedicamentoDetalleRouteArgs(id: args['id']?.toString() ?? '');
    }
    return const MedicamentoDetalleRouteArgs(id: '');
  }
}

class CitaDetalleRouteArgs {
  final String id;

  const CitaDetalleRouteArgs({required this.id});

  static CitaDetalleRouteArgs from(Object? args) {
    if (args is CitaDetalleRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return CitaDetalleRouteArgs(id: args['id']?.toString() ?? '');
    }
    return const CitaDetalleRouteArgs(id: '');
  }
}

class AlertaMedicacionRouteArgs {
  final String? doseId;

  const AlertaMedicacionRouteArgs({this.doseId});

  static AlertaMedicacionRouteArgs from(Object? args) {
    if (args is AlertaMedicacionRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return AlertaMedicacionRouteArgs(doseId: args['doseId'] as String?);
    }
    return const AlertaMedicacionRouteArgs();
  }
}

class AlertaCitaRouteArgs {
  final String? alertId;
  final String? appointmentId;
  final String? reminderKind;
  final String? reminderInstanceId;

  const AlertaCitaRouteArgs({
    this.alertId,
    this.appointmentId,
    this.reminderKind,
    this.reminderInstanceId,
  });

  static AlertaCitaRouteArgs from(Object? args) {
    if (args is AlertaCitaRouteArgs) return args;
    if (args is Map<String, dynamic>) {
      return AlertaCitaRouteArgs(
        alertId: args['alertId'] as String?,
        appointmentId: args['appointmentId'] as String?,
        reminderKind: args['reminderKind'] as String?,
        reminderInstanceId: args['reminderInstanceId'] as String?,
      );
    }
    return const AlertaCitaRouteArgs();
  }
}
