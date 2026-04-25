import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';

export 'premium_background.dart';
export 'stock_progress_bar.dart';
export 'weekly_adherence_strip.dart';

// ════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS — Aviso Vital
// Componentes reutilizables con lenguaje visual unificado
// ════════════════════════════════════════════════════════════════════

// ────────────────────────────────────────────────────────────────────
// BOTONES
// ────────────────────────────────────────────────────────────────────

/// Botón primario estándar de la app
/// Adaptable: tamaño, color, icono, loading state
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? width;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 56,
    this.width,
    this.fontSize = 17,
  });

  /// Variante grande — para flujo usuario mayor
  factory PrimaryButton.large({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) => PrimaryButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    height: 72,
    width: double.infinity,
    fontSize: 22,
  );

  /// Variante pequeña — para acciones secundarias
  factory PrimaryButton.small({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
  }) => PrimaryButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    height: 44,
    width: width,
    fontSize: 14,
  );

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.amber;
    final fg =
        foregroundColor ??
        (bg == AppColors.amber ? AppColors.textOnAmber : AppColors.textPrimary);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          foregroundColor: fg,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: fontSize + 4, color: fg),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    context.t.text(label),
                    style: AppTextStyles.buttonLarge.copyWith(
                      fontSize: fontSize,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Botón secundario con borde
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: AppColors.surfaceBorder),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 8),
            ],
            Text(
              context.t.text(label),
              style: AppTextStyles.button.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ────────────────────────────────────────────────────────────────────

enum BadgeVariant { success, danger, warning, info, neutral, amber }

/// Badge de estado reutilizable
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
    this.small = false,
  });

  factory StatusBadge.confirmed({bool small = false}) => StatusBadge(
    label: 'Confirmada',
    variant: BadgeVariant.success,
    icon: Icons.check_circle_outline,
    small: small,
  );

  factory StatusBadge.missed({bool small = false}) => StatusBadge(
    label: 'Omitida',
    variant: BadgeVariant.danger,
    icon: Icons.cancel_outlined,
    small: small,
  );

  factory StatusBadge.pending({bool small = false}) => StatusBadge(
    label: 'Pendiente',
    variant: BadgeVariant.warning,
    icon: Icons.schedule_outlined,
    small: small,
  );

  factory StatusBadge.expired({bool small = false}) => StatusBadge(
    label: 'Expirada',
    variant: BadgeVariant.danger,
    icon: Icons.timer_off_outlined,
    small: small,
  );

  factory StatusBadge.lowStock({bool small = false}) => StatusBadge(
    label: 'Stock bajo',
    variant: BadgeVariant.danger,
    icon: Icons.warning_amber_outlined,
    small: small,
  );

  factory StatusBadge.today({bool small = false}) =>
      StatusBadge(label: 'Hoy', variant: BadgeVariant.amber, small: small);

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();
    final fs = small ? 11.0 : 12.0;
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.chip,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fs + 2, color: fg),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            context.t.text(label),
            style: AppTextStyles.overline.copyWith(
              fontSize: fs,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _colors() {
    return switch (variant) {
      BadgeVariant.success => (
        AppColors.successSubtle,
        AppColors.success,
        AppColors.successBorder,
      ),
      BadgeVariant.danger => (
        AppColors.dangerSubtle,
        AppColors.danger,
        AppColors.dangerBorder,
      ),
      BadgeVariant.warning => (
        AppColors.warningSubtle,
        AppColors.warning,
        AppColors.warningBorder,
      ),
      BadgeVariant.info => (
        AppColors.infoSubtle,
        AppColors.info,
        AppColors.infoBorder,
      ),
      BadgeVariant.amber => (
        AppColors.amberSubtle,
        AppColors.amber,
        AppColors.amberBorder,
      ),
      BadgeVariant.neutral => (
        AppColors.surfaceRaised,
        AppColors.textSecondary,
        AppColors.surfaceBorder,
      ),
    };
  }
}

// ────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ────────────────────────────────────────────────────────────────────

