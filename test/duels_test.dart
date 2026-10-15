import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/core/theme/app_theme.dart';
import 'package:nee_app/features/duels/data/duel_models.dart';
import 'package:nee_app/features/duels/data/duel_questions.dart';
import 'package:nee_app/features/duels/duel_provider.dart';
import 'package:nee_app/features/duels/duel_screen.dart';
import 'package:nee_app/features/duels/duels_view.dart';
import 'package:nee_app/features/lessons/data/lesson_models.dart';
import 'package:nee_app/features/onboarding/user_provider.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

List<Unit> _loadUnits() {
  final json = jsonDecode(
    File('assets/data/lecciones.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final u in json['unidades'] as List)
      Unit.fromJson(u as Map<String, dynamic>),
  ];
}

/// 5 preguntas con respuesta "si1".."si5" y opción incorrecta "no1".."no5".
final _questions = [
  for (var i = 1; i <= 5; i++)
    DuelQuestion(
      instruction: '¿Qué significa?',
      prompt: 'Pregunta $i',
      options: ['si$i', 'no$i'],
      answer: 'si$i',
    ),
];

List<RivalAnswer> _rival(List<bool> correct, {int ms = 3000}) => [
  for (final c in correct) RivalAnswer(correct: c, ms: ms),
];

void main() {
  group('Preguntas', () {
    final units = _loadUnits();

    test('arma 5 preguntas distintas con la respuesta entre las opciones', () {
      for (var seed = 0; seed < 20; seed++) {
        final qs = DuelQuestionBuilder(units, random: Random(seed)).build();
        expect(qs, hasLength(5));
        expect(qs.map((q) => q.prompt).toSet(), hasLength(5));
        for (final q in qs) {
          expect(q.options, contains(q.answer));
        }
      }
    });

    test('usa las lecciones completadas si alcanzan', () {
      final qs = DuelQuestionBuilder(
        units,
        random: Random(1),
      ).build(isCompleted: (id) => id == 'u3l2');
      final lesson = units.last.lessons.last;
      final prompts = {
        for (final ex in lesson.exercises)
          if (ex is ChoiceExercise) ex.prompt,
        for (final ex in lesson.exercises)
          if (ex is MatchExercise) ...ex.pairs.map((p) => p.guarani),
      };
      expect(qs.every((q) => prompts.contains(q.prompt)), isTrue);
    });
  });

  test('resultado: más aciertos gana; si empatan, el más rápido', () {
    DuelOutcome c(int a, int b, int ma, int mb) =>
        DuelOutcome.compare(a, b, myMs: ma, rivalMs: mb);
    expect(c(4, 3, 40000, 1000), DuelOutcome.win, reason: 'aciertos mandan');
    expect(c(2, 3, 1000, 40000), DuelOutcome.loss);
    expect(c(3, 3, 12000, 15000), DuelOutcome.win, reason: 'más rápido');
    expect(c(3, 3, 15000, 12000), DuelOutcome.loss);
    expect(c(3, 3, 12000, 12000), DuelOutcome.draw);
  });

  test('el rival simulado responde dentro del tiempo', () {
    final random = Random(7);
    for (final friend in friends) {
      for (var i = 0; i < 200; i++) {
        final a = RivalAnswer.simulate(friend, random);
        if (a.ms != null) expect(a.ms, inInclusiveRange(1800, 9500));
      }
    }
  });

  group('DuelProvider', () {
    late StorageService storage;
    var now = DateTime(2026, 10, 15, 12);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      now = DateTime(2026, 10, 15, 12);
    });

    DuelProvider create() =>
        DuelProvider(storage, random: Random(3), clock: () => now);

    test('la primera vez llegan 2 desafíos pendientes', () {
      final p = create();
      expect(p.pending.map((d) => d.friendId), ['lucia', 'mati']);
      expect(p.pending.first.rivalAnswers, hasLength(5));
    });

    test('jugar un pendiente lo saca de la lista y guarda el récord', () async {
      final p = create();
      await p.recordResult(
        DuelOutcome.win,
        friend: friends.first,
        myScore: 4,
        rivalScore: 2,
        pendingId: p.pending.first.id,
      );
      await p.recordResult(
        DuelOutcome.loss,
        friend: friends[1],
        myScore: 1,
        rivalScore: 3,
      );

      final reloaded = create();
      expect(reloaded.pending, hasLength(1));
      expect(reloaded.wins, 1);
      expect(reloaded.losses, 1);
      expect(reloaded.played, 2);
      expect(reloaded.history.first.friendId, friends[1].id);
      expect(reloaded.history.last.myScore, 4);
    });

    test('sin pendientes, al otro día llega un desafío nuevo', () async {
      final p = create();
      for (final d in p.pending) {
        await p.recordResult(
          DuelOutcome.draw,
          friend: d.friend,
          myScore: 2,
          rivalScore: 2,
          pendingId: d.id,
        );
      }
      expect(create().pending, isEmpty, reason: 'mismo día: no llega otro');

      now = DateTime(2026, 10, 16, 9);
      expect(create().pending, hasLength(1));
    });
  });

  group('Pantalla de duelo', () {
    late ProgressProvider progress;
    late DuelProvider duels;

    Future<void> pumpDuel(
      WidgetTester tester,
      DuelSetup setup, {
      StorageService? existing,
    }) async {
      if (existing == null) SharedPreferences.setMockInitialValues({});
      final storage = existing ?? await StorageService.init();
      progress = ProgressProvider(storage);
      duels = DuelProvider(storage, random: Random(1));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider.value(value: duels),
            ChangeNotifierProvider(create: (_) => UserProvider(storage)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: DuelScreen(setup: setup),
          ),
        ),
      );
    }

    // Ojo: no usar pumpAndSettle mientras corre el reloj de una pregunta,
    // porque avanzaría los 10 segundos y se acabaría el tiempo.
    Future<void> answer(WidgetTester tester, String option) async {
      await tester.tap(find.text(option));
      await tester.pump();
      await tester.pump(DuelScreen.revealTime);
      await tester.pump(const Duration(milliseconds: 500)); // transición
    }

    testWidgets('acertar todo contra un rival con 2 aciertos es victoria', (
      tester,
    ) async {
      await pumpDuel(
        tester,
        DuelSetup(
          friend: friends.first,
          questions: _questions,
          rivalAnswers: _rival([true, true, false, false, false]),
        ),
      );
      final firstPending = duels.pending.first.id;

      expect(find.text('Pregunta 1 de 5'), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        await answer(tester, 'si$i');
      }

      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.text('5 – 2'), findsOneWidget);
      expect(find.text('+15 XP'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.text('Revancha'), findsOneWidget);
      expect(duels.wins, 1);
      expect(progress.xpToday, 15);
      expect(progress.streak, 1);
      // Este duelo no era un pendiente: los pendientes siguen ahí.
      expect(duels.pending.first.id, firstPending);
    });

    testWidgets('responder un pendiente lo saca de la lista', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final pending = DuelProvider(storage, random: Random(1)).pending.first;
      await pumpDuel(
        tester,
        DuelSetup(
          friend: pending.friend,
          questions: _questions,
          rivalAnswers: _rival([true, true, true, true, true]),
          pendingId: pending.id,
        ),
        existing: storage,
      );
      // pumpDuel crea un DuelProvider nuevo que lee los mismos pendientes.
      expect(duels.pending.map((p) => p.id), contains(pending.id));

      for (var i = 1; i <= 5; i++) {
        await answer(tester, 'no$i');
      }
      expect(find.text('Perdiste'), findsOneWidget);
      expect(find.text('+3 XP'), findsOneWidget);
      expect(duels.pending.map((p) => p.id), isNot(contains(pending.id)));
      expect(duels.losses, 1);
    });

    testWidgets('mismos aciertos: gana el que respondió más rápido', (
      tester,
    ) async {
      // El rival tarda 3 s en cada una; acá se responde al instante.
      await pumpDuel(
        tester,
        DuelSetup(
          friend: friends.first,
          questions: _questions,
          rivalAnswers: _rival([true, true, true, false, false]),
        ),
      );
      await answer(tester, 'si1');
      await answer(tester, 'si2');
      await answer(tester, 'si3');
      await answer(tester, 'no4');
      await answer(tester, 'no5');

      expect(find.text('3 – 3'), findsOneWidget);
      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.textContaining('Desempate por tiempo'), findsOneWidget);
      expect(find.textContaining('Tiempo total: vos '), findsOneWidget);
      expect(duels.wins, 1);
      expect(duels.history.single.myScore, 3);
    });

    testWidgets('mismos aciertos pero más lento: pierde', (tester) async {
      // El rival tarda 0,5 s; acá se esperan 2 s antes de cada respuesta.
      await pumpDuel(
        tester,
        DuelSetup(
          friend: friends.first,
          questions: _questions,
          rivalAnswers: _rival([true, true, false, false, false], ms: 500),
        ),
      );
      for (final option in ['si1', 'si2', 'no3', 'no4', 'no5']) {
        await tester.pump(const Duration(seconds: 2));
        await answer(tester, option);
      }

      expect(find.text('2 – 2'), findsOneWidget);
      expect(find.text('Perdiste'), findsOneWidget);
      expect(find.textContaining('Desempate por tiempo'), findsOneWidget);
      expect(duels.losses, 1);
    });

    testWidgets('el rival "ya respondió" a su tiempo y se revela al final', (
      tester,
    ) async {
      await pumpDuel(
        tester,
        DuelSetup(
          friend: friends.first,
          questions: _questions,
          rivalAnswers: _rival([true, true, true, true, true], ms: 4000),
        ),
      );
      expect(find.text('Pensando…'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Pensando…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Ya respondió'), findsOneWidget);

      await tester.tap(find.text('si1'));
      await tester.pump();
      expect(find.text('Acertó'), findsOneWidget);
    });

    testWidgets('a los 10 segundos se acaba el tiempo y cuenta como error', (
      tester,
    ) async {
      await pumpDuel(
        tester,
        DuelSetup(
          friend: friends.first,
          questions: _questions,
          rivalAnswers: _rival([false, false, false, false, false]),
        ),
      );
      expect(find.text('10 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7, milliseconds: 100));
      expect(find.text('3 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('¡Se acabó el tiempo!'), findsOneWidget);

      await tester.pump(DuelScreen.revealTime);
      await tester.pump();
      expect(find.text('Pregunta 2 de 5'), findsOneWidget);
    });
  });

  testWidgets('la pestaña Duelos muestra pendientes y amigos', (tester) async {
    await pumpApp(tester, prefs: onboardedPrefs);
    await tester.tap(find.text('Duelos').last);
    await tester.pumpAndSettle();

    expect(find.text('Duelos pendientes'), findsOneWidget);
    expect(find.text('Lucía te desafió'), findsOneWidget);
    expect(find.text('Mati te desafió'), findsOneWidget);

    final challengeRosa = find.descendant(
      of: find.ancestor(
        of: find.text('Doña Rosa'),
        matching: find.byType(Card),
      ),
      matching: find.byType(OutlinedButton),
    );
    await tester.scrollUntilVisible(
      challengeRosa,
      200,
      // La pestaña Inicio también tiene una lista (IndexedStack).
      scrollable: find
          .descendant(
            of: find.byType(DuelsView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(challengeRosa);
    await tester.pumpAndSettle();
    await tester.tap(challengeRosa);
    await tester.pumpAndSettle();
    expect(find.text('¡Empezar!'), findsOneWidget);

    await tester.tap(find.text('¡Empezar!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pregunta 1 de 5'), findsOneWidget);
  });
}
