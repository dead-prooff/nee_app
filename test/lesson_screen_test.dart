import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/theme/app_theme.dart';
import 'package:nee_app/features/lessons/data/lesson_models.dart';
import 'package:nee_app/features/lessons/lesson_screen.dart';

const _lesson = Lesson(
  id: 'test',
  title: 'Prueba',
  xp: 10,
  exercises: [
    ChoiceExercise(
      direction: Direction.guaraniToSpanish,
      prompt: 'Aguyje',
      options: ['Gracias', 'Hola'],
      answer: 'Gracias',
    ),
    BuildExercise(
      direction: Direction.spanishToGuarani,
      prompt: 'Quiero pan',
      answer: 'Aipota mbujape',
      extras: ['kamby'],
    ),
    MatchExercise(
      pairs: [
        (guarani: 'Y', spanish: 'Agua'),
        (guarani: 'Ka\'a', spanish: 'Yerba'),
      ],
    ),
  ],
);

Future<void> _open(WidgetTester tester, {Lesson lesson = _lesson}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _check(WidgetTester tester) async {
  await tester.tap(find.text('Comprobar'));
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('completar sin errores da XP base + bonus', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Gracias'));
    await tester.pump();
    await _check(tester);
    expect(find.text('¡Iporã! Correcto'), findsOneWidget);
    await _continue(tester);

    await tester.tap(find.text('Aipota'));
    await tester.pump();
    await tester.tap(find.text('mbujape'));
    await tester.pump();
    await _check(tester);
    expect(find.text('¡Iporã! Correcto'), findsOneWidget);
    await _continue(tester);

    for (final (gn, es) in [('Y', 'Agua'), ('Ka\'a', 'Yerba')]) {
      await tester.tap(find.text(gn));
      await tester.pump();
      await tester.tap(find.text(es));
      await tester.pump();
    }
    await _check(tester);
    await _continue(tester);

    expect(find.text('¡Lección completada!'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
  });

  testWidgets('un error muestra la respuesta correcta y resta una vida', (
    tester,
  ) async {
    await _open(tester);
    expect(find.bySemanticsLabel('3 vidas'), findsOneWidget);

    await tester.tap(find.text('Hola'));
    await tester.pump();
    await _check(tester);

    expect(find.text('Incorrecto'), findsOneWidget);
    expect(find.text('Respuesta correcta:'), findsOneWidget);
    expect(find.bySemanticsLabel('2 vidas'), findsOneWidget);
  });

  testWidgets('sin vidas se pierde la lección y se puede reintentar', (
    tester,
  ) async {
    // Con un solo ejercicio, cada error lo vuelve a poner en la fila.
    await _open(
      tester,
      lesson: Lesson(
        id: 'uno',
        title: 'Uno',
        xp: 10,
        exercises: [_lesson.exercises.first],
      ),
    );

    for (var i = 0; i < LessonScreen.maxLives; i++) {
      await tester.tap(find.text('Hola'));
      await tester.pump();
      await _check(tester);
      await _continue(tester);
    }

    expect(find.text('Te quedaste sin vidas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('+0'), findsOneWidget);
  });
}
