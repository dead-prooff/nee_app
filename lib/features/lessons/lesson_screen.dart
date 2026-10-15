import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../progress/progress_provider.dart';
import 'data/lesson_models.dart';
import 'lesson_result_screen.dart';
import 'widgets/build_exercise_view.dart';
import 'widgets/choice_exercise_view.dart';
import 'widgets/feedback_panel.dart';
import 'widgets/listen_exercise_view.dart';
import 'widgets/match_exercise_view.dart';

/// Resultado de una lección, terminada o perdida por quedarse sin vidas.
class LessonOutcome {
  const LessonOutcome({
    required this.passed,
    required this.xp,
    required this.mistakes,
    required this.correct,
    required this.livesLeft,
  });

  final bool passed;
  final int xp;
  final int mistakes;
  final int correct;
  final int livesLeft;

  /// Porcentaje de respuestas correctas sobre todas las comprobadas.
  int get accuracy {
    final answered = correct + mistakes;
    return answered == 0 ? 0 : (correct * 100 / answered).round();
  }
}

/// Pantalla donde se juega una lección, ejercicio por ejercicio.
///
/// Los ejercicios errados vuelven al final de la fila, así la lección solo
/// se completa cuando se respondió bien cada uno (o se acaban las vidas).
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  static const maxLives = 3;

  /// XP extra por terminar sin errores.
  static const perfectBonus = 5;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<Exercise> _queue = [...widget.lesson.exercises];
  int _turn = 0;
  int _completed = 0;
  int _mistakes = 0;
  int _lives = LessonScreen.maxLives;

  /// Respuesta actual del ejercicio (null = todavía no se puede comprobar).
  bool? _pending;

  /// Resultado una vez comprobado; null mientras se está respondiendo.
  bool? _result;

  Exercise get _current => _queue[_turn];
  int get _total => widget.lesson.exercises.length;

  void _check() {
    final correct = _pending!;
    if (correct) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _result = correct;
      if (correct) {
        _completed++;
      } else {
        _lives--;
        _mistakes++;
        _queue.add(_current);
      }
    });
  }

  void _continue() {
    if (_lives == 0 || _completed == _total) {
      _finish();
      return;
    }
    setState(() {
      _turn++;
      _pending = null;
      _result = null;
    });
  }

  void _finish() {
    final passed = _lives > 0;
    final outcome = LessonOutcome(
      passed: passed,
      xp: passed
          ? widget.lesson.xp + (_mistakes == 0 ? LessonScreen.perfectBonus : 0)
          : 0,
      mistakes: _mistakes,
      correct: _completed,
      livesLeft: _lives,
    );
    if (passed) {
      context.read<ProgressProvider>().completeLesson(
        widget.lesson.id,
        xp: outcome.xp,
      );
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            LessonResultScreen(lesson: widget.lesson, outcome: outcome),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la lección?'),
        content: const Text('Vas a perder el progreso de esta lección.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _exit() async {
    if (await _confirmExit() && mounted) Navigator.of(context).pop();
  }

  Widget _exerciseView() {
    final key = ValueKey(_turn);
    final locked = _result != null;
    void onChanged(bool? value) => setState(() => _pending = value);

    return switch (_current) {
      final ChoiceExercise e => ChoiceExerciseView(
        key: key,
        exercise: e,
        locked: locked,
        onChanged: onChanged,
      ),
      final BuildExercise e => BuildExerciseView(
        key: key,
        exercise: e,
        locked: locked,
        onChanged: onChanged,
      ),
      final MatchExercise e => MatchExerciseView(
        key: key,
        exercise: e,
        locked: locked,
        onChanged: onChanged,
      ),
      final ListenExercise e => ListenExerciseView(
        key: key,
        exercise: e,
        locked: locked,
        onChanged: onChanged,
      ),
    };
  }

  Widget _bottomArea() {
    final result = _result;
    if (result == null) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _pending == null ? null : _check,
            child: const Text('Comprobar'),
          ),
        ),
      );
    }

    final current = _current;
    String? label;
    String? detail;
    if (!result) {
      label = current is MatchExercise
          ? 'Los pares correctos son:'
          : 'Respuesta correcta:';
      detail = current.solution;
    } else if (current is ListenExercise && current.translation != null) {
      label = 'Significa:';
      detail = current.translation;
    }
    return FeedbackPanel(
      correct: result,
      detailLabel: label,
      detail: detail,
      onContinue: _continue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;
    final progress = _completed / _total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Salir de la lección',
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
          titleSpacing: 0,
          title: Semantics(
            label: 'Progreso: $_completed de $_total',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  builder: (_, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 14,
                    color: colors.success,
                    backgroundColor: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Semantics(
              label: _lives == 1 ? '1 vida' : '$_lives vidas',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: Row(
                    children: [
                      for (var i = 0; i < LessonScreen.maxLives; i++)
                        Icon(
                          i < _lives ? Icons.favorite : Icons.favorite_border,
                          color: colors.error,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _exerciseView(),
              ),
            ),
            _bottomArea(),
          ],
        ),
      ),
    );
  }
}
