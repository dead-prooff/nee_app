import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