/// Cabecera de sección con título, subtítulo y acción opcional
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.text(title),
                style: AppTextStyles.h3.copyWith(fontSize: 22, height: 1.1),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  context.t.text(subtitle!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              context.t.text(actionLabel!),
              style: AppTextStyles.label.copyWith(color: AppColors.amber),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// EMPTY STATE CARD
// ────────────────────────────────────────────────────────────────────

/// Estado vacío elegante con icono, mensaje y CTA opcional
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  factory EmptyStateCard.noMedications({VoidCallback? onAdd}) => EmptyStateCard(
    icon: Icons.medication_outlined,
    title: 'Sin medicamentos',
    subtitle:
        'Añada el primer medicamento para empezar a gestionar las alertas',
    actionLabel: onAdd != null ? 'Añadir medicamento' : null,
    onAction: onAdd,
    iconColor: AppColors.amber,
  );

  factory EmptyStateCard.noAppointments({VoidCallback? onAdd}) =>
      EmptyStateCard(
        icon: Icons.event_outlined,
        title: 'Sin citas próximas',
        subtitle: 'No hay citas programadas. Añada una cuando la tenga.',
        actionLabel: onAdd != null ? 'Añadir cita' : null,
        onAction: onAdd,
        iconColor: AppColors.orange,
      );

  factory EmptyStateCard.noAlerts() => const EmptyStateCard(
    icon: Icons.notifications_none_outlined,
    title: 'Sin alertas recientes',
    subtitle: 'Aquí aparecerá el historial de confirmaciones y omisiones',
    iconColor: AppColors.textTertiary,
  );

  factory EmptyStateCard.noActivity() => const EmptyStateCard(
    icon: Icons.timeline_outlined,
    title: 'Sin actividad reciente',
    subtitle: 'La actividad aparecerá aquí en tiempo real',
    iconColor: AppColors.textTertiary,
  );

  factory EmptyStateCard.noDevice({VoidCallback? onConnect}) => EmptyStateCard(
    icon: Icons.phone_android_outlined,
    title: 'Dispositivo no vinculado',
    subtitle:
        'Vincule el teléfono del usuario mayor para empezar a enviarle alertas',
    actionLabel: onConnect != null ? 'Vincular dispositivo' : null,
    onAction: onConnect,
    iconColor: AppColors.info,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.textTertiary).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: iconColor ?? AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t.text(title),
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              context.t.text(subtitle!),
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PrimaryButton.small(
              label: context.t.text(actionLabel!),
              onPressed: onAction,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ────────────────────────────────────────────────────────────────────

/// Diálogo de confirmación reutilizable con variante destructiva
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDestructive ? AppColors.danger : AppColors.amber;
    final confirmFg = isDestructive
        ? AppColors.textPrimary
        : AppColors.textOnAmber;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDestructive) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dangerSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(context.t.text(title), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              context.t.text(message),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: context.t.text(cancelLabel),
                    onPressed: () => Navigator.of(context).pop(false),
                    height: 48,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: context.t.text(confirmLabel),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    backgroundColor: confirmColor,
                    foregroundColor: confirmFg,
                    height: 48,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// APP BACK BUTTON
// ────────────────────────────────────────────────────────────────────

/// Botón de atrás consistente en toda la app
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onPressed ??
          () async {
            final navigator = Navigator.of(context);
            if (await navigator.maybePop()) return;
          },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surfaceElevated],
          ),
          borderRadius: AppRadius.icon,
          border: Border.all(color: AppColors.surfaceBorderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Theme.of(context).platform == TargetPlatform.iOS
              ? Icons.arrow_back_ios_new_rounded
              : Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// LOADING OVERLAY
// ────────────────────────────────────────────────────────────────────

/// Indicador de carga centrado para estados de loading
class LoadingCenter extends StatelessWidget {
  final String? message;
  const LoadingCenter({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.amber),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// SUMMARY STAT CARD
// ────────────────────────────────────────────────────────────────────

/// Tarjeta de estadística compacta para dashboards
class SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const SummaryStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 390;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.07),
              AppColors.surfaceStrong,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          borderRadius: AppRadius.cardLg,
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 32 : 36,
              height: isCompact ? 32 : 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.iconLg,
                border: Border.all(color: color.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontSize: isCompact ? 19 : 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.t.text(title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                context.t.text(subtitle!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// PILL VISUAL
// ────────────────────────────────────────────────────────────────────

/// Ilustración visual de pastilla — reutilizable en todas las pantallas
class PillVisual extends StatelessWidget {
  final Color color;
  final FormShape shape;
  final double size;
  final bool showGlow;

  const PillVisual({
    super.key,
    required this.color,
    this.shape = FormShape.round,
    this.size = 48,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = showGlow ? AppShadows.pill(color) : null;

    if (shape == FormShape.capsule) {
      return _Capsule(color: color, size: size, shadows: shadows);
    }

    return Container(
      width: size,
      height: shape == FormShape.oval ? size * 0.65 : size,
      decoration: BoxDecoration(
        color: color,
        shape: shape == FormShape.round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shape == FormShape.oval
            ? BorderRadius.circular(size)
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: shadows,
      ),
      child: shape == FormShape.round
          ? CustomPaint(painter: _PillLinePainter())
          : null,
    );
  }
}

enum FormShape { round, oval, capsule }

class _Capsule extends StatelessWidget {
  final Color color;
  final double size;
  final List<BoxShadow>? shadows;
  const _Capsule({required this.color, required this.size, this.shadows});

  @override
  Widget build(BuildContext context) {
    final w = size * 1.8;
    final h = size * 0.7;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: w / 2,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(h / 2)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: shadows,
          ),
        ),
        Container(
          width: w / 2,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(h / 2),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// ERROR RETRY VIEW
// ────────────────────────────────────────────────────────────────────

class ErrorRetryView extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool useScaffold;

  const ErrorRetryView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.useScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                title ?? strings.loadErrorTitle,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                PrimaryButton(label: strings.retry, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );

    if (!useScaffold) return content;

    return Scaffold(body: Center(child: content));
  }
}

class _PillLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.28, size.height / 2),
      Offset(size.width * 0.72, size.height / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
