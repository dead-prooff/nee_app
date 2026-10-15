import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/core/theme/app_theme.dart';
import 'package:nee_app/features/home/home_view.dart';
import 'package:nee_app/features/lessons/data/lesson_repository.dart';
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
    expect(find.text('15 XP'), findsOneWidget);
    expect(find.text('15 / 20 XP'), findsOneWidget);
  });

  testWidgets('tocar la lección disponible la abre', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text("¡Mba'éichapa!"));
    await tester.pumpAndSettle();
    expect(find.text('Comprobar'), findsOneWidget);
  });
}
