import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'features/duels/duel_provider.dart';
import 'features/league/league_provider.dart';
import 'features/lessons/data/lesson_repository.dart';
import 'features/notifications/messages.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/onboarding/user_provider.dart';
import 'features/profile/badges.dart';
import 'features/progress/progress_provider.dart';
import 'features/settings/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  // Textos de los avisos (assets/data/mensajes.json).
  final messages = await Messages.load(rootBundle);
  final badgeCatalog = await BadgeCatalog.load(rootBundle);

  // Se crean juntos porque dependen entre sí: la liga usa el XP semanal y
  // los avisos escuchan al progreso, los duelos y la liga.
  final user = UserProvider(storage);
  final progress = ProgressProvider(storage);
  final duels = DuelProvider(storage);
  final league = LeagueProvider(storage, progress);
  final notifications = NotificationsProvider(
    storage,
    messages: messages,
    progress: progress,
    duels: duels,
    league: league,
  );
  final badges = BadgeProvider(
    storage,
    catalog: badgeCatalog,
    progress: progress,
    duels: duels,
    league: league,
    user: user,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider(create: (_) => LessonRepository()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider.value(value: user),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: duels),
        ChangeNotifierProvider.value(value: league),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider.value(value: badges),
      ],
      child: const NeeApp(),
    ),
  );
}
