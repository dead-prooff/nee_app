import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_scope.dart';
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
              title: const Text('Sonido y vibración'),
              subtitle: const Text(
                'Audio automático en los ejercicios de escucha y vibración '
                'al responder.',
              ),
              value: settings.soundEnabled,
              onChanged: settings.setSoundEnabled,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Modo demo'),
          const _DemoModeCard(),
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

/// Herramientas para presentar la app (por ejemplo, frente a un jurado).
class _DemoModeCard extends StatelessWidget {
  const _DemoModeCard();

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _loadDemo(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: '¿Cargar el perfil de ejemplo?',
      message:
          'Reemplaza tu progreso por uno de ejemplo: racha de 8 días, '
          '4 lecciones, Liga Plata, duelos ganados e insignias.',
      action: 'Cargar',
    );
    if (ok && context.mounted) {
      await context.read<AppController>().loadDemoProfile();
    }
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: '¿Reiniciar todo?',
      message:
          'Se borran el registro, el progreso, la racha, el XP, las '
          'insignias y los avisos, y la app vuelve a la bienvenida. El tema '
          'y el tamaño de texto se mantienen.',
      action: 'Reiniciar',
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<AppController>().resetAll();
    }
  }

  void _closeLeague(BuildContext context) {
    final r = context.read<LeagueProvider>().closeWeekNow();
    final text = r.promoted
        ? '¡Subiste a Liga ${r.to.label}! (puesto ${r.rank})'
        : r.demoted
        ? 'Bajaste a Liga ${r.to.label} (puesto ${r.rank})'
        : 'Te mantuviste en Liga ${r.to.label} (puesto ${r.rank})';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Card(
      semanticContainer: false,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_pin_outlined),
            title: const Text('Cargar perfil de ejemplo'),
            subtitle: const Text(
              'Para mostrar la app "en uso" sin jugar antes.',
            ),
            onTap: () => _loadDemo(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Simular cierre de la liga'),
            subtitle: const Text(
              'Cierra la semana con la tabla actual, sin esperar al domingo.',
            ),
            onTap: () => _closeLeague(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.restart_alt, color: error),
            title: Text('Reiniciar todo', style: TextStyle(color: error)),
            subtitle: const Text('Para mostrar el registro desde cero.'),
            onTap: () => _reset(context),
          ),
        ],
      ),
    );
  }
}
