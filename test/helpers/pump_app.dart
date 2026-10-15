import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/app.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/duels/duel_provider.dart';
import 'package:nee_app/features/league/league_provider.dart';
import 'package:nee_app/features/lessons/data/lesson_repository.dart';
import 'package:nee_app/features/notifications/messages.dart';
import 'package:nee_app/features/notifications/notifications_provider.dart';
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

/// Los textos reales de `assets/data/mensajes.json`.
Messages testMessages() =>
    Messages.fromJsonString(File(Messages.path).readAsStringSync());

/// Levanta la app completa con los providers reales, como en `main()`.
Future<StorageService> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await StorageService.init();

  // Desmonta lo anterior para que los providers se creen de nuevo, como al
  // reabrir la app.
  await tester.pumpWidget(const SizedBox());

  final progress = ProgressProvider(storage, clock: clock);
  final duels = DuelProvider(storage, clock: clock);
  final league = LeagueProvider(storage, progress, clock: clock);
  final notifications = NotificationsProvider(
    storage,
    messages: testMessages(),
    progress: progress,
    duels: duels,
    league: league,
    clock: clock,
    random: Random(0),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider(create: (_) => LessonRepository(bundle: FileAssetBundle())),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: duels),
        ChangeNotifierProvider.value(value: league),
        ChangeNotifierProvider.value(value: notifications),
      ],
      child: const NeeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}
