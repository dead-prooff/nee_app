import 'dart:math';

import '../../lessons/data/lesson_models.dart';
import 'duel_models.dart';

/// Arma las preguntas de un duelo a partir del contenido de las lecciones:
/// los ejercicios de "elegir traducción" y cada par de los de "emparejar".
class DuelQuestionBuilder {
  DuelQuestionBuilder(this.units, {Random? random})
    : _random = random ?? Random();

  static const questionCount = 5;

  final List<Unit> units;
  final Random _random;

  /// Elige [questionCount] preguntas distintas. Usa las lecciones ya
  /// completadas si alcanzan; si no, todo el contenido.
  List<DuelQuestion> build({bool Function(String lessonId)? isCompleted}) {
    final lessons = units.expand((u) => u.lessons).toList();
    final done = isCompleted == null
        ? <Lesson>[]
        : lessons.where((l) => isCompleted(l.id)).toList();

    var pool = _questionsFrom(done);
    if (pool.length < questionCount) pool = _questionsFrom(lessons);
    pool.shuffle(_random);
    return pool.take(questionCount).toList();
  }

  List<DuelQuestion> _questionsFrom(List<Lesson> lessons) {
    final byPrompt = <String, DuelQuestion>{};
    for (final lesson in lessons) {
      for (final ex in lesson.exercises) {
        switch (ex) {
          case ChoiceExercise():
            byPrompt[ex.prompt] = DuelQuestion(
              instruction: ex.direction == Direction.guaraniToSpanish
                  ? '¿Qué significa?'
                  : '¿Cómo se dice en guaraní?',
              prompt: ex.prompt,
              options: [...ex.options]..shuffle(_random),
              answer: ex.answer,
            );
          case MatchExercise(:final pairs):
            for (final pair in pairs) {
              byPrompt[pair.guarani] = DuelQuestion(
                instruction: '¿Qué significa?',
                prompt: pair.guarani,
                // Las otras traducciones del mismo ejercicio son las
                // opciones incorrectas.
                options: [for (final p in pairs) p.spanish]..shuffle(_random),
                answer: pair.spanish,
              );
            }
          case BuildExercise() || ListenExercise():
            break;
        }
      }
    }
    return byPrompt.values.toList();
  }
}
