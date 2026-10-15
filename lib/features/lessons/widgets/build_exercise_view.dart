import 'package:flutter/material.dart';

import '../data/lesson_models.dart';
import 'exercise_common.dart';

/// "Armá la frase" tocando las palabras en orden.
class BuildExerciseView extends StatefulWidget {
  const BuildExerciseView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.onChanged,
  });

  final BuildExercise exercise;
  final bool locked;
  final AnswerChanged onChanged;

  @override
  State<BuildExerciseView> createState() => _BuildExerciseViewState();
}

class _BuildExerciseViewState extends State<BuildExerciseView> {
  /// Palabras disponibles, mezcladas. Se trabaja por índice porque una frase
  /// puede repetir palabras ("che sy ha che ru").
  late final List<String> _bank = [
    ...widget.exercise.answerWords,
    ...widget.exercise.extras,
  ]..shuffle();

  /// Índices de [_bank] en el orden en que se eligieron.
  final List<int> _chosen = [];

  void _update(VoidCallback change) {
    setState(change);
    if (_chosen.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final built = _chosen.map((i) => _bank[i]).join(' ');
    widget.onChanged(built == widget.exercise.answerWords.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ex = widget.exercise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseHeader(
          instruction: ex.direction == Direction.spanishToGuarani
              ? 'Armá la frase en guaraní'
              : 'Armá la traducción',
          prompt: ex.prompt,
          hint: ex.hint,
        ),
        const SizedBox(height: 24),
        // Zona de respuesta: tocar una palabra la devuelve al banco.
        Semantics(
          label: _chosen.isEmpty ? 'Tu respuesta: vacía' : 'Tu respuesta',
          container: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.outline, width: 2),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in _chosen)
                  AnswerTile(
                    key: ValueKey('chosen-$i'),
                    label: _bank[i],
                    compact: true,
                    state: TileState.selected,
                    onTap: widget.locked
                        ? null
                        : () => _update(() => _chosen.remove(i)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < _bank.length; i++)
              _chosen.contains(i)
                  // Hueco con el tamaño de la palabra, para que el banco
                  // no se reacomode al elegir.
                  ? ExcludeSemantics(
                      child: Opacity(
                        opacity: 0.35,
                        child: AnswerTile(label: _bank[i], compact: true),
                      ),
                    )
                  : AnswerTile(
                      key: ValueKey('bank-$i'),
                      label: _bank[i],
                      compact: true,
                      onTap: widget.locked
                          ? null
                          : () => _update(() => _chosen.add(i)),
                    ),
          ],
        ),
      ],
    );
  }
}
