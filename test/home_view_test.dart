import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/core/theme/app_theme.dart';
import 'package:nee_app/features/home/home_view.dart';
import 'package:nee_app/features/lessons/data/lesson_repository.dart';
import 'package:nee_app/features/onboarding/user_provider.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/file_asset_bundle.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await StorageService.init();
  // Pantalla alta para que entre todo el camino sin scrollear.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => LessonRepository(bundle: FileAssetBundle())),
        ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeView()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  testWidgets('sin progreso: solo la primera lección está abierta', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(
      find.bySemanticsLabel("Lección 1: ¡Mba'éichapa!, siguiente lección"),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'bloqueada$')), findsNWidgets(5));
    expect(find.text('¡Empezá!'), findsOneWidget);
    expect(find.text('0 días de racha'), findsOneWidget);
    expect(find.text('0 / 20 XP'), findsOneWidget);
  });

  testWidgets('tocar un nodo bloqueado avisa y no abre la lección', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Presentarse y despedirse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completá la lección anterior'), findsOneWidget);
    expect(find.text('Comprobar'), findsNothing);
  });

  testWidgets('con progreso guardado muestra racha, XP y nodos completados', (
    tester,
  ) async {
    final today = _day(DateTime.now());
    await _pumpHome(
      tester,
      prefs: {
        'progress.completedLessons': ['u1l1', 'u1l2'],
        'progress.totalXp': 30,
        'progress.xpToday': 15,
        'progress.xpDate': today,
        'progress.streak': 3,
        'progress.lastActiveDate': today,
      },
    );

    expect(find.bySemanticsLabel(RegExp(r'completada$')), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(
        'Lección 3: Mamá, papá y abuelos, siguiente lección',
      ),
      findsOneWidget,
    );
    expect(find.text('3 días de racha'), findsOneWidget);
    expect(find.text('Hendy hína 🔥'), findsOneWidget);
    expect(find.text('15 XP'), findsOneWidget);
    expect(find.text('15 / 20 XP'), findsOneWidget);
  });

  testWidgets('tocar la lección disponible la abre', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text("¡Mba'éichapa!"));
    await tester.pumpAndSettle();
    expect(find.text('Comprobar'), findsOneWidget);
  });

  testWidgets('con 7 días o más muestra "Hendy kavaju resa"', (tester) async {
    final today = _day(DateTime.now());
    await _pumpHome(
      tester,
      prefs: {
        'progress.streak': 8,
        'progress.lastActiveDate': today,
        'progress.xpToday': 10,
        'progress.xpDate': today,
      },
    );
    expect(find.text('8 días de racha'), findsOneWidget);
    expect(find.text('Hendy kavaju resa 🐴✨'), findsOneWidget);
  });

  testWidgets('si hoy no practicó, no muestra "Hendy hína"', (tester) async {
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
    await _pumpHome(
      tester,
      prefs: {'progress.streak': 2, 'progress.lastActiveDate': yesterday},
    );
    expect(find.textContaining('Hendy'), findsNothing);
    expect(find.text('Hacé una lección hoy para no perderla'), findsOneWidget);
  });

  group('Nivel inicial', () {
    Future<int> openLessons(WidgetTester tester, String level) async {
      await _pumpHome(tester, prefs: {'user.level': level});
      return find
          .bySemanticsLabel(
            RegExp(r'^Lección \d+: .*(siguiente lección|disponible)$'),
          )
          .evaluate()
          .length;
    }

    testWidgets('"Nunca hablé" empieza de cero', (tester) async {
      expect(await openLessons(tester, 'none'), 1);
    });

    testWidgets('"Entiendo algo" abre las primeras lecciones', (tester) async {
      expect(await openLessons(tester, 'some'), 2);
      expect(find.bySemanticsLabel(RegExp(r'bloqueada$')), findsNWidgets(4));
    });

    testWidgets('"Hablo jopara" abre la Unidad 1 completa', (tester) async {
      expect(await openLessons(tester, 'jopara'), 3);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Lección 3: Mamá, papá y abuelos, disponible$'),
        ),
        findsOneWidget,
      );
      // Abiertas, pero no completadas: no regala XP ni insignias.
      expect(find.bySemanticsLabel(RegExp(r'completada$')), findsNothing);
    });
  });
}
