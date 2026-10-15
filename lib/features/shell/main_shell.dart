import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../duels/duels_view.dart';
import '../home/home_view.dart';
import '../league/ranking_view.dart';
import '../notifications/notification_models.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_view.dart';
import '../profile/profile_view.dart';
import 'celebration_listener.dart';

/// Estructura principal con la barra de navegación inferior (5 pestañas).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['Ñe\'ẽ', 'Duelos', 'Ranking', 'Avisos', 'Perfil'];
  static const _avisos = 3;

  void _select(int index) {
    // Al entrar a Avisos se revisa si hay algo nuevo (por ejemplo, la racha
    // en peligro después de las 18 h).
    if (index == _avisos) context.read<NotificationsProvider>().sync();
    setState(() => _index = index);
  }

  /// Desde un aviso, ir a la pestaña relacionada.
  void _openFor(NotificationType type) => _select(switch (type) {
    NotificationType.duel => 1,
    NotificationType.streak => 0,
    NotificationType.league => 2,
  });

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsProvider, int>(
      (n) => n.unreadCount,
    );
    final pages = [
      const HomeView(),
      const DuelsView(),
      const RankingView(),
      NotificationsView(onOpen: _openFor),
      const ProfileView(),
    ];

    // Festeja ascensos de liga e insignias nuevas apenas pasan.
    return CelebrationListener(
      child: Scaffold(
        appBar: AppBar(title: Text(_titles[_index])),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.sports_kabaddi_outlined),
              selectedIcon: Icon(Icons.sports_kabaddi),
              label: 'Duelos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Ranking',
            ),
            NavigationDestination(
              icon: _UnreadBadge(
                unread: unread,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: _UnreadBadge(
                unread: unread,
                child: const Icon(Icons.notifications),
              ),
              label: 'Avisos',
              tooltip: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
            ),
            const NavigationDestination(
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
