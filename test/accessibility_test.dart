import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/features/duels/duels_view.dart';
import 'package:nee_app/features/forum/forum_view.dart';

import 'helpers/pump_app.dart';

/// Revisa la accesibilidad de cada pantalla, con el perfil de ejemplo
/// cargado (para que no estén vacías):
/// - áreas táctiles de al menos 48x48 (criterios de Android e iOS),
/// - todo lo tocable tiene etiqueta para TalkBack / VoiceOver,
/// - contraste de texto WCAG AA, en modo claro y oscuro,
/// - nada se corta con el texto en el tamaño más grande.
void main() {
  final clock = DateTime(2026, 10, 14, 10); // miércoles

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Cómo llegar a cada pantalla desde el inicio de la app.
  final screens = <String, Future<void> Function(WidgetTester)>{
    'Inicio': (t) async {},
    'Duelos': (t) => tab(t, 'Duelos'),
    'Ranking': (t) => tab(t, 'Ranking'),
    'Avisos': (t) => tapAndSettle(t, find.byIcon(Icons.notifications_outlined)),
    'Foro': (t) => tab(t, 'Foro'),
    'Tema del foro': (t) async {
      await tab(t, 'Foro');
      // El tema más reciente (el primero de la lista); con letra enorme
      // hay que bajar hasta verlo.
      final title = find.text('¿Quién más estudia con tereré en la mano? 🧉');
      await t.scrollUntilVisible(
        title,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ForumView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapAndSettle(t, title);
    },
    'Nuevo tema': (t) async {
      await tab(t, 'Foro');
      await tapAndSettle(t, find.text('Nuevo tema'));
    },
    'Comentarios de la lección': (t) async {
      await tapAndSettle(t, find.text('En la mesa'));
      await tapAndSettle(t, find.byIcon(Icons.chat_bubble_outline));
    },
    'Perfil': (t) => tab(t, 'Perfil'),
    'Lección': (t) => tapAndSettle(t, find.text('En la mesa')),
    'Presentación del duelo': (t) async {
      await tab(t, 'Duelos');
      // Con letra enorme el botón queda abajo: se scrollea hasta verlo.
      await t.scrollUntilVisible(
        find.text('Lucía te desafió'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(DuelsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapAndSettle(t, find.text('Jugar').first);
    },
    'Duelo en curso': (t) async {
      await tab(t, 'Duelos');
      await t.scrollUntilVisible(
        find.text('Lucía te desafió'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(DuelsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapAndSettle(t, find.text('Jugar').first);
      await t.tap(find.text('¡Empezar!'));
      // Primera pregunta con la respuesta del rival ya revelada.
      await t.pump(const Duration(seconds: 11));
    },
    'Resultado del duelo': (t) async {
      await tab(t, 'Duelos');
      await t.scrollUntilVisible(
        find.text('Lucía te desafió'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(DuelsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapAndSettle(t, find.text('Jugar').first);
      await t.tap(find.text('¡Empezar!'));
      // Sin responder, el duelo corre solo: 10 s por pregunta y la pausa
      // que muestra cada resultado.
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 11));
        await t.pump(const Duration(seconds: 2));
      }
      await t.pumpAndSettle();
      expect(find.text('Volver a Duelos'), findsOneWidget);
    },
    'Invitar amigos': (t) async {
      await tab(t, 'Perfil');
      await tapAndSettle(t, find.text('Invitar amigos'));
    },
    'Cambiar avatar': (t) async {
      await tab(t, 'Perfil');
      await tapAndSettle(t, find.byTooltip('Cambiar avatar'));
    },
    'Configuración': (t) async {
      await tab(t, 'Perfil');
      await tapAndSettle(t, find.text('Configuración'));
    },
  };

  Future<void> open(
    WidgetTester tester,
    String screen, {
    bool dark = false,
    bool hugeText = false,
  }) async {
    // Celular chico: 360 x 690 dp.
    tester.view.physicalSize = const Size(1080, 2070);
    tester.view.devicePixelRatio = 3;
    if (hugeText) tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      demo: true,
      clock: () => clock,
      prefs: {
        if (dark) 'settings.theme': 'dark',
        // "Muy grande" en la app (x1.4) sobre texto grande del sistema.
        if (hugeText) 'settings.textSize': 'extraLarge',
      },
    );
    await screens[screen]!(tester);
  }

  for (final screen in screens.keys) {
    group(screen, () {
      for (final dark in [false, true]) {
        testWidgets(
          'botones, etiquetas y contraste (${dark ? 'oscuro' : 'claro'})',
          (tester) async {
            final semantics = tester.ensureSemantics();
            await open(tester, screen, dark: dark);

            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            semantics.dispose();
          },
        );
      }

      testWidgets('no se corta con texto muy grande', (tester) async {
        await open(tester, screen, hugeText: true);
        // Cualquier desborde ("RenderFlex overflowed") hace fallar el test.
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
      });
    });
  }

  group('Onboarding', () {
    Future<void> openRegister(WidgetTester tester, {bool huge = false}) async {
      tester.view.physicalSize = const Size(1080, 2070);
      tester.view.devicePixelRatio = 3;
      if (huge) tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, clock: () => clock);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('registro: botones, etiquetas y contraste', (tester) async {
      final semantics = tester.ensureSemantics();
      await openRegister(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('registro con texto muy grande', (tester) async {
      await openRegister(tester, huge: true);
      expect(tester.takeException(), isNull);
    });

    Future<void> openLogin(WidgetTester tester, {bool huge = false}) async {
      tester.view.physicalSize = const Size(1080, 2070);
      tester.view.devicePixelRatio = 3;
      if (huge) tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, clock: () => clock);
      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya tengo cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('iniciar sesión: botones, etiquetas y contraste', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openLogin(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('iniciar sesión con texto muy grande', (tester) async {
      await openLogin(tester, huge: true);
      expect(tester.takeException(), isNull);
    });
  });
}
