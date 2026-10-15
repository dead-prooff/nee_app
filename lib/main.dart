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
import 'features/progress/progress_provider.dart';
import 'features/settings/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  // Textos de los avisos (assets/data/mensajes.json).
  final messages = await Messages.load(rootBundle);

  // Se crean juntos porque dependen entre sí: la liga usa el XP semanal y
  // los avisos escuchan al progreso, los duelos y la liga.
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

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider(create: (_) => LessonRepository()),
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
}
