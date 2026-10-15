import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

/// Recorre la app de punta a punta, como lo haría alguien que la prueba
/// por primera vez: registro, lección, duelo, ranking, avisos, perfil,
/// invitar y el modo demo.
void main() {
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Sin audio ni portapapeles reales en los tests.
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  final lessons = jsonDecode(
    File('assets/data/lecciones.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  /// Baja en Configuración hasta el "Modo demo" (está al final).
  Future<void> scrollToDemo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text),
        300,
        scrollable: find.byType(Scrollable).last,
      );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Responde bien un ejercicio de la lección según el JSON.
  Future<void> answer(WidgetTester tester, Map<String, dynamic> ex) async {
    switch (ex['tipo']) {
      case 'traduccion' || 'escuchar':
        await tap(tester, find.text(ex['respuesta'] as String).last);
      case 'armar':
        for (final word in (ex['respuesta'] as String).split(' ')) {
          // La palabra todavía disponible en el banco (la última en el árbol).
          await tap(tester, find.text(word).last);
        }
      case 'pares':
        for (final pair in ex['pares'] as List) {
          await tap(tester, find.text(pair[0] as String).last);
          await tap(tester, find.text(pair[1] as String).last);
        }
    }
    await tap(tester, find.text('Comprobar'));
    expect(find.text('¡Iporã! Correcto'), findsOneWidget, reason: '$ex');
    await tap(tester, find.text('Continuar'));
  }

  testWidgets('de punta a punta', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final storage = await pumpApp(
      tester,
      clock: () => DateTime(2026, 10, 14, 10),
    );

    // --- Bienvenida y registro en pasos (un dato por pantalla)
    await tap(tester, find.text('Siguiente'));
    await tap(tester, find.text('Siguiente'));
    await tap(tester, find.text('Crear cuenta'));
    for (final value in ['willy@gmail.com', 'tereré2026', 'Willy', 'willy']) {
      await tester.enterText(find.byType(TextFormField), value);
      await tester.pump();
      await tap(tester, find.text('Continuar'));
    }
    await tap(tester, find.text('Saltar')); // sin código de invitación
    await tap(tester, find.text('Hablo jopara'));
    await tap(tester, find.text('Continuar'));
    await tap(tester, find.text('Continuar')); // meta diaria
    await tap(tester, find.text('Kurupí'));
    await tap(tester, find.text('Empezar a aprender'));
    expect(storage.getString('user.avatar'), 'kurupi');

    // --- Inicio: con "Hablo jopara" la Unidad 1 ya está abierta.
    expect(find.text('0 días de racha'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Lección 3: .*, disponible$')),
      findsOneWidget,
    );

    // --- Lección 1 completa, sin errores.
    await tap(tester, find.text("¡Mba'éichapa!"));
    final firstLesson =
        (((lessons['unidades'] as List).first as Map)['lecciones'] as List)
                .first
            as Map<String, dynamic>;
    for (final ex in firstLesson['ejercicios'] as List) {
      await answer(tester, ex as Map<String, dynamic>);
    }
    expect(find.text('¡Lección completada!'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);

    // Festejos: "Primer mborayhu" y "Chipa caliente" (sin errores).
    expect(find.text('¡Insignia nueva!'), findsOneWidget);
    await tap(tester, find.text('¡Iporã!'));
    expect(find.text('¡Insignia nueva!'), findsOneWidget);
    await tap(tester, find.text('¡Iporã!'));
    await tap(tester, find.text('Continuar'));

    expect(find.text('1 día de racha'), findsOneWidget);
    expect(find.text('Hendy hína 🔥'), findsOneWidget);

    // --- Duelo contra Lucía (sin responder: corre solo hasta el final).
    await tap(tester, find.text('Duelos').last);
    await tap(tester, find.text('Jugar').first);
    await tester.tap(find.text('¡Empezar!'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pumpAndSettle();
    expect(find.text('Volver a Duelos'), findsOneWidget);
    await tap(tester, find.text('Volver a Duelos'));
    expect(find.text('Mati te desafió'), findsOneWidget);
    expect(find.text('Lucía te desafió'), findsNothing);

    // --- Ranking: tu fila con el XP de la semana (15 + 3 del duelo).
    await tap(tester, find.text('Ranking').last);
    expect(find.text('VOS'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Puesto \d+: vos, 18 XP')), findsOne);

    // --- Avisos: hay sin leer y se pueden marcar.
    await tap(tester, find.text('Avisos').last);
    expect(find.textContaining('sin leer'), findsOneWidget);
    await tap(tester, find.text('Marcar todo como leído'));
    expect(find.text('Todo leído'), findsOneWidget);

    // --- Perfil e invitar.
    await tap(tester, find.text('Perfil').last);
    expect(find.text('@willy'), findsOneWidget);
    expect(find.bySemanticsLabel('Lecciones completadas: 1'), findsOneWidget);
    await tap(tester, find.text('Invitar amigos'));
    await tap(tester, find.text('Copiar código'));
    expect(find.text('¡Insignia nueva!'), findsOneWidget); // Che ra'a
    await tap(tester, find.text('¡Iporã!'));
    await tester.pageBack();
    await tester.pumpAndSettle();

    // --- Modo demo: perfil de ejemplo.
    await tap(tester, find.text('Configuración'));
    await scrollToDemo(tester, 'Cargar perfil de ejemplo');
    await tap(tester, find.text('Cargar perfil de ejemplo'));
    await tap(tester, find.text('Cargar'));
    expect(find.text('8 días de racha'), findsOneWidget);
    expect(find.text('Hendy kavaju resa 🐴✨'), findsOneWidget);
    expect(
      storage.getString('user.name'),
      'Willy',
      reason: 'mantiene el nombre',
    );

    await tap(tester, find.text('Ranking').last);
    expect(find.text('Liga Plata'), findsOneWidget);

    // --- Modo demo: reiniciar todo vuelve a la bienvenida.
    await tap(tester, find.text('Perfil').last);
    await tap(tester, find.text('Configuración'));
    await scrollToDemo(tester, 'Reiniciar todo');
    await tap(tester, find.text('Reiniciar todo'));
    await tap(tester, find.text('Reiniciar'));
    expect(find.text("Mba'éichapa! Esto es Ñe'ẽ"), findsOneWidget);
    expect(storage.getBool('user.onboardingDone'), isNull);
    expect(storage.getInt('progress.totalXp'), isNull);
  });
}
