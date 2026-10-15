import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../duels/duels_view.dart';
import '../forum/forum_provider.dart';
import '../forum/forum_view.dart';
import '../forum/new_topic_screen.dart';
import '../home/home_view.dart';
import '../league/ranking_view.dart';
import '../notifications/notification_models.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_view.dart';
import '../profile/profile_view.dart';
import 'celebration_listener.dart';

/// Estructura principal con la barra de navegación inferior (5 pestañas).
/// Los avisos se abren desde la campanita de Inicio.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['Ñe\'ẽ', 'Duelos', 'Ranking', 'Foro', 'Perfil'];
  static const _home = 0;
  static const _forum = 3;

  void _select(int index) {
    // Al entrar al foro se revisan respuestas y likes simulados nuevos.
    if (index == _forum) context.read<ForumProvider>().refresh();
    setState(() => _index = index);
  }

  /// Desde un aviso, ir a la pestaña relacionada.
  void _openFor(NotificationType type) => _select(switch (type) {
    NotificationType.duel => 1,
    NotificationType.streak => _home,
    NotificationType.league => 2,
    NotificationType.forum => _forum,
  });

  void _openNotifications() {
    // Se revisa si hay algo nuevo (por ejemplo, la racha en peligro o
    // respuestas en el foro) antes de mostrar la lista.
    context.read<ForumProvider>().refresh();
    context.read<NotificationsProvider>().sync();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => NotificationsScreen(
          onOpen: (type) {
            Navigator.of(routeContext).pop();
            _openFor(type);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsProvider, int>(
      (n) => n.unreadCount,
    );
    const pages = [
      HomeView(),
      DuelsView(),
      RankingView(),
      ForumView(),
      ProfileView(),
    ];

    // Festeja ascensos de liga e insignias nuevas apenas pasan.
    return CelebrationListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            if (_index == _home)
              IconButton(
                tooltip: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
                onPressed: _openNotifications,
                icon: _UnreadBadge(
                  unread: unread,
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
          ],
        ),
        body: IndexedStack(index: _index, children: pages),
        floatingActionButton: _index == _forum
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewTopicScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo tema'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
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
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Foro',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de avisos (se abre desde la campanita).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.onOpen});

  final ValueChanged<NotificationType> onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos')),
    body: NotificationsView(onOpen: onOpen),
  );
}

/// Globito con la cantidad de avisos sin leer.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.unread, required this.child});

  final int unread;
  final Widget child;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: unread > 0,
    label: Text(unread > 9 ? '9+' : '$unread'),
    child: child,
  );
}
