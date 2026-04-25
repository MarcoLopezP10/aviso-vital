import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/features/device_status/presentation/screens/estado_dispositivo_screen.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminDashboardHeader extends StatelessWidget {
  static const _authRepository = AuthRepository();

  final String caredUserName;
  final bool isConnected;

  const AdminDashboardHeader({
    super.key,
    required this.caredUserName,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected ? AppColors.success : AppColors.warning;
    final statusBackground = isConnected
        ? AppColors.successSubtle.withValues(alpha: 0.72)
        : AppColors.warningSubtle.withValues(alpha: 0.72);
    final statusBorder = isConnected
        ? AppColors.successBorder.withValues(alpha: 0.8)
        : AppColors.warning.withValues(alpha: 0.28);
    final statusLabel = isConnected
        ? context.t.text('Conectado')
        : context.t.text('Sin conexión');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surfaceStrong],
        ),
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: AppColors.surfaceBorderSoft),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.text('CUIDANDO A'),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  caredUserName,
                  style: AppTextStyles.h2.copyWith(fontSize: 26, height: 1.05),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: AppRadius.chip,
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.28),
                              blurRadius: 6,
                              spreadRadius: 0.6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _HeaderActionButton(
            icon: Icons.phone_android_outlined,
            tooltip: context.t.text('Llamar al móvil'),
            onTap: () =>
                Navigator.pushNamed(context, EstadoDispositivoScreen.routeName),
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            icon: Icons.logout_rounded,
            tooltip: context.t.text('Cerrar sesión'),
            onTap: () => ConfirmDialog.show(
              context,
              title: 'Cerrar sesión',
              message: '¿Está seguro de que quiere salir?',
              confirmLabel: 'Salir',
              isDestructive: true,
              onConfirm: () async {
                await _authRepository.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.roleSelection,
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceElevated, AppColors.surfaceStrong],
                ),
                borderRadius: AppRadius.icon,
                border: Border.all(color: AppColors.surfaceBorderSoft),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
