import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/app.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/lessons/data/lesson_repository.dart';
import 'package:nee_app/features/onboarding/user_provider.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:nee_app/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_asset_bundle.dart';

/// Preferencias de un usuario que ya hizo el onboarding.
const onboardedPrefs = <String, Object>{
  'user.onboardingDone': true,
  'user.name': 'Ana',
  'user.username': 'ana',
};

/// Levanta la app completa con los providers reales, como en `main()`.
Future<StorageService> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await StorageService.init();

  // Desmonta lo anterior para que los providers se creen de nuevo, como al
  // reabrir la app.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider(create: (_) => LessonRepository(bundle: FileAssetBundle())),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)),
      ],
      child: const NeeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}
