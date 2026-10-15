import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'core/services/storage_service.dart';
import 'features/duels/duel_provider.dart';
import 'features/forum/forum_models.dart';
import 'features/forum/forum_provider.dart';
import 'features/league/league_provider.dart';
import 'features/lessons/data/lesson_repository.dart';
import 'features/notifications/messages.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/onboarding/user_provider.dart';
import 'features/profile/badges.dart';
import 'features/progress/progress_provider.dart';
import 'features/settings/demo_profile.dart';
import 'features/settings/settings_provider.dart';

/// Acciones del "Modo demo" que rearman toda la app.
abstract class AppController {
  /// Borra todo (menos la configuración visual) y vuelve al registro.
  Future<void> resetAll();

  /// Deja un usuario "en uso": racha de 8 días, Liga Plata, insignias...
  Future<void> loadDemoProfile();
}

/// Crea todos los providers de la app y los vuelve a crear cuando el modo
/// demo cambia los datos guardados.
class AppScope extends StatefulWidget {
  const AppScope({
    super.key,
    required this.storage,
    required this.messages,
    required this.badgeCatalog,
    required this.forumSeed,
    required this.child,
    this.lessonBundle,
    this.clock,
    this.random,
  });

  final StorageService storage;
  final Messages messages;
  final BadgeCatalog badgeCatalog;
  final ForumSeed forumSeed;
  final Widget child;

  /// Para los tests (en la app se usa rootBundle).
  final AssetBundle? lessonBundle;
  final DateTime Function()? clock;
  final Random? random;

  @override
  State<AppScope> createState() => _AppScopeState();
}

/// Los providers de una "sesión": se crean juntos porque dependen entre sí
/// (la liga usa el XP semanal, los avisos y las insignias escuchan al resto).
class _Session {
  _Session(AppScope w) {
    final s = w.storage;
    settings = SettingsProvider(s);
    user = UserProvider(s, clock: w.clock);
    progress = ProgressProvider(s, clock: w.clock);
    duels = DuelProvider(s, clock: w.clock);
    league = LeagueProvider(s, progress, clock: w.clock);
    forum = ForumProvider(s, seed: w.forumSeed, clock: w.clock);
    notifications = NotificationsProvider(
      s,
      messages: w.messages,
      progress: progress,
      duels: duels,
      league: league,
      forum: forum,
      clock: w.clock,
      random: w.random,
    );
    badges = BadgeProvider(
      s,
      catalog: w.badgeCatalog,
      progress: progress,
      duels: duels,
      league: league,
      user: user,
      forum: forum,
      clock: w.clock,
    );
  }

  late final SettingsProvider settings;
  late final UserProvider user;
  late final ProgressProvider progress;
  late final DuelProvider duels;
  late final LeagueProvider league;
  late final ForumProvider forum;
  late final NotificationsProvider notifications;
  late final BadgeProvider badges;

  /// Primero los que escuchan a otros.
  void dispose() {
    for (final p in [
      badges,
      notifications,
      forum,
      league,
      duels,
      progress,
      user,
    ]) {
      p.dispose();
    }
    settings.dispose();
  }
}

class _AppScopeState extends State<AppScope> implements AppController {
  late _Session _session = _Session(widget);
  late final LessonRepository _lessons = LessonRepository(
    bundle: widget.lessonBundle,
  );
  int _generation = 0;

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _restart(Future<void> Function() change) async {
    await change();
    if (!mounted) return;
    final old = _session;
    setState(() {
      _session = _Session(widget);
      _generation++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// Todo lo que no es configuración visual (tema, texto, sonido).
  bool _isAppData(String key) => !key.startsWith('settings.');

  @override
  Future<void> resetAll() =>
      _restart(() => widget.storage.removeWhere(_isAppData));

  @override
  Future<void> loadDemoProfile() => _restart(() async {
    final user = _session.user;
    final name = user.onboardingDone ? user.name : null;
    final username = user.onboardingDone ? user.username : null;
    await widget.storage.removeWhere(_isAppData);
    await applyDemoProfile(
      widget.storage,
      now: (widget.clock ?? DateTime.now)(),
      name: name,
      username: username,
    );
  });

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return MultiProvider(
      providers: [
        Provider<AppController>.value(value: this),
        Provider<StorageService>.value(value: widget.storage),
        Provider<LessonRepository>.value(value: _lessons),
        ChangeNotifierProvider.value(value: s.settings),
        ChangeNotifierProvider.value(value: s.user),
        ChangeNotifierProvider.value(value: s.progress),
        ChangeNotifierProvider.value(value: s.duels),
        ChangeNotifierProvider.value(value: s.league),
        ChangeNotifierProvider.value(value: s.forum),
        ChangeNotifierProvider.value(value: s.notifications),
        ChangeNotifierProvider.value(value: s.badges),
      ],
      // Una clave nueva rearma toda la app (y vacía la navegación).
      child: KeyedSubtree(key: ValueKey(_generation), child: widget.child),
    );
  }
}
