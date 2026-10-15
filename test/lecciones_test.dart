import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/features/lessons/data/lesson_models.dart';

/// Revisa que `lecciones.json` sea coherente, para atrapar errores al editar
/// el contenido a mano (respuesta que no está entre las opciones, etc.).
void main() {
  final json = jsonDecode(
    File('assets/data/lecciones.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final units = [
    for (final u in json['unidades'] as List)
      Unit.fromJson(u as Map<String, dynamic>),
  ];

  test('3 unidades, 2 lecciones por unidad, 8 ejercicios por lección', () {
    expect(units, hasLength(3));
    for (final unit in units) {
      expect(unit.lessons, hasLength(2), reason: unit.title);
      for (final lesson in unit.lessons) {
        expect(lesson.exercises, hasLength(8), reason: lesson.title);
      }
    }
  });

  test('cada lección usa los 4 tipos de ejercicio', () {
    for (final lesson in units.expand((u) => u.lessons)) {
      final types = lesson.exercises.map((e) => e.runtimeType).toSet();
      expect(types, hasLength(4), reason: lesson.title);
    }
  });

  test('las respuestas y los audios son válidos', () {
    for (final lesson in units.expand((u) => u.lessons)) {
      for (final ex in lesson.exercises) {
        final where = '${lesson.title}: ${ex.solution}';
        switch (ex) {
          case ChoiceExercise(:final options, :final answer):
          case ListenExercise(:final options, :final answer):
            expect(options, contains(answer), reason: where);
            expect(options.toSet(), hasLength(options.length), reason: where);
          case BuildExercise(:final answerWords, :final extras):
            for (final extra in extras) {
              expect(answerWords, isNot(contains(extra)), reason: where);
            }
          case MatchExercise(:final pairs):
            expect(pairs.length, greaterThanOrEqualTo(3), reason: where);
            expect(
              pairs.map((p) => p.guarani).toSet(),
              hasLength(pairs.length),
              reason: where,
            );
            expect(
              pairs.map((p) => p.spanish).toSet(),
              hasLength(pairs.length),
              reason: where,
            );
        }
        if (ex is ListenExercise) {
          expect(
            ex.audio,
            matches(RegExp(r'^[a-z0-9_]+\.(mp3|wav|m4a)$')),
            reason: where,
          );
        }
      }
    }
  });
}
