import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'features/settings/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
      ],
      child: const NeeApp(),
    ),
  );
}
