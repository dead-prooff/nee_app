import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/duels/duel_provider.dart';
import 'package:nee_app/features/forum/forum_models.dart';
import 'package:nee_app/features/forum/forum_provider.dart';
import 'package:nee_app/features/league/league_provider.dart';
import 'package:nee_app/features/notifications/notifications_provider.dart';
import 'package:nee_app/features/onboarding/user_provider.dart';
import 'package:nee_app/features/profile/badges.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  group('ForumProvider', () {
    late StorageService storage;
    late DateTime now;

    ForumProvider create() =>
        ForumProvider(storage, seed: testForumSeed(), clock: () => now);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      now = DateTime(2026, 10, 14, 10);
    });

    test('carga los temas de ejemplo con sus respuestas', () {
      final f = create();
      expect(f.topics, hasLength(8));
      final rosa = f.topicById('t-mbaeichapa')!;
      expect(rosa.authorId, 'rosa');
      expect(rosa.replies, hasLength(3));
      expect(f.likesOf(rosa), 24);
    });

    test('filtra por categoría, busca sin tildes y ordena', () {
      final f = create();
      final dudas = f.filteredTopics(category: ForumCategory.dudas);
      expect(dudas, hasLength(2));
      expect(dudas.every((t) => t.category == ForumCategory.dudas), isTrue);

      expect(f.filteredTopics(query: 'terere'), isNotEmpty);
      expect(f.filteredTopics(query: 'terere').first.title, contains('tereré'));
      expect(f.filteredTopics(query: 'zzz no existe'), isEmpty);

      final recent = f.filteredTopics();
      for (var i = 1; i < recent.length; i++) {
        expect(
          recent[i - 1].createdAt.isAfter(recent[i].createdAt) ||
              recent[i - 1].createdAt == recent[i].createdAt,
          isTrue,
        );
      }
      final popular = f.filteredTopics(sort: ForumSort.popular);
      for (var i = 1; i < popular.length; i++) {
        expect(
          f.popularity(popular[i - 1]),
          greaterThanOrEqualTo(f.popularity(popular[i])),
        );
      }
    });

    test(
      'un tema nuevo recibe respuesta de un amigo y likes con el tiempo',
      () async {
        final f = create();
        final topic = await f.createTopic(
          title: '¿Cómo se dice abuelo?',
          category: ForumCategory.dudas,
          body: 'Siempre me olvido cómo se dice abuelo en guaraní.',
        );
        expect(f.topicById(topic.id)!.replies, isEmpty);
        expect(f.likesOf(topic), 0);

        now = now.add(const Duration(minutes: 1));
        final replies = f.topicById(topic.id)!.replies;
        expect(replies, hasLength(1));
        expect(replies.single.authorId, 'ramon', reason: 'dudas: Don Ramón');

        now = now.add(const Duration(minutes: 30));
        expect(f.likesOf(topic), inInclusiveRange(3, 8));
      },
    );

    test('una corrección llega a "Revisión de la comunidad"', () async {
      final f = create();
      final c = await f.addLessonComment(
        lessonId: 'u1l1',
        tag: CommentTag.correccion,
        body: 'Creo que se escribe con tilde nasal.',
      );
      expect(f.isCommunityReview(c), isFalse);
      expect(f.hasPopularCorrection, isFalse);

      now = now.add(const Duration(minutes: 10));
      final again = f.lessonCommentById('u1l1', c.id)!;
      expect(f.likesOf(again), greaterThanOrEqualTo(ForumProvider.reviewLikes));
      expect(f.isCommunityReview(again), isTrue);
      expect(f.hasPopularCorrection, isTrue);
      expect(again.replies.single.authorId, 'rosa');
    });

    test('las correcciones de ejemplo muy votadas ya están destacadas', () {
      final f = create();
      final comments = f.lessonComments('u1l1');
      expect(comments.first.tag, CommentTag.correccion, reason: 'más votado');
      expect(f.isCommunityReview(comments.first), isTrue);
      expect(f.lessonCommentCount('u1l1'), 3);
    });

    test('likes, "útil", reportar y todo se guarda', () async {
      final f = create();
      await f.toggleLike('t-che-nde');
      expect(f.likesOf(f.topicById('t-che-nde')!), 12);

      final mine = await f.createTopic(
        title: 'Mi tema de prueba',
        category: ForumCategory.charla,
        body: 'Hola a todos, ¿cómo andan con las lecciones?',
      );
      now = now.add(const Duration(minutes: 2));
      final reply = f.topicById(mine.id)!.replies.single;
      expect(f.isUseful(f.topicById(mine.id)!, reply), isFalse);
      await f.toggleUseful(reply.id);
      expect(f.isUseful(f.topicById(mine.id)!, reply), isTrue);

      await f.report('t-emparejar');
      expect(f.topicById('t-emparejar'), isNull);

      final reloaded = create();
      expect(reloaded.likedByMe('t-che-nde'), isTrue);
      expect(reloaded.topicById(mine.id), isNotNull);
      expect(reloaded.topicById('t-emparejar'), isNull);
      expect(reloaded.isUseful(reloaded.topicById(mine.id)!, reply), isTrue);
    });

    test('respuestas útiles en temas de otros (para "Mbo\'ehára")', () async {
      final f = create();
      for (var i = 0; i < 20 && f.myUsefulReplies < 5; i++) {
        await f.reply('t-che-nde', 'Respuesta número $i para ayudar.');
        now = now.add(const Duration(minutes: 3));
      }
      expect(f.myUsefulReplies, greaterThanOrEqualTo(5));
    });
  });

  group('Avisos e insignias del foro', () {
    late StorageService storage;
    late DateTime now;
    late ForumProvider forum;
    late NotificationsProvider notifications;
    late BadgeProvider badges;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      now = DateTime(2026, 10, 14, 10);
      final progress = ProgressProvider(storage, clock: () => now);
      final duels = DuelProvider(storage, clock: () => now);
      final league = LeagueProvider(storage, progress, clock: () => now);
      final user = UserProvider(storage, clock: () => now);
      forum = ForumProvider(storage, seed: testForumSeed(), clock: () => now);
      notifications = NotificationsProvider(
        storage,
        messages: testMessages(),
        progress: progress,
        duels: duels,
        league: league,
        forum: forum,
        clock: () => now,
        random: Random(1),
      );
      badges = BadgeProvider(
        storage,
        catalog: testBadgeCatalog(),
        progress: progress,
        duels: duels,
        league: league,
        user: user,
        forum: forum,
        clock: () => now,
      );
    });

    test('"Doña Rosa respondió tu comentario" y "A 5 personas…"', () async {
      await forum.addLessonComment(
        lessonId: 'u3l2',
        tag: CommentTag.correccion,
        body: 'En mi casa decimos distinto la frase de la guampa.',
      );
      now = now.add(const Duration(minutes: 10));
      forum.refresh();

      final texts = notifications.items.map((n) => '${n.title} | ${n.body}');
      expect(
        texts.where((t) => t.contains('Doña Rosa')),
        isNotEmpty,
        reason: texts.join('\n'),
      );
      expect(texts.where((t) => t.contains('5')), isNotEmpty);
      // Y la insignia nueva "Ñe'ẽ porã" (corrección con 10 likes).
      expect(badges.isUnlocked('nee_pora_comunidad'), isTrue);
    });

    test('"Mbo\'ehára" con 5 respuestas útiles', () async {
      for (var i = 0; i < 20 && forum.myUsefulReplies < 5; i++) {
        await forum.reply('t-nasales', 'Gracias, profe. Aporte número $i.');
        now = now.add(const Duration(minutes: 3));
      }
      forum.refresh();
      expect(badges.isUnlocked('mboehara'), isTrue);
    });

    test('"Curso completo" reemplaza a la vieja "Ñe\'ẽ porã"', () {
      final names = badges.all.map((b) => b.name).toList();
      expect(names, contains('Curso completo'));
      expect(names.where((n) => n == "Ñe'ẽ porã"), hasLength(1));
      expect(names, contains("Mbo'ehára"));
    });
  });

  group('Pantallas', () {
    Future<void> openForum(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        prefs: onboardedPrefs,
        clock: () => DateTime(2026, 10, 14, 10),
      );
      await tester.tap(find.text('Foro').last);
      await tester.pumpAndSettle();
    }

    testWidgets('la campanita está en Inicio y el Foro en la barra', (
      tester,
    ) async {
      await pumpApp(tester, prefs: onboardedPrefs);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Avisos'), findsNothing, reason: 'ya no es pestaña');
      await tester.tap(find.text('Foro').last);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.text('Nuevo tema'), findsOneWidget);
    });

    testWidgets('buscar y filtrar temas', (tester) async {
      await openForum(tester);
      expect(
        find.text('¿Quién más estudia con tereré en la mano? 🧉'),
        findsOne,
      );

      await tester.tap(find.text('Correcciones de guaraní'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sobre la ortografía: las vocales nasales y el puso'),
        findsOneWidget,
      );
      expect(
        find.text('¿Quién más estudia con tereré en la mano? 🧉'),
        findsNothing,
      );

      await tester.tap(find.text('Todos'));
      await tester.enterText(find.byType(TextField).first, 'emparejar');
      await tester.pumpAndSettle();
      expect(find.textContaining('no me sale el ejercicio'), findsOneWidget);
      expect(
        find.text('¿Quién más estudia con tereré en la mano? 🧉'),
        findsNothing,
      );
    });

    testWidgets('nuevo tema: valida, muestra las normas y publica', (
      tester,
    ) async {
      await openForum(tester);
      await tester.tap(find.text('Nuevo tema'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí un título'), findsOneWidget);
      expect(find.text('Elegí una categoría'), findsOneWidget);
      expect(find.text('Contá un poco más'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        '¿Cómo se dice abuelo?',
      );
      await tester.tap(find.text('Categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dudas').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto'),
        'Siempre me olvido cómo se dice abuelo en guaraní 😅',
      );
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();

      // Primera vez: normas de la comunidad.
      expect(find.text('Normas de la comunidad'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo se dice abuelo?'), findsOneWidget);
      expect(find.text('Todavía no hay respuestas'), findsOneWidget);
    });

    testWidgets('en un tema: like, responder y reportar', (tester) async {
      await openForum(tester);
      await tester.tap(
        find.text('¿Quién más estudia con tereré en la mano? 🧉'),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('9 me gusta'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('9 me gusta'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('10 me gusta'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Yo también, con menta 🌿',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Yo también, con menta 🌿'), findsOneWidget);
      expect(find.text('3 respuestas'), findsOneWidget);

      await tester.tap(find.byTooltip('Reportar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Es spam o publicidad'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gracias por avisar'), findsOneWidget);
      expect(find.text('Este tema ya no está disponible.'), findsOneWidget);
    });

    testWidgets('comentarios de la lección desde un ejercicio', (tester) async {
      await openForum(tester);
      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text("¡Mba'éichapa!"));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Comentarios de la lección (3)'));
      await tester.pumpAndSettle();
      expect(find.text('Comentarios (3)'), findsOneWidget);
      expect(find.text('Revisión de la comunidad'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Corrección'));
      await tester.enterText(find.byType(TextField), 'Yo lo escribo con g̃.');
      await tester.pump();
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Comentarios (4)'), findsOneWidget);
      expect(find.text('Yo lo escribo con g̃.'), findsOneWidget);
    });
  });
}
