import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/app_links.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/duels/data/duel_models.dart';
import 'package:nee_app/features/duels/duel_provider.dart';
import 'package:nee_app/features/league/league_provider.dart';
import 'package:nee_app/features/onboarding/user_provider.dart';
import 'package:nee_app/features/profile/avatars.dart';
import 'package:nee_app/features/profile/badges.dart';
import 'package:nee_app/features/profile/invite_screen.dart';
import 'package:nee_app/features/profile/widgets/badge_widgets.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  group('Avatares', () {
    test('cada avatar tiene su SVG y su ficha', () {
      expect(avatars, hasLength(12));
      for (final a in avatars) {
        expect(File(a.asset).existsSync(), isTrue, reason: a.asset);
        expect(a.description.length, greaterThan(20), reason: a.id);
      }
      expect(avatars.where((a) => a.isMyth), hasLength(8));
    });

    test('los 10 amigos tienen avatares distintos de la grilla', () {
      final ids = avatars.map((a) => a.id).toSet();
      for (final f in friends) {
        expect(ids, contains(f.avatar), reason: f.name);
      }
      expect(friends.map((f) => f.avatar).toSet(), hasLength(friends.length));
    });
  });

  group('Código de invitación', () {
    test('se arma con el usuario y siempre da lo mismo', () {
      final code = UserProvider.inviteCodeFor('willy');
      expect(code, matches(RegExp(r'^NEE-WILLY\d{2}$')));
      expect(UserProvider.inviteCodeFor('willy'), code);
      expect(UserProvider.inviteCodeFor('ana_py'), startsWith('NEE-ANAPY'));
    });

    test('formato válido', () {
      expect(UserProvider.isValidInviteCode('NEE-WILLY23'), isTrue);
      expect(UserProvider.isValidInviteCode('nee-willy23'), isTrue);
      expect(UserProvider.isValidInviteCode('NEE-AB'), isFalse);
      expect(UserProvider.isValidInviteCode('WILLY23'), isFalse);
    });

    test('el mensaje para compartir trae el código y el link', () {
      final text = InviteScreen.shareText('NEE-WILLY23');
      expect(text, contains('NEE-WILLY23'));
      expect(text, contains(appUrl));
      expect(text, contains('+50 XP'));
    });
  });

  group('insignias.json', () {
    final raw = jsonDecode(
      File(BadgeCatalog.path).readAsStringSync(),
    ) as Map<String, dynamic>;

    test('tiene las 8 pedidas y más, con todos los textos', () {
      final catalog = testBadgeCatalog();
      final names = catalog.badges.map((b) => b.name).toList();
      expect(
        names,
        containsAll([
          'Primer mborayhu',
          'Hendy hína',
          'Kavaju resa',
          'Rey del tereré',
          'Mbarete',
          'Le ganaste a Doña Rosa',
          'Liga Oro',
          "Che ra'a",
        ]),
      );
      expect(catalog.badges.length, greaterThan(8));
      for (final b in catalog.badges) {
        expect(b.howTo, isNotEmpty);
        expect(b.celebration, isNotEmpty);
        expect(b.emoji, isNotEmpty);
      }
      expect(
        (raw['insignias'] as List).map((b) => (b as Map)['id']).toSet(),
        hasLength(catalog.badges.length),
        reason: 'ids únicos',
      );
    });
  });

  group('BadgeProvider', () {
    late StorageService storage;
    late ProgressProvider progress;
    late DuelProvider duels;
    late LeagueProvider league;
    late UserProvider user;
    final now = DateTime(2026, 10, 14, 10);

    BadgeProvider create() {
      progress = ProgressProvider(storage, clock: () => now);
      duels = DuelProvider(storage, clock: () => now);
      league = LeagueProvider(storage, progress, clock: () => now);
      user = UserProvider(storage, clock: () => now);
      return BadgeProvider(
        storage,
        catalog: testBadgeCatalog(),
        progress: progress,
        duels: duels,
        league: league,
        user: user,
        clock: () => now,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
    });

    test('arranca sin insignias', () {
      final b = create();
      expect(b.unlockedCount, 0);
      expect(b.nextCelebration, isNull);
    });

    test('primera lección: "Primer mborayhu" con festejo', () async {
      final b = create();
      await progress.completeLesson('u1l1', xp: 10);
      expect(b.isUnlocked('primer_mborayhu'), isTrue);
      expect(b.nextCelebration?.name, 'Primer mborayhu');
      b.celebrationShown();
      expect(b.nextCelebration, isNull);
    });

    test('lección sin errores: "Chipa caliente"', () async {
      final b = create();
      await progress.completeLesson('u1l1', xp: 15, perfect: true);
      expect(b.isUnlocked('chipa_caliente'), isTrue);
    });

    test('ganarle a Doña Rosa y ganar 5 duelos', () async {
      final b = create();
      await duels.recordResult(
        DuelOutcome.win,
        friend: friendById('rosa'),
        myScore: 3,
        rivalScore: 2,
      );
      expect(b.isUnlocked('dona_rosa'), isTrue);
      expect(b.isUnlocked('mbarete'), isFalse);
      for (var i = 0; i < 4; i++) {
        await duels.recordResult(
          DuelOutcome.win,
          friend: friendById('nico'),
          myScore: 5,
          rivalScore: 1,
        );
      }
      expect(b.isUnlocked('mbarete'), isTrue);
      expect(b.isUnlocked('pya_e'), isTrue, reason: '5 de 5');
    });

    test('invitar a un amigo: "Che ra\'a"', () async {
      final b = create();
      await user.markInvitedFriend();
      expect(b.isUnlocked('che_raa'), isTrue);
    });

    test('se guardan y la primera vez se desbloquean sin festejo', () async {
      // Simula a alguien que ya tenía progreso antes de esta versión.
      await storage.setStringList('progress.completedLessons', ['u1l1']);
      final b = create();
      expect(b.isUnlocked('primer_mborayhu'), isTrue);
      expect(b.nextCelebration, isNull, reason: 'sin catarata de festejos');

      final again = create();
      expect(again.isUnlocked('primer_mborayhu'), isTrue);
    });

    test('el texto para compartir trae el link oficial', () {
      final b = testBadgeCatalog().badges.first;
      expect(badgeShareText(b), contains(appUrl));
    });
  });

  group('Pestaña Perfil', () {
    Future<void> openProfile(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        prefs: {
          ...onboardedPrefs,
          'user.username': 'willy',
          'user.registeredAt': '2026-10-15T09:00:00.000',
          'progress.streak': 2,
          'progress.longestStreak': 5,
          'progress.totalXp': 120,
          'progress.completedLessons': ['u1l1', 'u1l2'],
          'duels.wins': 3,
        },
        clock: () => DateTime(2026, 10, 14, 10),
      );
      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
    }

    testWidgets('muestra encabezado, estadísticas e insignias', (tester) async {
      await openProfile(tester);

      expect(find.text('Ana'), findsWidgets);
      expect(find.text('@willy'), findsOneWidget);
      expect(find.text('Se unió el 15 de octubre de 2026'), findsOneWidget);

      expect(find.bySemanticsLabel('Racha más larga: 5 días'), findsOneWidget);
      expect(find.bySemanticsLabel('XP total: 120'), findsOneWidget);
      expect(find.bySemanticsLabel('Lecciones completadas: 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Duelos ganados: 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Liga actual: 🥉 Bronce'), findsOneWidget);

      // Ya tenía progreso: "Primer mborayhu" desbloqueada, el resto no.
      expect(find.textContaining('Insignias (2 de'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Insignia Primer mborayhu, desbloqueada'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Insignia Mbarete, bloqueada')),
        findsOneWidget,
      );
      expect(find.text('Ganá 5 duelos.'), findsOneWidget);

      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Invitar amigos'), findsOneWidget);
    });

    testWidgets('invitar: muestra el código, copia y festeja "Che ra\'a"', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await openProfile(tester);
      await tester.tap(find.text('Invitar amigos'));
      await tester.pumpAndSettle();

      final code = UserProvider.inviteCodeFor('willy');
      expect(find.text(code), findsOneWidget);
      expect(find.textContaining('+50 XP'), findsWidgets);

      await tester.tap(find.text('Copiar código'));
      await tester.pumpAndSettle();
      expect(copied, code);
      expect(find.text('¡Insignia nueva!'), findsOneWidget);
      expect(find.text("Che ra'a"), findsWidgets);

      await tester.tap(find.text('¡Iporã!'));
      await tester.pumpAndSettle();
      expect(find.text('¡Insignia nueva!'), findsNothing);
    });

    testWidgets('cambiar avatar desde el Perfil', (tester) async {
      await openProfile(tester);
      await tester.tap(find.byTooltip('Cambiar avatar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ao Ao'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Oveja salvaje'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final user = Provider.of<UserProvider>(
        tester.element(find.text('@willy')),
        listen: false,
      );
      expect(user.avatarId, 'ao_ao');
    });
  });
}
