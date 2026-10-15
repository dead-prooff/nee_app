import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/settings/settings_provider.dart';

/// Vibraciones de la app. No vibra si el usuario desactivó "Sonido y
/// vibración" en Configuración.
class Haptics {
  Haptics._();

  static bool _enabled(BuildContext context) =>
      Provider.of<SettingsProvider?>(context, listen: false)?.soundEnabled ??
      true;

  /// Respuesta correcta.
  static void success(BuildContext context) {
    if (_enabled(context)) HapticFeedback.selectionClick();
  }

  /// Respuesta incorrecta.
  static void error(BuildContext context) {
    if (_enabled(context)) HapticFeedback.mediumImpact();
  }

  /// Error leve (por ejemplo, un par mal emparejado).
  static void light(BuildContext context) {
    if (_enabled(context)) HapticFeedback.lightImpact();
  }
}
