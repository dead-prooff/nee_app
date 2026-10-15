import 'dart:math';

import '../social/friends.dart';

enum League {
  bronze('Bronce', '🥉'),
  silver('Plata', '🥈'),
  gold('Oro', '🥇');

  const League(this.label, this.emoji);

  final String label;
  final String emoji;

  League? get next => index + 1 < values.length ? values[index + 1] : null;
  League? get previous => index > 0 ? values[index - 1] : null;

  /// Cuántos suben (los 3 primeros) y cuántos bajan (los 2 últimos) al
  /// terminar la semana.
  int get promoteCount => next == null ? 0 : 3;
  int get demoteCount => previous == null ? 0 : 2;

  /// En ligas más altas los rivales ganan más XP.
  double get xpScale => switch (this) {
    bronze => 1.0,
    silver => 1.3,
    gold => 1.7,
  };
}

enum Zone { promotion, safe, demotion }

/// Una fila de la tabla de la liga.
class LeagueEntry {
  const LeagueEntry({
    required this.rank,
    required this.name,
    required this.emoji,
    required this.xp,
    required this.zone,
    this.friend,
  });

  final int rank;
  final String name;
  final String emoji;
  final int xp;
  final Zone zone;

  /// `null` si es el usuario.
  final Friend? friend;

  bool get isMe => friend == null;
}

/// Hash estable entre plataformas (String.hashCode puede cambiar entre la
/// app y la web), para que cada amigo tenga el mismo XP en todos lados.
///
/// Los productos quedan por debajo de 2^53, así en la web (que usa números
/// de JavaScript) da exactamente lo mismo que en el celular.
int _stableHash(String text) {
  var hash = 17;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

/// XP simulado de [friend] en la semana [week], con [progress] de 0 a 1
/// (cuánto pasó de la semana). Siempre da lo mismo para los mismos datos.
int simulatedFriendXp(
  Friend friend, {
  required String week,
  required League league,
  required double progress,
}) {
  final random = Random(_stableHash('$week/${friend.id}/${league.name}'));
  // XP total al final de la semana: más alto cuanto más sabe.
  final target = (40 + random.nextDouble() * 160) * (0.6 + friend.skill);
  // Algunos arrancan fuerte y otros dejan todo para el final.
  final pace = 0.7 + random.nextDouble() * 0.6;
  final done = min(1.0, progress * pace);
  return (target * league.xpScale * done).round();
}

/// Tabla de la liga: 10 amigos + el usuario, ordenada por XP.
List<LeagueEntry> buildStandings({
  required League league,
  required String week,
  required double progress,
  required int myXp,
  required String myName,
}) {
  final rows = <({String name, String emoji, int xp, Friend? friend})>[
    for (final f in friends)
      (
        name: f.name,
        emoji: f.emoji,
        xp: simulatedFriendXp(
          f,
          week: week,
          league: league,
          progress: progress,
        ),
        friend: f,
      ),
    (name: myName, emoji: '🙂', xp: myXp, friend: null),
  ];
  // Más XP primero; si empata, el usuario va adelante.
  rows.sort((a, b) {
    final byXp = b.xp.compareTo(a.xp);
    if (byXp != 0) return byXp;
    return (a.friend == null ? 0 : 1).compareTo(b.friend == null ? 0 : 1);
  });

  return [
    for (final (i, r) in rows.indexed)
      LeagueEntry(
        rank: i + 1,
        name: r.name,
        emoji: r.emoji,
        xp: r.xp,
        friend: r.friend,
        zone: i < league.promoteCount
            ? Zone.promotion
            : i >= rows.length - league.demoteCount
            ? Zone.demotion
            : Zone.safe,
      ),
  ];
}

/// Cómo terminó una semana de liga.
class LeagueResult {
  const LeagueResult({
    required this.week,
    required this.from,
    required this.to,
    required this.rank,
  });

  final String week;
  final League from;
  final League to;
  final int rank;

  bool get promoted => to.index > from.index;
  bool get demoted => to.index < from.index;

  Map<String, Object> toJson() => {
    'week': week,
    'from': from.name,
    'to': to.name,
    'rank': rank,
  };

  factory LeagueResult.fromJson(Map<String, dynamic> json) => LeagueResult(
    week: json['week'] as String,
    from: League.values.byName(json['from'] as String),
    to: League.values.byName(json['to'] as String),
    rank: json['rank'] as int,
  );
}
