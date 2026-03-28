import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

export 'app_colors.dart';
export 'app_text_styles.dart';
export 'app_dimensions.dart';

/// AppTheme — ThemeData centralizado de Aviso Vital
abstract class AppTheme {
  // ── Alias de compatibilidad con código anterior ───────────────────
  static Color get background    => AppColors.background;
  static Color get surface       => AppColors.surface;
  static Color get userButton    => AppColors.amber;
  static Color get adminButton   => AppColors.orange;
  static Color get alert         => AppColors.danger;
  static Color get primaryText   => AppColors.textPrimary;
  static Color get secondaryText => AppColors.textSecondary;

  // ── ThemeData principal ───────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:                 AppColors.amber,
        onPrimary:               AppColors.textOnAmber,
        secondary:               AppColors.orange,
        onSecondary:             AppColors.textOnOrange,
        surface:                 AppColors.surface,
        onSurface:               AppColors.textPrimary,
        error:                   AppColors.danger,
        onError:                 AppColors.textPrimary,
        outline:                 AppColors.surfaceBorder,
        surfaceContainerHighest: AppColors.surfaceRaised,
      ),

      // ── AppBar ────────────────────────────────────────────────────
      // Sin const — titleTextStyle usa AppTextStyles
      appBarTheme: AppBarTheme(
        backgroundColor:        AppColors.background,
        foregroundColor:        AppColors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h3,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness:     Brightness.dark,
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────
      // Sin const — textStyle usa AppTextStyles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.amber,
          foregroundColor:         AppColors.textOnAmber,
          disabledBackgroundColor: AppColors.amber.withValues(alpha: 0.4),
          elevation:               0,
          minimumSize:             const Size(double.infinity, 56),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle:               AppTextStyles.buttonLarge,
          padding:                 AppSpacing.paddingButton,
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────
      // Sin const — textStyle usa AppTextStyles
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side:            const BorderSide(color: AppColors.surfaceBorder),
          minimumSize:     const Size(double.infinity, 52),
          shape:           const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle:       AppTextStyles.button,
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────
      // Sin const — textStyle usa AppTextStyles
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber,
          minimumSize:     const Size(48, 48),
          textStyle:       AppTextStyles.button,
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────
      // Sin const — hintStyle y errorStyle usan AppTextStyles
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AppColors.surface,
        hintStyle:      AppTextStyles.body.copyWith(color: AppColors.textDisabled),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:   BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:   BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:   BorderSide(color: AppColors.amber, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:   BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:   BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
      ),

      // ── Card ──────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side:         BorderSide(color: AppColors.surfaceBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.surfaceBorder,
        thickness: 1,
        space:     1,
      ),

      // ── Chip ──────────────────────────────────────────────────────
      // Sin const — labelStyle usa AppTextStyles
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor:   AppColors.amber.withValues(alpha: 0.2),
        disabledColor:   AppColors.surface,
        labelStyle:      AppTextStyles.label,
        padding:         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
          side:         BorderSide(color: AppColors.surfaceBorder),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────────────
      // Sin const — titleTextStyle y contentTextStyle usan AppTextStyles
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side:         const BorderSide(color: AppColors.surfaceBorder),
        ),
        titleTextStyle:   AppTextStyles.h3,
        contentTextStyle: AppTextStyles.body,
      ),

      // ── BottomSheet ───────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:      AppColors.surfaceRaised,
        modalBackgroundColor: AppColors.surfaceRaised,
        elevation:            0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.modal),
      ),

      // ── TabBar ────────────────────────────────────────────────────
      // Sin const — labelStyle y unselectedLabelStyle usan AppTextStyles
      tabBarTheme: TabBarThemeData(
        labelColor:            AppColors.amber,
        unselectedLabelColor:  AppColors.textTertiary,
        indicatorColor:        AppColors.amber,
        indicatorSize:         TabBarIndicatorSize.label,
        labelStyle:            AppTextStyles.labelLarge,
        unselectedLabelStyle:  AppTextStyles.label,
        dividerColor:          AppColors.surfaceBorder,
      ),

      // ── ProgressIndicator ─────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.amber,
        linearTrackColor: AppColors.surfaceBorder,
      ),

      // ── FloatingActionButton ──────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.textOnAmber,
        elevation:       0,
        shape:           CircleBorder(),
      ),

      // ── NavigationRail ────────────────────────────────────────────
      // Sin const — selectedLabelTextStyle y unselectedLabelTextStyle usan AppTextStyles
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:          AppColors.surface,
        selectedIconTheme:         const IconThemeData(color: AppColors.amber, size: 24),
        unselectedIconTheme:       const IconThemeData(color: AppColors.textTertiary, size: 24),
        selectedLabelTextStyle:    AppTextStyles.label.copyWith(color: AppColors.amber),
        unselectedLabelTextStyle:  AppTextStyles.label,
        indicatorColor:            AppColors.amber.withValues(alpha: 0.15),
      ),

      // ── SnackBar ──────────────────────────────────────────────────
      // Sin const — contentTextStyle usa AppTextStyles
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.surfaceRaised,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side:         const BorderSide(color: AppColors.surfaceBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Switch ────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.textOnAmber
              : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.amber
              : AppColors.surfaceRaised),
      ),

      // ── Checkbox ─────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.amber
              : Colors.transparent),
        checkColor: WidgetStateProperty.all(AppColors.textOnAmber),
        side:  const BorderSide(color: AppColors.surfaceBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}