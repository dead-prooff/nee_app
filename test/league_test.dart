import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/core/utils/dates.dart';
import 'package:nee_app/features/league/league_models.dart';
import 'package:nee_app/features/league/league_provider.dart';
import 'package:nee_app/features/league/ranking_view.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:nee_app/features/social/friends.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  group('Fechas de la liga', () {
    test('la semana empieza el lunes', () {
      // 14/10/2026 es miércoles.
      expect(weekKey(DateTime(2026, 10, 14, 15)), '2026-10-12');
      expect(weekKey(DateTime(2026, 10, 12)), '2026-10-12');
      expect(weekKey(DateTime(2026, 10, 18, 23, 59)), '2026-10-12');
      expect(weekKey(DateTime(2026, 10, 19)), '2026-10-19');
      expect(previousWeekKey('2026-11-02'), '2026-10-26');
    });

    test('progreso de la semana y días que faltan', () {
      expect(weekProgress(DateTime(2026, 10, 12)), 0);
      expect(weekProgress(DateTime(2026, 10, 15, 12)), closeTo(0.5, 0.001));
      expect(daysLeftInWeek(DateTime(2026, 10, 12)), 7);
      expect(daysLeftInWeek(DateTime(2026, 10, 18)), 1);
    });
  });

  group('Tabla', () {
    test('el XP simulado es estable y crece durante la semana', () {
      final f = friends.first;
      int xp(double p) => simulatedFriendXp(
        f,
        week: '2026-10-12',
        league: League.bronze,
        progress: p,
      );
      expect(xp(0), 0);
      expect(xp(0.5), xp(0.5), reason: 'determinístico');
      expect(xp(0.3), lessThanOrEqualTo(xp(0.6)));
      expect(xp(0.6), lessThanOrEqualTo(xp(1)));
      expect(xp(1), greaterThan(0));
    });

    test('10 amigos + vos, ordenados por XP', () {
      final table = buildStandings(
        league: League.silver,
        week: '2026-10-12',
        progress: 0.5,
        myXp: 40,
        myName: 'Ana',
      );
      expect(table, hasLength(11));
      expect(table.where((e) => e.isMe), hasLength(1));
      for (var i = 1; i < table.length; i++) {
        expect(table[i - 1].xp, greaterThanOrEqualTo(table[i].xp));
        expect(table[i].rank, i + 1);
      }
    });

    test('zonas: suben los 3 primeros y bajan los 2 últimos', () {
      Map<Zone, int> zones(League league) {
        final table = buildStandings(
          league: league,
          week: '2026-10-12',
          progress: 0.5,
          myXp: 0,
          myName: 'Ana',
        );
        return {
          for (final z in Zone.values)
            z: table.where((e) => e.zone == z).length,
        };
      }

      expect(zones(League.bronze), {
        Zone.promotion: 3,
        Zone.safe: 8,
        Zone.demotion: 0,
      });
      expect(zones(League.silver), {
        Zone.promotion: 3,
        Zone.safe: 6,
        Zone.demotion: 2,
      });
      expect(zones(League.gold), {
        Zone.promotion: 0,
        Zone.safe: 9,
        Zone.demotion: 2,
      });
    });
  });

  group('LeagueProvider', () {
    late StorageService storage;
    late DateTime now;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      now = DateTime(2026, 10, 14, 10); // miércoles
    });

    (ProgressProvider, LeagueProvider) create() {
      final progress = ProgressProvider(storage, clock: () => now);
      return (progress, LeagueProvider(storage, progress, clock: () => now));
    }

    test('arranca en Bronce', () {
      final (_, league) = create();
      expect(league.league, League.bronze);
      expect(league.results, isEmpty);
    });

    test('al cambiar de semana, el primero sube de liga', () async {
      final (progress, _) = create();
      await progress.addXp(5000);

      now = DateTime(2026, 10, 19, 9); // lunes siguiente
      final (_, league) = create();
      expect(league.league, League.silver);
      expect(league.results.single.promoted, isTrue);
      expect(league.results.single.rank, 1);
    });

    test('sin XP en Plata, al cambiar de semana baja', () async {
      await storage.setString('league.current', 'silver');
      create();

      now = DateTime(2026, 10, 19, 9);
      final (_, league) = create();
      expect(league.league, League.bronze);
      expect(league.results.single.demoted, isTrue);
    });

    test('el XP semanal vuelve a 0 y recuerda la semana anterior', () async {
      final (progress, _) = create();
      await progress.addXp(30);
      expect(progress.weekXp, 30);

      now = DateTime(2026, 10, 19, 9);
      final (progress2, _) = create();
      expect(progress2.weekXp, 0);
      await progress2.addXp(10);
      expect(progress2.weekXp, 10);
      expect(progress2.xpOfWeek('2026-10-12'), 30);
      expect(progress2.totalXp, 40);
    });

    test('simular cierre no cierra dos veces la misma semana', () async {
      final (progress, league) = create();
      await progress.addXp(5000);
      final result = league.closeWeekNow();
      expect(result.promoted, isTrue);
      expect(league.league, League.silver);

      now = DateTime(2026, 10, 19, 9);
      final (_, next) = create();
      expect(next.results, hasLength(1));
      expect(next.league, League.silver);
    });
  });

  testWidgets('la pestaña Ranking muestra la liga, tu puesto y las zonas', (
    tester,
  ) async {
    // Pantalla alta para que entren las 11 filas sin scrollear.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      prefs: onboardedPrefs,
      clock: () => DateTime(2026, 10, 14, 10),
    );
    await tester.tap(find.text('Ranking').last);
    await tester.pumpAndSettle();

    expect(find.text('Liga Bronce'), findsOneWidget);
    expect(
      find.textContaining('Faltan 5 días para que cierre la liga.'),
      findsOneWidget,
    );
    expect(find.textContaining('Zona de ascenso a Plata'), findsOneWidget);
    expect(find.textContaining('Zona de descenso'), findsNothing);

    final rows = find.descendant(
      of: find.byType(RankingView),
      matching: find.bySemanticsLabel(RegExp(r'^Puesto \d+:')),
    );
    expect(rows, findsNWidgets(11));
    expect(find.bySemanticsLabel(RegExp(r'^Puesto \d+: vos, 0 XP')), findsOne);
    expect(find.text('VOS'), findsOneWidget);
  });
}
