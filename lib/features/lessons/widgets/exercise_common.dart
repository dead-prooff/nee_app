import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Lo que cada vista de ejercicio le informa a la pantalla de lección:
/// `null` si todavía no hay respuesta para comprobar, o si es correcta.
typedef AnswerChanged = void Function(bool? isCorrect);

/// Estado visual de una opción tocable.
enum TileState { idle, selected, correct, wrong, matched }

/// Opción tocable usada por todos los tipos de ejercicio.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.label,
    this.state = TileState.idle,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final TileState state;
  final VoidCallback? onTap;

  /// Versión chica para las palabras de "armar frase".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedback = theme.extension<FeedbackColors>()!;

    final (bg, border, fg) = switch (state) {
      TileState.idle => (scheme.surface, scheme.outline, scheme.onSurface),
      TileState.selected =>
        (scheme.primaryContainer, scheme.primary, scheme.onPrimaryContainer),
      TileState.correct || TileState.matched => (
          feedback.successContainer,
          feedback.success,
          feedback.onSuccessContainer,
        ),
      TileState.wrong =>
        (feedback.errorContainer, feedback.error, feedback.onErrorContainer),
    };
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      button: true,
      selected: state == TileState.selected,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(
            color: border,
            width: state == TileState.idle ? 2 : 2.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? 48 : 56,
                minWidth: 48,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 16,
                  vertical: compact ? 10 : 14,
                ),
                child: Center(
                  widthFactor: compact ? 1 : null,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Consigna del ejercicio, con la frase a trabajar y una pista opcional.
class ExerciseHeader extends StatelessWidget {
  const ExerciseHeader({
    super.key,
    required this.instruction,
    this.prompt,
    this.hint,
  });

  final String instruction;
  final String? prompt;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(instruction, style: theme.textTheme.titleLarge),
        ),
        if (prompt != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              prompt!,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Lista de opciones de selección única ("elegir" y "escuchar").
///
/// Una vez comprobado ([locked]), marca en verde la correcta y en rojo la
/// elegida si estaba mal.
class OptionList extends StatelessWidget {
  const OptionList({
    super.key,
    required this.options,
    required this.answer,
    required this.selected,
    required this.locked,
    required this.onSelect,
  });

  final List<String> options;
  final String answer;
  final String? selected;
  final bool locked;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    TileState stateFor(String option) {
      if (locked) {
        if (option == answer) return TileState.correct;
        if (option == selected) return TileState.wrong;
        return TileState.idle;
      }
      return option == selected ? TileState.selected : TileState.idle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          AnswerTile(
            label: option,
            state: stateFor(option),
            onTap: locked ? null : () => onSelect(option),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
