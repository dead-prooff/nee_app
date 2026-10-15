import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// En pantallas anchas (la web en una compu) muestra la app en una columna
/// del ancho de un celular, centrada y con un fondo suave a los costados.
///
/// Además le dice a la app que la pantalla mide [maxWidth] de ancho, así
/// los diseños, diálogos y avisos se acomodan a la columna y no a la ventana.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  static const maxWidth = 480.0;

  /// Por debajo de este ancho la app ocupa toda la pantalla (no tendría
  /// sentido dejar costados de pocos píxeles).
  static const breakpoint = maxWidth + 48;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!enabled || media.size.width < breakpoint) return child;

    final dark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: dark ? AppColors.frameSideDark : AppColors.frameSide,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(
                color: dark ? AppColors.outlineDark : AppColors.outline,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.4 : 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: SizedBox(
            width: maxWidth,
            child: ClipRect(
              child: MediaQuery(
                data: media.copyWith(size: Size(maxWidth, media.size.height)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
