import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/repositories/device_repository.dart';
import 'package:aviso_vital_2/features/device_status/presentation/screens/estado_dispositivo_screen.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

class AdminDeviceStatusBanner extends StatelessWidget {
  static const _deviceRepository = DeviceRepository();

  const AdminDeviceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DeviceBannerData>(
      future: _loadData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _DeviceBannerData();
        final color = data.connected ? AppColors.success : AppColors.warning;
        final label = data.connected
            ? '${data.userName ?? 'Usuario vinculado'} · Sync hace ${_syncLabel(data.lastSync)}'
            : 'Sin usuario mayor vinculado todavía';

        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, EstadoDispositivoScreen.routeName),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF102216), Color(0xFF0B1610)],
              ),
              borderRadius: AppRadius.card,
              border: Border.all(color: color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_DeviceBannerData> _loadData() async {
    final user = await _deviceRepository.getLinkedDeviceStatus();
    return _DeviceBannerData(
      connected: user?.connected == true,
      userName: user?.displayName,
      lastSync: user?.lastSyncAt,
    );
  }
}

class _DeviceBannerData {
  final bool connected;
  final String? userName;
  final DateTime? lastSync;

  const _DeviceBannerData({
    this.connected = false,
    this.userName,
    this.lastSync,
  });
}

String _syncLabel(DateTime? ultima) {
  if (ultima == null) return 'desconocido';
  final diff = DateTime.now().difference(ultima);
  if (diff.inMinutes < 1) return 'ahora mismo';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
