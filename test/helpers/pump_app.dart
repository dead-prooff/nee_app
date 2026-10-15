import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/app.dart';
import 'package:nee_app/app_scope.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/forum/forum_models.dart';
import 'package:nee_app/features/notifications/messages.dart';
import 'package:nee_app/features/profile/badges.dart';
import 'package:nee_app/features/settings/demo_profile.dart';
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

/// Los textos reales de `assets/data/insignias.json`.
BadgeCatalog testBadgeCatalog() =>
    BadgeCatalog.fromJsonString(File(BadgeCatalog.path).readAsStringSync());

/// El contenido real de `assets/data/foro.json`.
ForumSeed testForumSeed() =>
    ForumSeed.fromJsonString(File(ForumSeed.path).readAsStringSync());

/// Levanta la app completa con los providers reales, como en `main()`.
Future<StorageService> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
  bool demo = false,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await StorageService.init();
  // Con [demo], arranca con el perfil de ejemplo del Modo demo.
  if (demo) {
    await applyDemoProfile(storage, now: (clock ?? DateTime.now)());
  }

  // Desmonta lo anterior para que los providers se creen de nuevo, como al
  // reabrir la app.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      storage: storage,
      messages: testMessages(),
      badgeCatalog: testBadgeCatalog(),
      forumSeed: testForumSeed(),
      lessonBundle: FileAssetBundle(),
      clock: clock,
      random: Random(0),
      child: const NeeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}
