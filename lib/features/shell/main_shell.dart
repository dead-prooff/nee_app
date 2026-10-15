import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_view.dart';
import '../home/home_view.dart';
import '../settings/settings_screen.dart';

/// Estructura principal con la barra de navegación inferior (5 pestañas).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['Ñe\'ẽ', 'Duelos', 'Ranking', 'Avisos', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeView(),
      const ComingSoonView(
        emoji: '⚔️',
        title: 'Duelos',
        message: 'Desafiá a un amigo a 5 preguntas rápidas.',
      ),
      const ComingSoonView(
        emoji: '🏆',
        title: 'Ranking',
        message: 'La liga semanal entre amigos.',
      ),
      const ComingSoonView(
        emoji: '🔔',
        title: 'Avisos',
        message: 'Desafíos, rachas en peligro y ascensos de liga.',
      ),
      ComingSoonView(
        emoji: '🧉',
        title: 'Perfil',
        message: 'Estadísticas, insignias e invitaciones.',
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          icon: const Icon(Icons.settings),
          label: const Text('Configuración'),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_kabaddi_outlined),
            selectedIcon: Icon(Icons.sports_kabaddi),
            label: 'Duelos',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
