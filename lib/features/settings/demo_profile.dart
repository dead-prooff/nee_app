import 'dart:convert';

import '../../core/services/storage_service.dart';
import '../../core/utils/dates.dart';

/// Guarda un usuario "en uso" para mostrar la app sin jugar antes:
/// racha de 8 días (hoy ya practicó), 4 lecciones, Liga Plata (subió la
/// semana pasada), duelos ganados (incluso a Doña Rosa) e insignias.
///
/// Las insignias y los avisos no se guardan acá: se generan solos al abrir
/// la app a partir de estos datos.
Future<void> applyDemoProfile(
  StorageService s, {
  required DateTime now,
  String? name,
  String? username,
}) async {
  final today = dayKey(now);
  final thisWeek = weekKey(now);
  final lastWeek = previousWeekKey(thisWeek);
  String daysAgo(int d) =>
      DateTime(now.year, now.month, now.day - d, 19).toIso8601String();

  await Future.wait([
    // Usuario
    s.setBool('user.onboardingDone', true),
    s.setString('user.name', name ?? 'Willy'),
    s.setString('user.username', username ?? 'willy'),
    s.setString('user.authMethod', 'email'),
    s.setString('user.level', 'some'),
    s.setString('user.avatar', 'teju_jagua'),
    s.setString('user.registeredAt', daysAgo(30)),
    s.setBool('user.invitedFriend', true),

    // Progreso: 4 lecciones, racha de 8 días y meta de hoy cumplida.
    s.setStringList('progress.completedLessons', [
      'u1l1',
      'u1l2',
      'u2l1',
      'u2l2',
    ]),
    s.setInt('progress.totalXp', 420),
    s.setInt('progress.xpToday', 25),
    s.setString('progress.xpDate', today),
    s.setInt('progress.streak', 8),
    s.setInt('progress.longestStreak', 8),
    s.setString('progress.lastActiveDate', today),
    s.setInt('progress.goalDays', 6),
    s.setInt('progress.perfectLessons', 2),
    s.setString('progress.dailyGoal', 'regular'),
    s.setInt('progress.weekXp', 150),
    s.setString('progress.weekKey', thisWeek),
    s.setInt('progress.prevWeekXp', 260),
    s.setString('progress.prevWeekKey', lastWeek),

    // Duelos: 6 ganados, entre ellos a Doña Rosa.
    s.setInt('duels.wins', 6),
    s.setInt('duels.draws', 1),
    s.setInt('duels.losses', 2),
    s.setStringList('duels.beaten', ['rosa', 'nico', 'mati']),
    s.setStringList('duels.history', [
      jsonEncode({
        'id': 'demo-nico',
        'friend': 'nico',
        'outcome': 'win',
        'mine': 4,
        'rival': 2,
        'at': daysAgo(1),
      }),
      jsonEncode({
        'id': 'demo-rosa',
        'friend': 'rosa',
        'outcome': 'win',
        'mine': 4,
        'rival': 3,
        'at': daysAgo(0),
      }),
    ]),

    // Liga: subió a Plata la semana pasada.
    s.setString('league.current', 'silver'),
    s.setString('league.best', 'silver'),
    s.setString('league.week', thisWeek),
    s.setStringList('league.results', [
      jsonEncode({
        'week': lastWeek,
        'from': 'bronze',
        'to': 'silver',
        'rank': 2,
      }),
    ]),
  ]);
}
