import 'package:flutter/material.dart';

/// Paleta de Ñe'ẽ.
///
/// Todos los pares texto/fondo fueron verificados con la fórmula de contraste
/// WCAG 2.1 y cumplen nivel AA (>= 4.5:1). Los valores medidos están al lado.
class AppColors {
  AppColors._();

  // ---------- Modo claro ----------
  static const green = Color(0xFF1B7F4F); // blanco encima: 5.01
  static const greenLight = Color(0xFFDCF5E7);
  static const greenDark = Color(0xFF0B4A2C); // sobre greenLight: 8.99

  static const orange = Color(0xFFC2410C); // blanco encima: 5.18
  static const orangeLight = Color(0xFFFFE7D9);

  /// Naranja vivo, solo para íconos/decoración (fuego de racha). 3.39:1,
  /// suficiente para elementos gráficos (WCAG pide 3:1), NO usar en texto.
  static const fire = Color(0xFFE8553D);
  static const gold = Color(0xFFF2B705);
  static const onGold = Color(0xFF3D2E00); // sobre gold: 7.27

  static const background = Color(0xFFFAF7F0); // texto encima: 14.83
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C2421);
  static const textMuted = Color(0xFF5B6661); // sobre fondo: 5.58
  static const outline = Color(0xFFD9D4C7);

  static const error = Color(0xFFB42318); // sobre blanco: 6.57
  static const errorLight = Color(0xFFFDE4E1);
  static const errorDark = Color(0xFF7A1A12); // sobre errorLight: 8.75

  // ---------- Modo oscuro ----------
  static const greenDarkMode = Color(0xFF5CD69A); // sobre fondo: 10.05
  static const onGreenDarkMode = Color(0xFF05301C);
  static const orangeDarkMode = Color(0xFFFF9466); // sobre fondo: 8.43
  static const onOrangeDarkMode = Color(0xFF3A1200);

  static const backgroundDark = Color(0xFF111614);
  static const surfaceDark = Color(0xFF1B2320);
  static const textDark = Color(0xFFE6ECE9); // sobre fondo: 15.27
  static const textMutedDark = Color(0xFFA9B5AF); // sobre superficie: 7.58
  static const outlineDark = Color(0xFF34403B);

  static const errorDarkMode = Color(0xFFFF8A80);
  static const successContainerDark = Color(0xFF123826);
  static const onSuccessContainerDark = Color(0xFFB9F0D2); // 10.16
  static const errorContainerDark = Color(0xFF4A1611);
  static const onErrorContainerDark = Color(0xFFFFD3CE); // 10.93
}
