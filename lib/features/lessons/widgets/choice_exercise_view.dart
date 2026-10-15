import 'package:flutter/material.dart';

import '../data/lesson_models.dart';
import 'exercise_common.dart';

/// "Elegí la traducción correcta".
class ChoiceExerciseView extends StatefulWidget {
  const ChoiceExerciseView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.onChanged,
  });

  final ChoiceExercise exercise;
  final bool locked;
  final AnswerChanged onChanged;

  @override
  State<ChoiceExerciseView> createState() => _ChoiceExerciseViewState();
}

class _ChoiceExerciseViewState extends State<ChoiceExerciseView> {
  late final List<String> _options = [...widget.exercise.options]..shuffle();
  String? _selected;

  void _select(String option) {
    setState(() => _selected = option);
    widget.onChanged(option == widget.exercise.answer);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseHeader(
          instruction: ex.direction == Direction.guaraniToSpanish
              ? '¿Qué significa?'
              : '¿Cómo se dice en guaraní?',
          prompt: ex.prompt,
          hint: ex.hint,
        ),
        const SizedBox(height: 24),
        OptionList(
          options: _options,
          answer: ex.answer,
          selected: _selected,
          locked: widget.locked,
          onSelect: _select,
        ),
      ],
    );
  }
}
