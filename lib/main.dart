import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_scope.dart';
import 'core/services/storage_service.dart';
import 'features/forum/forum_models.dart';
import 'features/notifications/messages.dart';
import 'features/profile/badges.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  // Textos editables: avisos (mensajes.json), insignias (insignias.json) y
  // contenido de ejemplo del foro (foro.json).
  final messages = await Messages.load(rootBundle);
  final badgeCatalog = await BadgeCatalog.load(rootBundle);
  final forumSeed = ForumSeed.fromJsonString(
    await rootBundle.loadString(ForumSeed.path),
  );

  runApp(
    AppScope(
      storage: storage,
      messages: messages,
      badgeCatalog: badgeCatalog,
      forumSeed: forumSeed,
      child: const NeeApp(),
    ),
  );
}
