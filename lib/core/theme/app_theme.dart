import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colores de feedback de ejercicios (acierto / error), accesibles desde
/// cualquier widget con `Theme.of(context).extension<FeedbackColors>()!`.
@immutable
class FeedbackColors extends ThemeExtension<FeedbackColors> {
  const FeedbackColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.fire,
    required this.gold,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color fire;
  final Color gold;

  static const light = FeedbackColors(
    success: AppColors.green,
    successContainer: AppColors.greenLight,
    onSuccessContainer: AppColors.greenDark,
    error: AppColors.error,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorDark,
    fire: AppColors.fire,
    gold: AppColors.gold,
  );

  static const dark = FeedbackColors(
    success: AppColors.greenDarkMode,
    successContainer: AppColors.successContainerDark,
    onSuccessContainer: AppColors.onSuccessContainerDark,
    error: AppColors.errorDarkMode,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    fire: AppColors.fire,
    gold: AppColors.gold,
  );

  @override
  FeedbackColors copyWith() => this;

  @override
  FeedbackColors lerp(FeedbackColors? other, double t) {
    if (other == null) return this;
    return FeedbackColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      fire: Color.lerp(fire, other.fire, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Nunito';

  static ThemeData get light => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: Colors.white,
          primaryContainer: AppColors.greenLight,
          onPrimaryContainer: AppColors.greenDark,
          secondary: AppColors.orange,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.orangeLight,
          onSecondaryContainer: const Color(0xFF6B2205),
          surface: AppColors.surface,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textMuted,
          surfaceContainerLowest: AppColors.background,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
          error: AppColors.error,
          onError: Colors.white,
        ),
        background: AppColors.background,
        feedback: FeedbackColors.light,
      );

  static ThemeData get dark => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.greenDarkMode,
          onPrimary: AppColors.onGreenDarkMode,
          primaryContainer: AppColors.successContainerDark,
          onPrimaryContainer: AppColors.onSuccessContainerDark,
          secondary: AppColors.orangeDarkMode,
          onSecondary: AppColors.onOrangeDarkMode,
          secondaryContainer: const Color(0xFF4A2210),
          onSecondaryContainer: const Color(0xFFFFDBCB),
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textDark,
          onSurfaceVariant: AppColors.textMutedDark,
          surfaceContainerLowest: AppColors.backgroundDark,
          outline: AppColors.outlineDark,
          outlineVariant: AppColors.outlineDark,
          error: AppColors.errorDarkMode,
          onError: const Color(0xFF3B0907),
        ),
        background: AppColors.backgroundDark,
        feedback: FeedbackColors.dark,
      );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color background,
    required FeedbackColors feedback,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      // Garantiza áreas táctiles de al menos 48x48 en todos los botones.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [feedback],
    );

    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    const radius = BorderRadius.all(Radius.circular(16));
    const minSize = Size(48, 52);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        headlineMedium:
            text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.3,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 17),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline, width: 2),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        errorMaxLines: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
    );
  }
}
