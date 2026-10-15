import 'package:flutter/material.dart';

import '../../../core/services/phrase_audio.dart';
import '../data/lesson_models.dart';
import 'exercise_common.dart';

/// "Escuchá y elegí lo que oíste".
class ListenExerciseView extends StatefulWidget {
  const ListenExerciseView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.onChanged,
  });

  final ListenExercise exercise;
  final bool locked;
  final AnswerChanged onChanged;

  @override
  State<ListenExerciseView> createState() => _ListenExerciseViewState();
}

class _ListenExerciseViewState extends State<ListenExerciseView> {
  late final List<String> _options = [...widget.exercise.options]..shuffle();
  final _audio = PhraseAudio();
  String? _selected;

  /// `null` mientras se averigua si existe la grabación real.
  bool? _hasRecording;
  bool _showMeaning = false;

  @override
  void initState() {
    super.initState();
    PhraseAudio.hasRecording(widget.exercise.audio).then((value) {
      if (mounted) setState(() => _hasRecording = value);
    });
    // Suena una vez al aparecer, como en cualquier ejercicio de escucha.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _play() => _audio.play(widget.exercise.audio);

  void _select(String option) {
    setState(() => _selected = option);
    widget.onChanged(option == widget.exercise.answer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ex = widget.exercise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseHeader(instruction: 'Escuchá y elegí lo que oíste', hint: ex.hint),
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            label: 'Reproducir audio',
            button: true,
            excludeSemantics: true,
            child: FilledButton(
              onPressed: _play,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(96, 96),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.volume_up_rounded, size: 48),
            ),
          ),
        ),
        if (_hasRecording == false) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio de prueba: esta frase todavía no está grabada.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                if (ex.translation != null)
                  _showMeaning
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, left: 28),
                          child: Text(
                            'Significa: ${ex.translation}',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _showMeaning = true),
                            child: const Text('Ver qué significa'),
                          ),
                        ),
              ],
            ),
          ),
        ],
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
