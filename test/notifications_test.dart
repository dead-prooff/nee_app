import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/core/utils/dates.dart';
import 'package:nee_app/features/duels/data/duel_models.dart';
import 'package:nee_app/features/duels/duel_provider.dart';
import 'package:nee_app/features/league/league_provider.dart';
import 'package:nee_app/features/notifications/messages.dart';
import 'package:nee_app/features/notifications/notification_models.dart';
import 'package:nee_app/features/notifications/notifications_provider.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  group('mensajes.json', () {
    final raw = jsonDecode(
      File(Messages.path).readAsStringSync(),
    ) as Map<String, dynamic>;
    final messages = testMessages();
    const vars = {
      'nombre',
      'dias',
      'dias_txt',
      'meta',
      'liga',
      'emoji',
      'puesto',
      'marcador',
    };

    test('al menos 4 mensajes por tipo de aviso', () {
      for (final kind in MessageKind.values) {
        final min = kind.key.startsWith('bienvenida') ? 1 : 4;
        expect(
          messages.of(kind).length,
          greaterThanOrEqualTo(min),
          reason: kind.key,
        );
      }
    });

    test('solo usa variables conocidas y todo tiene título', () {
      for (final kind in MessageKind.values) {
        for (final m in raw[kind.key] as List) {
          final map = m as Map<String, dynamic>;
          expect((map['titulo'] as String).trim(), isNotEmpty);
          final text = '${map['titulo']} ${map['texto'] ?? ''}';
          for (final v in RegExp(r'\{(\w+)\}').allMatches(text)) {
            expect(vars, contains(v[1]), reason: '${kind.key}: $text');
          }
        }
      }
    });

    test('incluye las expresiones pedidas tal cual', () {
      List<String> titles(MessageKind k) =>
          messages.of(k).map((m) => m.title).toList();
      expect(titles(MessageKind.streakLost), contains('Omano la nde racha 💀'));
      expect(
        titles(MessageKind.streakActive),
        contains('Hendy hína tu racha 🔥'),
      );
      expect(
        titles(MessageKind.streakKavaju),
        contains('Tu racha hendy kavaju resa 🐴✨'),
      );
      expect(
        titles(MessageKind.streakDanger),
        contains('Hake la nde racha! 🔥'),
      );
    });

    test('rellena variables y no repite el último mensaje', () {
      final text = messages.render(MessageKind.duelLost, 1, {
        'nombre': 'Nico',
        'marcador': '1 a 4',
      });
      expect(
        text.body,
        'Nico te ganó 1 a 4. Pero la revancha está a un toque.',
      );

      final random = Random(5);
      final count = messages.of(MessageKind.duelWon).length;
      for (var last = 0; last < count; last++) {
        for (var i = 0; i < 20; i++) {
          final picked = messages.pick(
            MessageKind.duelWon,
            random,
            recent: [last],
          );
          expect(picked, isNot(last));
        }
      }
    });
  });

  group('NotificationsProvider', () {
    late StorageService storage;
    late DateTime now;
    late ProgressProvider progress;
    late DuelProvider duels;
    late LeagueProvider league;

    NotificationsProvider create() {
      progress = ProgressProvider(storage, clock: () => now);
      duels = DuelProvider(storage, clock: () => now);
      league = LeagueProvider(storage, progress, clock: () => now);
      return NotificationsProvider(
        storage,
        messages: testMessages(),
        progress: progress,
        duels: duels,
        league: league,
        clock: () => now,
        random: Random(1),
      );
    }

    Iterable<AppNotification> withId(NotificationsProvider n, String prefix) =>
        n.items.where((x) => x.id.startsWith(prefix));

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      now = DateTime(2026, 10, 14, 10);
    });

    test('la primera vez: bienvenida + un aviso por cada desafío', () {
      final n = create();
      expect(n.ofType(NotificationType.duel), hasLength(2));
      expect(n.ofType(NotificationType.league), hasLength(1));
      expect(n.ofType(NotificationType.streak), hasLength(1));
      expect(n.unreadCount, 4);
      final duelTexts = n
          .ofType(NotificationType.duel)
          .map((x) => '${x.title} ${x.body}');
      expect(duelTexts.where((t) => t.contains('Lucía')), hasLength(1));
      expect(duelTexts.where((t) => t.contains('Mati')), hasLength(1));
    });

    test('practicar: racha activa y meta cumplida (una vez por día)', () async {
      final n = create();
      await progress.addXp(10);
      expect(withId(n, 'streak-active-'), hasLength(1));
      expect(withId(n, 'goal-'), isEmpty, reason: '10 de 20 XP');

      await progress.addXp(10);
      expect(withId(n, 'goal-'), hasLength(1));
      expect(withId(n, 'goal-').single.body, contains('20'));

      await progress.addXp(10);
      expect(withId(n, 'streak-active-'), hasLength(1));
      expect(withId(n, 'goal-'), hasLength(1));
    });

    test('desde 7 días de racha usa los mensajes "kavaju resa"', () async {
      await storage.setInt('progress.streak', 6);
      await storage.setString('progress.lastActiveDate', '2026-10-13');
      final n = create();
      await progress.addXp(10);
      expect(progress.streak, 7);

      final messages = testMessages();
      final kavajuTitles = [
        for (var i = 0; i < messages.of(MessageKind.streakKavaju).length; i++)
          messages.render(MessageKind.streakKavaju, i, {
            'dias': 7,
            'dias_txt': 'días',
          }).title,
      ];
      expect(kavajuTitles, contains(withId(n, 'streak-active-').single.title));
    });

    test('racha en peligro si hoy todavía no practicó', () async {
      create();
      await progress.addXp(10);

      now = DateTime(2026, 10, 15, 9); // al otro día, sin practicar
      final n = create();
      expect(withId(n, 'streak-danger-'), hasLength(1));

      // No se repite el mismo día.
      n.sync();
      expect(withId(n, 'streak-danger-'), hasLength(1));
    });

    test('racha perdida al pasar un día entero sin practicar', () async {
      create();
      await progress.addXp(10);

      now = DateTime(2026, 10, 16, 9); // se saltó el 15
      final n = create();
      final lost = withId(n, 'streak-lost-');
      expect(lost, hasLength(1));
      expect(withId(n, 'streak-danger-'), isEmpty);
    });

    test('duelo ganado y perdido generan avisos con el marcador', () async {
      final n = create();
      await duels.recordResult(
        DuelOutcome.win,
        friend: friendById('nico'),
        myScore: 4,
        rivalScore: 1,
      );
      await duels.recordResult(
        DuelOutcome.loss,
        friend: friendById('rosa'),
        myScore: 2,
        rivalScore: 5,
      );
      final results = withId(n, 'duelres-').toList();
      expect(results, hasLength(2));
      final texts = results.map((x) => '${x.title} ${x.body}').join(' | ');
      expect(texts, contains('Nico'));
      expect(texts, contains('Doña Rosa'));
    });

    test('subir de liga genera un aviso con la liga nueva', () async {
      create();
      await progress.addXp(5000);

      now = DateTime(2026, 10, 19, 9);
      final n = create();
      final up = withId(n, 'league-').single;
      expect(
        '${up.title} ${up.body}',
        anyOf(contains('Plata'), contains('🥈')),
      );
    });

    test('jugar un desafío pendiente marca su aviso como leído', () async {
      final n = create();
      final pending = duels.pending.first;
      await duels.recordResult(
        DuelOutcome.win,
        friend: pending.friend,
        myScore: 3,
        rivalScore: 2,
        pendingId: pending.id,
      );

      final notif = n.items.firstWhere((x) => x.id == 'duel-${pending.id}');
      expect(notif.read, isTrue);
    });

    test('marcar leído (uno, por tipo y todos) se guarda', () {
      var n = create();
      final first = n.items.first;
      n.markRead(first.id);
      expect(n.unreadCount, 3);

      n.markAllRead(type: NotificationType.duel);
      expect(n.unreadOf(NotificationType.duel), 0);

      n = create();
      expect(n.items.firstWhere((x) => x.id == first.id).read, isTrue);
      expect(n.unreadOf(NotificationType.duel), 0);

      n.markAllRead();
      expect(n.unreadCount, 0);
    });
  });

  test('hora de los avisos', () {
    final now = DateTime(2026, 10, 14, 18);
    expect(clockLabel(DateTime(2026, 10, 14, 9, 5), now), 'Hoy, 09:05');
    expect(clockLabel(DateTime(2026, 10, 13, 22, 30), now), 'Ayer, 22:30');
    expect(clockLabel(DateTime(2026, 10, 2, 7, 0), now), '02/10, 07:00');
  });

  group('Pestaña Avisos', () {
    Future<void> openAvisos(WidgetTester tester) async {
      await pumpApp(
        tester,
        prefs: onboardedPrefs,
        clock: () => DateTime(2026, 10, 14, 10),
      );
      await tester.tap(find.text('Avisos').last);
      await tester.pumpAndSettle();
    }

    testWidgets('el globito muestra los no leídos', (tester) async {
      await openAvisos(tester);
      expect(find.byTooltip('Avisos, 4 sin leer'), findsOneWidget);
      expect(find.text('4 sin leer'), findsOneWidget);
    });

    testWidgets('filtrar por Duelos muestra solo desafíos', (tester) async {
      await openAvisos(tester);
      await tester.tap(find.text('Duelos (2)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lucía'), findsOneWidget);
      expect(find.textContaining('Mati'), findsOneWidget);
      expect(find.textContaining('liga semanal'), findsNothing);
    });

    testWidgets('tocar un aviso lo marca leído y abre Duelos', (tester) async {
      await openAvisos(tester);
      await tester.tap(find.textContaining('Lucía'));
      await tester.pumpAndSettle();

      expect(find.text('Duelos pendientes'), findsOneWidget);
      expect(find.byTooltip('Avisos, 3 sin leer'), findsOneWidget);
    });

    testWidgets('"Marcar todo como leído" deja todo leído', (tester) async {
      await openAvisos(tester);
      await tester.tap(find.text('Marcar todo como leído'));
      await tester.pumpAndSettle();

      expect(find.text('Todo leído'), findsOneWidget);
      expect(find.byTooltip('Avisos'), findsOneWidget);
      expect(find.text('Marcar todo como leído'), findsNothing);
    });
  });
}
