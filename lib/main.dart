import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_scope.dart';
import 'core/services/storage_service.dart';
import 'features/notifications/messages.dart';
import 'features/profile/badges.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  // Textos editables: avisos (mensajes.json) e insignias (insignias.json).
  final messages = await Messages.load(rootBundle);
  final badgeCatalog = await BadgeCatalog.load(rootBundle);

  runApp(
    AppScope(
      storage: storage,
      messages: messages,
      badgeCatalog: badgeCatalog,
      child: const NeeApp(),
    ),
  );
}
