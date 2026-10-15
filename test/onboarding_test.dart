import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/features/onboarding/register_step.dart';
import 'package:nee_app/features/onboarding/validators.dart';

import 'helpers/pump_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Toca algo que puede estar fuera de la pantalla (scrollea primero).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

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

    await _tapVisible(tester, find.text('Crear cuenta'));
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

    await _tapVisible(tester, find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuánto guaraní sabés?'), findsOneWidget);

    await tester.tap(find.text('Hablo jopara'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí tu meta diaria'), findsOneWidget);

    await tester.tap(find.text('15 min por día'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso de avatar: elegir el Teju Jagua.
    expect(find.text('Elegí tu avatar'), findsOneWidget);
    await _tapVisible(tester, find.text('Teju Jagua'));
    await tester.pumpAndSettle();
    expect(find.textContaining('guardián de las cuevas'), findsOneWidget);
    await tester.tap(find.text('Empezar a aprender'));
    await tester.pumpAndSettle();

    // Entra a Inicio con la meta elegida (15 min = 30 XP).
    expect(find.text('0 / 30 XP'), findsOneWidget);
    expect(storage.getBool('user.onboardingDone'), isTrue);
    expect(storage.getString('user.username'), 'anapy');
    expect(storage.getString('user.level'), 'jopara');
    expect(storage.getString('progress.dailyGoal'), 'intense');
    expect(storage.getString('user.avatar'), 'teju_jagua');
    expect(storage.getString('user.registeredAt'), isNotNull);
    expect(storage.getInt('progress.totalXp'), isNull, reason: 'sin código');
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
    await _tapVisible(tester, find.text('Crear cuenta'));
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

  /// Llena el registro, nivel y meta, y llega al paso de avatar.
  Future<void> reachAvatarStep(WidgetTester tester, {String? invite}) async {
    await _skipIntro(tester);
    await _fillForm(tester);
    if (invite != null) {
      await tester.enterText(
        _field('¿Tenés un código de invitación? (opcional)'),
        invite,
      );
      await tester.pump();
    }
    await _tapVisible(tester, find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entiendo algo'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí tu avatar'), findsOneWidget);
  }

  testWidgets('código de invitación válido: +50 XP de bienvenida', (
    tester,
  ) async {
    await pumpApp(tester);
    await _skipIntro(tester);
    final field = _field('¿Tenés un código de invitación? (opcional)');

    await tester.enterText(field, 'nee-x');
    await tester.pump();
    expect(find.text('El código es como NEE-WILLY23'), findsOneWidget);

    await tester.enterText(field, 'nee-willy23');
    await tester.pump();
    expect(find.text('NEE-WILLY23'), findsOneWidget, reason: 'en mayúsculas');
    expect(find.textContaining('¡Código válido!'), findsOneWidget);

    // De nuevo desde cero, completando todo el flujo.
    final storage = await pumpApp(tester);
    await reachAvatarStep(tester, invite: 'NEE-WILLY23');
    await tester.tap(find.text('Saltar por ahora'));
    await tester.pumpAndSettle();

    expect(storage.getInt('progress.totalXp'), 50);
    expect(storage.getString('user.usedInviteCode'), 'NEE-WILLY23');
    // Saltar el avatar deja el de siempre y no cuenta como racha.
    expect(storage.getString('user.avatar'), 'mate');
    expect(find.text('0 días de racha'), findsOneWidget);
  });

  testWidgets('un código con formato inválido no frena el registro', (
    tester,
  ) async {
    final storage = await pumpApp(tester);
    await _skipIntro(tester);
    await _fillForm(tester);
    await tester.enterText(
      _field('¿Tenés un código de invitación? (opcional)'),
      'HOLA',
    );
    await _tapVisible(tester, find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    // Muestra el error y no avanza.
    expect(find.text('El código es como NEE-WILLY23'), findsOneWidget);
    expect(find.text('¿Cuánto guaraní sabés?'), findsNothing);
    expect(storage.getInt('progress.totalXp'), isNull);
  });
}
