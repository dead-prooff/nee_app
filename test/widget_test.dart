import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('la primera vez arranca con el onboarding', (tester) async {
    await pumpApp(tester);

    expect(find.text('Mba\'éichapa! Esto es Ñe\'ẽ'), findsOneWidget);
    expect(find.text('Duelos'), findsNothing);
  });

  testWidgets('después del onboarding muestra la navegación', (tester) async {
    await pumpApp(tester, prefs: onboardedPrefs);

    expect(find.text('Duelos'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
  });

  testWidgets('cambiar la meta en Configuración actualiza la barra de Inicio', (
    tester,
  ) async {
    final storage = await pumpApp(tester, prefs: onboardedPrefs);
    expect(find.text('0 / 20 XP'), findsOneWidget);

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    expect(find.text('Tranqui: 10 XP por día'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 10 XP'), findsOneWidget);
    expect(storage.getString('progress.dailyGoal'), 'relaxed');
  });
}
