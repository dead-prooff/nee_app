import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/user_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/shell/main_shell.dart';

class NeeApp extends StatelessWidget {
  const NeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final onboardingDone = context.select<UserProvider, bool>(
      (u) => u.onboardingDone,
    );

    return MaterialApp(
      title: 'Ñe\'ẽ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      // Combina el tamaño de texto del sistema con el elegido en la app,
      // con un tope para que los diseños no se rompan.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemFactor = media.textScaler.scale(14) / 14;
        final factor = (systemFactor * settings.textSize.factor).clamp(
          1.0,
          2.0,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(factor)),
          child: child!,
        );
      },
      // El onboarding aparece solo hasta que se completa una vez.
      home: onboardingDone ? const MainShell() : const OnboardingFlow(),
    );
  }
}
