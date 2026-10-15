import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../lessons/data/lesson_models.dart';

enum NodeState { completed, current, unlocked, locked }

/// Encabezado de cada unidad dentro del camino.
class UnitBanner extends StatelessWidget {
  const UnitBanner({
    super.key,
    required this.number,
    required this.unit,
    required this.completed,
    required this.locked,
  });

  final int number;
  final Unit unit;

  /// Cuántas lecciones de la unidad están completadas.
  final int completed;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = locked ? scheme.surfaceContainerHighest : scheme.primary;
    final fg = locked ? scheme.onSurfaceVariant : scheme.onPrimary;
    final total = unit.lessons.length;

    return Semantics(
      header: true,
      label:
          'Unidad $number: ${unit.title}. '
          '$completed de $total lecciones completadas'
          '${locked ? '. Bloqueada' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIDAD $number',
                    style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit.title,
                    style: theme.textTheme.titleLarge?.copyWith(color: fg),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed / $total lecciones',
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
            Text(unit.emoji, style: const TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }
}

/// Un nodo redondo del camino, con el título de la lección abajo.
class PathNode extends StatefulWidget {
  const PathNode({
    super.key,
    required this.lesson,
    required this.number,
    required this.state,
    required this.onTap,
  });

  final Lesson lesson;
  final int number;
  final NodeState state;
  final VoidCallback onTap;

  /// Desplazamiento horizontal del nodo [index] (de -1 a 1), para que el
  /// camino serpentee como en Duolingo.
  static double sway(int index) => math.sin(index * math.pi / 4);

  @override
  State<PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<PathNode> {
  static const _size = 76.0;
  static const _depth = 6.0;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final state = widget.state;

    final (bg, fg, icon) = switch (state) {
      NodeState.completed => (colors.gold, colors.onGold, Icons.check_rounded),
      NodeState.current || NodeState.unlocked => (
        scheme.primary,
        scheme.onPrimary,
        Icons.star_rounded,
      ),
      NodeState.locked => (
        scheme.outline,
        scheme.onSurfaceVariant,
        Icons.lock_rounded,
      ),
    };
    final shade = Color.lerp(bg, Colors.black, 0.28)!;
    final stateLabel = switch (state) {
      NodeState.completed => 'completada',
      NodeState.current => 'siguiente lección',
      NodeState.unlocked => 'disponible',
      NodeState.locked => 'bloqueada',
    };
    final offset = _pressed ? _depth : 0.0;

    final node = SizedBox(
      width: _size,
      height: _size + _depth,
      child: Stack(
        children: [
          // "Relieve" inferior: el botón se hunde al tocarlo.
          Positioned(top: _depth, child: _circle(shade)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            top: offset,
            child: _circle(bg, child: Icon(icon, size: 40, color: fg)),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: 'Lección ${widget.number}: ${widget.lesson.title}, $stateLabel',
      excludeSemantics: true,
      onTap: widget.onTap,
      // Todo el nodo (círculo y título) es tocable.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: SizedBox(
          width: 168,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == NodeState.current) ...[
                _StartBubble(color: scheme.primary),
                const SizedBox(height: 6),
              ],
              if (state == NodeState.current)
                // Anillo que destaca la lección que sigue.
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.35),
                      width: 5,
                    ),
                  ),
                  child: node,
                )
              else
                node,
              const SizedBox(height: 8),
              Text(
                widget.lesson.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: state == NodeState.locked
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(Color color, {Widget? child}) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}

/// Globito "¡Empezá!" sobre la lección que sigue.
class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '¡Empezá!',
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
