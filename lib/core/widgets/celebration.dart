import 'package:flutter/material.dart';

/// Si el usuario pidió reducir animaciones en el sistema.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Hace aparecer [child] con un rebote (para festejos cortos). Sin
/// animación si el sistema pide reducir movimiento.
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final total = delay + duration;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        // Espera [delay] y después rebota hasta su tamaño.
        final p = start >= 1
            ? 1.0
            : ((t - start) / (1 - start)).clamp(0.0, 1.0);
        final scale = Curves.elasticOut.transform(p);
        return Opacity(
          opacity: (p * 3).clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.3 + 0.7 * scale, child: child),
        );
      },
      child: child,
    );
  }
}

/// Número que sube contando desde 0 (por ejemplo, "+15 XP").
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // La versión final para lectores de pantalla; el conteo es solo visual.
    final text = '$prefix$value$suffix';
    if (reduceMotion(context)) return Text(text, style: style);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) =>
            Text('$prefix${v.round()}$suffix', style: style),
      ),
    );
  }
}
