import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../league/league_provider.dart';
import '../progress/progress_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Apariencia'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                settings.isDark ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Modo oscuro'),
              subtitle: Text(settings.isDark ? 'Activado' : 'Desactivado'),
              value: settings.isDark,
              onChanged: settings.setDarkMode,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Tamaño de texto'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<TextSizeOption>(
                    showSelectedIcon: false,
                    segments: [
                      for (final option in TextSizeOption.values)
                        ButtonSegment(
                          value: option,
                          label: Text(
                            option.label,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                    selected: {settings.textSize},
                    onSelectionChanged: (s) => settings.setTextSize(s.first),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vista previa: Mba\'éichapa! ¿Cómo estás?',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Meta diaria'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<DailyGoal>(
                    showSelectedIcon: false,
                    segments: [
                      for (final goal in DailyGoal.values)
                        ButtonSegment(
                          value: goal,
                          label: Text(
                            '${goal.minutes} min',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                    selected: {progress.goal},
                    onSelectionChanged: (s) => progress.setDailyGoal(s.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${progress.goal.label}: ${progress.goal.xp} XP por día',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Sonido'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
              ),
              title: const Text('Efectos y audio'),
              value: settings.soundEnabled,
              onChanged: settings.setSoundEnabled,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Herramientas de prueba'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Simular cierre de la liga'),
              subtitle: const Text(
                'Cierra la semana con la tabla actual, sin esperar al domingo.',
              ),
              onTap: () {
                final r = context.read<LeagueProvider>().closeWeekNow();
                final text = r.promoted
                    ? '¡Subiste a Liga ${r.to.label}! (puesto ${r.rank})'
                    : r.demoted
                    ? 'Bajaste a Liga ${r.to.label} (puesto ${r.rank})'
                    : 'Te mantuviste en Liga ${r.to.label} (puesto ${r.rank})';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(text)));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
