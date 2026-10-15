import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/features/onboarding/account_steps.dart';
import 'package:nee_app/features/onboarding/validators.dart';

import 'helpers/pump_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Botón (habilitado o no) con ese texto.
FilledButton _button(WidgetTester tester, String text) => tester.widget(
  find.ancestor(of: find.text(text), matching: find.byType(FilledButton)),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Bienvenida hasta la última página (la de los dos botones).
Future<void> _toLastIntroPage(WidgetTester tester) async {
  await _tap(tester, find.text('Siguiente'));
  await _tap(tester, find.text('Siguiente'));
}

/// Escribe en el único campo de la pantalla y toca "Continuar".
Future<void> _fill(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField), text);
  await tester.pump();
  await _tap(tester, find.text('Continuar'));
}

/// Registro con correo hasta el paso de nivel.
Future<void> _registerUntilLevel(WidgetTester tester) async {
  await _toLastIntroPage(tester);
  await _tap(tester, find.text('Crear cuenta'));
  await _fill(tester, 'ana@gmail.com');
  await _fill(tester, 'tereré2026');
  await _fill(tester, 'Ana');
  await _fill(tester, 'Ana Py');
  await _tap(tester, find.text('Saltar'));
  expect(find.text('¿Cuánto guaraní sabés?'), findsOneWidget);
}

