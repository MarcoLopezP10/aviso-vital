import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/aviso_vital_logo.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

// ════════════════════════════════════════════════════════════════════
// ADMIN SIDEBAR — para tablet/desktop con NavigationRail
// ════════════════════════════════════════════════════════════════════

class AdminDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool showInMobileNav;

  const AdminDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.showInMobileNav = true,
  });
}

const double adminNavigationBreakpoint = 700;

const List<AdminDestination> adminDestinations = [
  AdminDestination(
    label: 'Inicio',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    route: AppRoutes.homeAdmin,
  ),
  AdminDestination(
    label: 'Medicamentos',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication_rounded,
    route: AppRoutes.adminMedicamentos,
  ),
  AdminDestination(
    label: 'Citas',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event_rounded,
    route: AppRoutes.adminCitas,
  ),
  AdminDestination(
    label: 'Alertas',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    route: AppRoutes.adminAlertas,
  ),
];

const List<int> adminMobileDestinationIndexes = [0, 1, 2, 3];

bool isAdminWideLayout(BuildContext context) =>
    MediaQuery.of(context).size.width >= adminNavigationBreakpoint;

/// Sidebar para admin en tablet/desktop
/// En móvil se sustituye por AppBar + bottom nav o drawer
class AdminSidebar extends StatelessWidget {
  static const _authRepository = AuthRepository();
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.backgroundSoft],
        ),
        border: const Border(right: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                AvisoVitalLogo(size: 36, animate: false, showGlow: false),
                const SizedBox(width: 10),
                Text(
                  'Aviso Vital',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          const SizedBox(height: 8),

          // ── Items de navegación ──
          ...adminDestinations.asMap().entries.map((entry) {
            final i = entry.key;
            final dest = entry.value;
            final selected = i == selectedIndex;
            return _SidebarItem(
              dest: dest,
              selected: selected,
              onTap: () => onDestinationSelected(i),
            );
          }),

          const Spacer(),
          const Divider(),

          // ── Cerrar sesión ──
          _SidebarItem(
            dest: const AdminDestination(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              selectedIcon: Icons.logout_rounded,
              route: '/',
            ),
            selected: false,
            onTap: () => ConfirmDialog.show(
              context,
              title: 'Cerrar sesión',
              message: '¿Está seguro de que quiere salir?',
              confirmLabel: 'Salir',
              isDestructive: true,
              onConfirm: () async {
                await _authRepository.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.roleSelection,
                  (_) => false,
                );
              },
            ),
            isLogout: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class AdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        4,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.06),
                blurRadius: 12,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            children: adminMobileDestinationIndexes.map((destinationIndex) {
              final destination = adminDestinations[destinationIndex];
              final selected = destinationIndex == selectedIndex;
              return Expanded(
                child: _BottomNavItem(
                  destination: destination,
                  selected: selected,
                  onTap: () => onDestinationSelected(destinationIndex),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class AdminSectionFab extends StatelessWidget {
  final Color color;
  final Color foregroundColor;
  final bool hasBottomNav;
  final VoidCallback onPressed;
  final bool compact;

  const AdminSectionFab({
    super.key,
    required this.color,
    required this.foregroundColor,
    required this.hasBottomNav,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: AppSpacing.xs,
        bottom: hasBottomNav ? (compact ? 98 : 104) : 0,
      ),
      child: SizedBox(
        width: compact ? 48 : 56,
        height: compact ? 48 : 56,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 14 : 17),
            side: BorderSide(
              color: color.withValues(alpha: compact ? 0.22 : 0.32),
            ),
          ),
          child: Icon(Icons.add_rounded, size: compact ? 21 : 24),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final AdminDestination dest;
  final bool selected;
  final VoidCallback onTap;
  final bool isLogout;

  const _SidebarItem({
    required this.dest,
    required this.selected,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? AppColors.textTertiary
        : selected
        ? AppColors.amber
        : AppColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.icon,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.amber.withValues(alpha: 0.14),
                      AppColors.amber.withValues(alpha: 0.07),
                    ],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: AppRadius.icon,
            border: selected
                ? Border.all(color: AppColors.amber.withValues(alpha: 0.16))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.amber.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: AppRadius.icon,
                ),
                child: Icon(
                  selected ? dest.selectedIcon : dest.icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                dest.label,
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTextColor = AppColors.textOnAmber;
    final inactiveColor = AppColors.textTertiary;

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: selected
            ? const LinearGradient(
                colors: [AppColors.amberLight, AppColors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 9 : 6,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: selected ? 22 : 20,
                  color: selected ? activeTextColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: selected ? activeTextColor : inactiveColor,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// SEARCH FILTER BAR
// ════════════════════════════════════════════════════════════════════

/// Barra de búsqueda + filtros para listas admin
class SearchFilterBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final List<FilterChipData>? filters;
  final String? activeFilter;
  final ValueChanged<String>? onFilterChanged;
  final ValueChanged<String>? onSearch;
  final bool compact;

  const SearchFilterBar({
    super.key,
    this.controller,
    this.hint = 'Buscar...',
    this.filters,
    this.activeFilter,
    this.onFilterChanged,
    this.onSearch,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Campo de búsqueda ──
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surface, AppColors.surfaceFloating],
            ),
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: AppShadows.cardSubtle,
          ),
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textTertiary,
                size: compact ? 20 : 22,
              ),
              suffixIcon: controller?.text.isNotEmpty == true
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                      onPressed: () {
                        controller?.clear();
                        onSearch?.call('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ── Filtros ──
        if (filters != null && filters!.isNotEmpty) ...[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters!.map((f) {
                final active = f.value == activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.amber.withValues(alpha: 0.20)
                          : Colors.transparent,
                      borderRadius: AppRadius.chip,
                      border: Border.all(
                        color: active
                            ? AppColors.amber
                            : AppColors.surfaceBorder.withValues(alpha: 0.60),
                        width: active ? 1.4 : 1.0,
                      ),
                    ),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: active,
                      onSelected: (_) => onFilterChanged?.call(f.value),
                      backgroundColor: Colors.transparent,
                      selectedColor: Colors.transparent,
                      disabledColor: Colors.transparent,
                      showCheckmark: active,
                      checkmarkColor: AppColors.amber,
                      side: BorderSide.none,
                      labelStyle: AppTextStyles.label.copyWith(
                        color: active
                            ? AppColors.amber
                            : AppColors.textTertiary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: compact ? 12 : null,
                      ),
                      visualDensity: compact
                          ? const VisualDensity(horizontal: -2, vertical: -2)
                          : VisualDensity.standard,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class FilterChipData {
  final String label;
  final String value;
  const FilterChipData({required this.label, required this.value});
}

// ════════════════════════════════════════════════════════════════════
// CONNECTION STATUS CARD
// ════════════════════════════════════════════════════════════════════

/// Tarjeta de estado del dispositivo vinculado
class ConnectionStatusCard extends StatelessWidget {
  final String nombreUsuario;
  final bool conectado;
  final DateTime? ultimaSincronizacion;
  final DateTime? fechaVinculacion;
  final bool notificacionesActivas;
  final VoidCallback? onDesvincular;

  const ConnectionStatusCard({
    super.key,
    required this.nombreUsuario,
    required this.conectado,
    this.ultimaSincronizacion,
    this.fechaVinculacion,
    this.notificacionesActivas = true,
    this.onDesvincular,
  });

  @override
  Widget build(BuildContext context) {
    final color = conectado ? AppColors.success : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: conectado ? AppColors.success : AppColors.textTertiary,
                  boxShadow: conectado
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                conectado ? 'Dispositivo conectado' : 'Sin conexión',
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
              const Spacer(),
              if (conectado && notificacionesActivas)
                StatusBadge(
                  label: 'Alertas activas',
                  variant: BadgeVariant.success,
                  icon: Icons.notifications_active_outlined,
                  small: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(nombreUsuario, style: AppTextStyles.h4),
          const SizedBox(height: 6),
          if (ultimaSincronizacion != null)
            _InfoRow(
              icon: Icons.sync_rounded,
              text: 'Última sync: ${_formatDateTime(ultimaSincronizacion!)}',
            ),
          if (fechaVinculacion != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.link_rounded,
              text: 'Vinculado el ${_formatDate(fechaVinculacion!)}',
            ),
          ],
          if (onDesvincular != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onDesvincular,
              icon: const Icon(
                Icons.link_off_rounded,
                size: 16,
                color: AppColors.danger,
              ),
              label: const Text(
                'Desvincular dispositivo',
                style: TextStyle(color: AppColors.danger),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    return 'hace ${diff.inHours}h';
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}
