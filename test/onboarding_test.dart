import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/features/onboarding/register_step.dart';
import 'package:nee_app/features/onboarding/validators.dart';

import 'helpers/pump_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _skipIntro(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }
  expect(find.text('Creá tu cuenta'), findsOneWidget);
}

Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(_field('Nombre'), 'Ana');
  await tester.enterText(_field('Usuario'), 'Ana Py');
  await tester.enterText(_field('Correo'), 'ana@gmail.com');
  await tester.enterText(_field('Contraseña'), 'tereré2026');
  await tester.pump();
}

void main() {
  group('Validators', () {
    test('usuario', () {
      expect(Validators.username('ana_py'), isNull);
      expect(Validators.username('an'), isNotNull);
      expect(Validators.username('Ana!'), isNotNull);
    });

    test('correo', () {
      expect(Validators.email('ana@gmail.com'), isNull);
      expect(Validators.email('ana@gmail'), isNotNull);
      expect(Validators.email('ana gmail.com'), isNotNull);
    });

    test('contraseña', () {
      expect(Validators.password('tereré2026'), isNull);
      expect(Validators.password('corta1'), 'Mínimo 8 caracteres');
      expect(Validators.password('sinnumeros'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
  });

  testWidgets('las 3 pantallas de bienvenida llevan al registro', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Mba\'éichapa! Esto es Ñe\'ẽ'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo funciona'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Duelos con amigos'), findsOneWidget);
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Creá tu cuenta'), findsOneWidget);
  });

  testWidgets('valida en tiempo real mientras se escribe', (tester) async {
    await pumpApp(tester);
    await _skipIntro(tester);

    await tester.enterText(_field('Correo'), 'ana@');
    await tester.pump();
    expect(find.textContaining('Revisá el correo'), findsOneWidget);

    await tester.enterText(_field('Correo'), 'ana@gmail.com');
    await tester.pump();
    expect(find.textContaining('Revisá el correo'), findsNothing);

    await tester.enterText(_field('Contraseña'), 'abc');
    await tester.pump();
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('el usuario se pasa a minúsculas y sin espacios', (tester) async {
    await pumpApp(tester);
    await _skipIntro(tester);

    await tester.enterText(_field('Usuario'), 'Ana Py');
    await tester.pump();
    expect(find.text('anapy'), findsOneWidget);
  });

  testWidgets('mostrar/ocultar contraseña', (tester) async {
    await pumpApp(tester);
    await _skipIntro(tester);

    bool obscured() => tester
        .widget<EditableText>(
          find.descendant(
            of: _field('Contraseña'),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('"Crear cuenta" con campos vacíos muestra los errores', (
    tester,
  ) async {
    await pumpApp(tester);
    await _skipIntro(tester);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribí tu nombre'), findsOneWidget);
    expect(find.text('Creá una contraseña'), findsOneWidget);
    expect(find.text('¿Cuánto guaraní sabés?'), findsNothing);
  });

  testWidgets('registro completo: guarda datos, meta y no vuelve a aparecer', (
    tester,
  ) async {
    final storage = await pumpApp(tester);
    await _skipIntro(tester);
    await _fillForm(tester);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuánto guaraní sabés?'), findsOneWidget);

    await tester.tap(find.text('Hablo jopara'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí tu meta diaria'), findsOneWidget);

    await tester.tap(find.text('15 min por día'));
    await tester.pump();
    await tester.tap(find.text('Empezar a aprender'));
    await tester.pumpAndSettle();

    // Entra a Inicio con la meta elegida (15 min = 30 XP).
    expect(find.text('0 / 30 XP'), findsOneWidget);
    expect(storage.getBool('user.onboardingDone'), isTrue);
    expect(storage.getString('user.username'), 'anapy');
    expect(storage.getString('user.level'), 'jopara');
    expect(storage.getString('progress.dailyGoal'), 'intense');
    // La contraseña no se guarda en ningún lado.
    expect(
      storage.getString('user.password'),
      isNull,
      reason: 'no se guardan contraseñas en shared_preferences',
    );

    // Al reabrir la app, ya no aparece el onboarding.
    await pumpApp(
      tester,
      prefs: {
        'user.onboardingDone': storage.getBool('user.onboardingDone')!,
        'progress.dailyGoal': storage.getString('progress.dailyGoal')!,
      },
    );
    expect(find.text('Mba\'éichapa! Esto es Ñe\'ẽ'), findsNothing);
    expect(find.text('0 / 30 XP'), findsOneWidget);
  });

  testWidgets('volver atrás conserva los datos del registro', (tester) async {
    await pumpApp(tester);
    await _skipIntro(tester);
    await _fillForm(tester);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@gmail.com'), findsOneWidget);
  });

  testWidgets('"Continuar con Google" simulado salta al paso de nivel', (
    tester,
  ) async {
    await pumpApp(tester);
    await _skipIntro(tester);

    await tester.ensureVisible(find.text('Continuar con Google'));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    expect(find.text('Conectando…'), findsOneWidget);

    await tester.pump(RegisterStep.googleDelay);
    await tester.pumpAndSettle();
    expect(find.text('¿Cuánto guaraní sabés?'), findsOneWidget);
  });
}
