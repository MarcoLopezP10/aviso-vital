import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'package:aviso_vital_2/data/repositories/device_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_widgets.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/layout/app_detail_scaffold.dart';

/// Pantalla: Estado del dispositivo vinculado
/// Accessible desde el home admin — muestra info del dispositivo de Carmen
class EstadoDispositivoScreen extends StatefulWidget {
  static const String routeName = AppRoutes.estadoDispositivo;
  static const _deviceRepository = DeviceRepository();
  static const _userRepository = UserRepository();

  const EstadoDispositivoScreen({super.key});

  @override
  State<EstadoDispositivoScreen> createState() =>
      _EstadoDispositivoScreenState();
}

class _EstadoDispositivoScreenState extends State<EstadoDispositivoScreen> {
  late final Future<_DeviceStatusData> _screenDataFuture;

  @override
  void initState() {
    super.initState();
    _screenDataFuture = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      title: 'Estado del dispositivo',
      content: FutureBuilder<_DeviceStatusData>(
        future: _screenDataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final device = data?.linkedDevice;
          final admin = data?.admin;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (admin == null) {
            return const Center(
              child: Text('No se pudo cargar el perfil del administrador.'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConnectionStatusCard(
                nombreUsuario: device?.displayName ?? 'Sin usuario vinculado',
                conectado: device?.connected == true,
                ultimaSincronizacion: device?.lastSyncAt,
                fechaVinculacion: device?.linkedAt,
                notificacionesActivas: device?.connected == true,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'CÓDIGO DE VINCULACIÓN',
                style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código activo', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          Text(
                            _formatCode(admin.codigoVinculacion),
                            style: AppTextStyles.display2.copyWith(
                              letterSpacing: 3.2,
                              color: AppColors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () =>
                          _copyCode(context, admin.codigoVinculacion),
                      tooltip: 'Copiar',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Comparta este código exactamente como aparece: dos letras y cuatro números.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'ESTADO DE ALERTAS',
                style: AppTextStyles.overline.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              const _AlertaRow(label: 'Alertas de medicación', activo: true),
              const _AlertaRow(label: 'Alertas de citas médicas', activo: true),
              const _AlertaRow(label: 'Alertas de stock bajo', activo: true),
            ],
          );
        },
      ),
    );
  }

  String _formatCode(String? code) {
    final normalized = code?.replaceAll('-', '').trim().toUpperCase() ?? '';
    if (normalized.length != 6) return code ?? '—';
    return '${normalized.substring(0, 2)}-${normalized.substring(2)}';
  }

  Future<void> _copyCode(BuildContext context, String? code) async {
    final normalized = code?.replaceAll('-', '').trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: normalized));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  Future<_DeviceStatusData> _loadData() async {
    final admin = await EstadoDispositivoScreen._userRepository
        .getSignedInUserProfile();
    final linkedDevice = await EstadoDispositivoScreen._deviceRepository
        .getLinkedDeviceStatus();
    return _DeviceStatusData(admin: admin, linkedDevice: linkedDevice);
  }
}

class _DeviceStatusData {
  final Usuario? admin;
  final LinkedDeviceStatus? linkedDevice;

  const _DeviceStatusData({this.admin, this.linkedDevice});
}

class _AlertaRow extends StatelessWidget {
  final String label;
  final bool activo;
  const _AlertaRow({required this.label, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Switch(value: activo, onChanged: (_) {}),
        ],
      ),
    );
  }
}