/// Nivel, meta y avatar con lo que viene por defecto.
Future<void> _finishDefaults(WidgetTester tester) async {
  await _tap(tester, find.text('Entiendo algo'));
  await _tap(tester, find.text('Continuar'));
  await _tap(tester, find.text('Continuar'));
  await _tap(tester, find.text('Saltar por ahora'));
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

    test('código de invitación (opcional)', () {
      expect(Validators.inviteCode(''), isNull);
      expect(Validators.inviteCode('NEE-WILLY23'), isNull);
      expect(Validators.inviteCode('nee-willy23'), isNull);
      expect(Validators.inviteCode('HOLA'), isNotNull);
    });
  });

  testWidgets('la bienvenida termina con "Crear cuenta" y "Ya tengo cuenta"', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Mba\'éichapa! Esto es Ñe\'ẽ'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNothing);
    await _toLastIntroPage(tester);
    expect(find.text('Duelos con amigos'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('"Saltar" lleva a la última página', (tester) async {
    await pumpApp(tester);
    await _tap(tester, find.text('Saltar'));
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('correo: un dato por pantalla, con validación en tiempo real', (
    tester,
  ) async {
    await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));

    expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 1 de 8'), findsOneWidget);
    expect(_button(tester, 'Continuar').onPressed, isNull);

    await tester.enterText(_field('Correo'), 'ana@');
    await tester.pump();
    expect(find.textContaining('Revisá el correo'), findsOneWidget);
    expect(_button(tester, 'Continuar').onPressed, isNull);

    await tester.enterText(_field('Correo'), 'ana@gmail.com');
    await tester.pump();
    expect(find.textContaining('Revisá el correo'), findsNothing);
    expect(_button(tester, 'Continuar').onPressed, isNotNull);

    // Otras formas de registrarse y el link para iniciar sesión.
    expect(find.text('O registrate con'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con Apple'), findsOneWidget);
    expect(find.text('¿Ya tenés cuenta?'), findsOneWidget);
  });

  testWidgets('contraseña con mostrar/ocultar', (tester) async {
    await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));
    await _fill(tester, 'ana@gmail.com');
    expect(find.text('Creá una contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 2 de 8'), findsOneWidget);

    bool obscured() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(obscured(), isFalse);

    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
    expect(_button(tester, 'Continuar').onPressed, isNull);
  });

  testWidgets('registro completo: guarda datos y no vuelve a aparecer', (
    tester,
  ) async {
    final storage = await pumpApp(tester);
    await _registerUntilLevel(tester);

    await _tap(tester, find.text('Hablo jopara'));
    await _tap(tester, find.text('Continuar'));
    await _tap(tester, find.text('15 min por día'));
    await _tap(tester, find.text('Continuar'));
    expect(find.text('Elegí tu avatar'), findsOneWidget);
    await _tap(tester, find.text('Teju Jagua'));
    expect(find.textContaining('guardián de las cuevas'), findsOneWidget);
    await _tap(tester, find.text('Empezar a aprender'));

    expect(find.text('0 / 30 XP'), findsOneWidget);
    expect(storage.getBool('user.onboardingDone'), isTrue);
    expect(storage.getString('user.name'), 'Ana');
    expect(storage.getString('user.username'), 'anapy');
    expect(storage.getString('user.email'), 'ana@gmail.com');
    expect(storage.getString('user.level'), 'jopara');
    expect(storage.getString('user.avatar'), 'teju_jagua');
    expect(storage.getString('progress.dailyGoal'), 'intense');
    expect(storage.getInt('progress.totalXp'), isNull, reason: 'sin código');
    // La contraseña no se guarda en ningún lado.
    expect(
      storage.keys.where((k) => k.toLowerCase().contains('password')),
      isEmpty,
    );

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

  testWidgets('código de invitación: el texto entra y da +50 XP', (
    tester,
  ) async {
    final storage = await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));
    await _fill(tester, 'ana@gmail.com');
    await _fill(tester, 'tereré2026');
    await _fill(tester, 'Ana');
    await _fill(tester, 'ana');

    final field = _field('Código de invitación (opcional)');
    expect(field, findsOneWidget);
    expect(find.textContaining('los dos ganan +50 XP'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget, reason: 'vacío: se salta');

    await tester.enterText(field, 'nee-x');
    await tester.pump();
    expect(find.text('El código es como NEE-WILLY23'), findsOneWidget);
    expect(_button(tester, 'Continuar').onPressed, isNull);

    await tester.enterText(field, 'nee-willy23');
    await tester.pump();
    expect(find.text('NEE-WILLY23'), findsOneWidget, reason: 'en mayúsculas');
    expect(find.textContaining('¡Código válido!'), findsOneWidget);
    await _tap(tester, find.text('Continuar'));
    await _finishDefaults(tester);

    expect(storage.getInt('progress.totalXp'), 50);
    expect(storage.getString('user.usedInviteCode'), 'NEE-WILLY23');
    expect(storage.getString('user.avatar'), 'mate');
    expect(find.text('0 días de racha'), findsOneWidget);
  });

  testWidgets('volver atrás conserva los datos', (tester) async {
    await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));
    await _fill(tester, 'ana@gmail.com');
    await _fill(tester, 'tereré2026');
    await _fill(tester, 'Ana');

    await _tap(tester, find.byTooltip('Volver'));
    expect(find.text('Ana'), findsOneWidget);
    await _tap(tester, find.byTooltip('Volver'));
    await _tap(tester, find.byTooltip('Volver'));
    expect(find.text('ana@gmail.com'), findsOneWidget);

    // Desde el correo, "Volver" regresa a la última página de la bienvenida.
    await _tap(tester, find.byTooltip('Volver'));
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('registrarse con Google (simulado) saltea correo y contraseña', (
    tester,
  ) async {
    final storage = await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));

    await tester.ensureVisible(find.text('Continuar con Google'));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    expect(find.text('Conectando…'), findsOneWidget);
    await tester.pump(socialSignInDelay);
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo te llamás?'), findsOneWidget);
    await _fill(tester, 'Ana');
    await _fill(tester, 'ana');
    await _tap(tester, find.text('Saltar'));
    await _finishDefaults(tester);

    expect(storage.getString('user.authMethod'), 'google');
    expect(storage.getString('user.email'), isNull);
  });

  testWidgets('registrarse con Apple (simulado)', (tester) async {
    final storage = await pumpApp(tester);
    await _toLastIntroPage(tester);
    await _tap(tester, find.text('Crear cuenta'));
    await tester.ensureVisible(find.text('Continuar con Apple'));
    await tester.tap(find.text('Continuar con Apple'));
    await tester.pump(socialSignInDelay);
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo te llamás?'), findsOneWidget);
    // "Volver" desde el nombre vuelve al correo (no hubo contraseña).
    await _tap(tester, find.byTooltip('Volver'));
    expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
    expect(storage.getBool('user.onboardingDone'), isNull);
  });

  group('Iniciar sesión (simulado)', () {
    testWidgets('con correo entra directo a la app', (tester) async {
      final storage = await pumpApp(tester);
      await _toLastIntroPage(tester);
      await _tap(tester, find.text('Ya tengo cuenta'));

      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('O iniciá sesión con'), findsOneWidget);
      expect(find.text('¿No tenés cuenta?'), findsOneWidget);

      await tester.enterText(_field('Correo'), 'willy.py@gmail.com');
      await tester.enterText(_field('Contraseña'), 'algo1234');
      await _tap(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));

      expect(find.text('Duelos'), findsWidgets);
      expect(storage.getString('user.name'), 'Willy.py');
      expect(storage.getString('user.username'), 'willypy');
    });

    testWidgets('con campos vacíos muestra los errores', (tester) async {
      await pumpApp(tester);
      await _toLastIntroPage(tester);
      await _tap(tester, find.text('Ya tengo cuenta'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));

      expect(find.text('Escribí tu correo'), findsOneWidget);
      expect(find.text('Escribí tu contraseña'), findsOneWidget);
      expect(find.text('Duelos'), findsNothing);
    });

    testWidgets('con Google entra a la app', (tester) async {
      final storage = await pumpApp(tester);
      await _toLastIntroPage(tester);
      await _tap(tester, find.text('Ya tengo cuenta'));
      await tester.ensureVisible(find.text('Continuar con Google'));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump(socialSignInDelay);
      await tester.pumpAndSettle();

      expect(find.text('Duelos'), findsWidgets);
      expect(storage.getString('user.authMethod'), 'google');
      expect(storage.getString('user.username'), startsWith('google_'));
    });

    testWidgets('los links llevan de uno al otro', (tester) async {
      await pumpApp(tester);
      await _toLastIntroPage(tester);
      await _tap(tester, find.text('Ya tengo cuenta'));
      await _tap(tester, find.text('Registrate'));
      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
      await _tap(tester, find.text('Iniciá sesión'));
      expect(find.text('Qué bueno verte de nuevo 🧉'), findsOneWidget);
    });
  });
}
