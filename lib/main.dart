import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'features/duels/duel_provider.dart';
import 'features/lessons/data/lesson_repository.dart';
import 'features/onboarding/user_provider.dart';
import 'features/progress/progress_provider.dart';
import 'features/settings/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider(create: (_) => LessonRepository()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)),
        ChangeNotifierProvider(create: (_) => DuelProvider(storage)),
      ],
      child: const NeeApp(),
    ),
  );
}
