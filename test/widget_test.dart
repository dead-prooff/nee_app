import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/app.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('La app arranca y muestra la navegación', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ],
        child: const NeeApp(),
      ),
    );

    expect(find.text('Duelos'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
  });
}
