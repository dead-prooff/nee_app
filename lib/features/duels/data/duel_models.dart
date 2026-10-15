import 'dart:math';

/// Amigo simulado (todavía no hay servidor ni amigos reales).
class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.emoji,
    required this.tagline,
    required this.skill,
  });

  final String id;
  final String name;
  final String username;
  final String emoji;
  final String tagline;

  /// Probabilidad de que responda bien (0 a 1). También lo hace más rápido.
  final double skill;
}

const friends = [
  Friend(
    id: 'lucia',
    name: 'Lucía',
    username: 'lu_asu',
    emoji: '🌸',
    tagline: 'Racha de 12 días',
    skill: 0.8,
  ),
  Friend(
    id: 'mati',
    name: 'Mati',
    username: 'mati10',
    emoji: '⚽',
    tagline: 'Aprendiendo para hablar con su abuela',
    skill: 0.6,
  ),
  Friend(
    id: 'rosa',
    name: 'Doña Rosa',
    username: 'dona_rosa',
    emoji: '🧉',
    tagline: 'Habla guaraní desde chiquita',
    skill: 0.95,
  ),
  Friend(
    id: 'nico',
    name: 'Nico',
    username: 'nico_cde',
    emoji: '🎸',
    tagline: 'Recién empieza',
    skill: 0.45,
  ),
  Friend(
    id: 'caro',
    name: 'Caro',
    username: 'caro_py',
    emoji: '📚',
    tagline: 'Liga Oro esta semana',
    skill: 0.7,
  ),
];

Friend friendById(String id) => friends.firstWhere((f) => f.id == id);

/// Pregunta rápida de opción múltiple.
class DuelQuestion {
  const DuelQuestion({
    required this.instruction,
    required this.prompt,
    required this.options,
    required this.answer,
  });

  final String instruction;
  final String prompt;
  final List<String> options;
  final String answer;
}

/// Respuesta simulada del rival a una pregunta. [ms] es `null` si no llegó
/// a responder antes de que se acabe el tiempo.
class RivalAnswer {
  const RivalAnswer({required this.correct, required this.ms});

  final bool correct;
  final int? ms;

  bool get scored => correct && ms != null;

  /// Simula cómo responde [friend]: cuanto más sabe, más acierta y más
  /// rápido contesta.
  factory RivalAnswer.simulate(
    Friend friend,
    Random random, {
    int limitMs = 10000,
  }) {
    // A veces se le pasa el tiempo.
    if (random.nextDouble() < 0.06) {
      return const RivalAnswer(correct: false, ms: null);
    }
    final slowness = 1.25 - friend.skill; // 0.3 (rápido) a 0.8 (lento)
    final ms = (1800 + random.nextDouble() * 9000 * slowness).round();
    return RivalAnswer(
      correct: random.nextDouble() < friend.skill,
      ms: min(ms, limitMs - 500),
    );
  }

  List<Object?> toJson() => [correct, ms];

  factory RivalAnswer.fromJson(List<dynamic> json) =>
      RivalAnswer(correct: json[0] as bool, ms: json[1] as int?);
}

/// Desafío recibido de un amigo que ya jugó su parte.
class PendingDuel {
  const PendingDuel({
    required this.id,
    required this.friendId,
    required this.receivedAt,
    required this.rivalAnswers,
  });

  final String id;
  final String friendId;
  final DateTime receivedAt;
  final List<RivalAnswer> rivalAnswers;

  Friend get friend => friendById(friendId);

  Map<String, Object?> toJson() => {
    'id': id,
    'friend': friendId,
    'receivedAt': receivedAt.toIso8601String(),
    'rival': [for (final a in rivalAnswers) a.toJson()],
  };

  factory PendingDuel.fromJson(Map<String, dynamic> json) => PendingDuel(
    id: json['id'] as String,
    friendId: json['friend'] as String,
    receivedAt: DateTime.parse(json['receivedAt'] as String),
    rivalAnswers: [
      for (final a in json['rival'] as List)
        RivalAnswer.fromJson(a as List<dynamic>),
    ],
  );
}

enum DuelOutcome {
  win('¡Ganaste!', '🏆', 15),
  draw('¡Empate!', '🤝', 8),
  loss('Perdiste', '😅', 3);

  const DuelOutcome(this.title, this.emoji, this.xp);

  final String title;
  final String emoji;

  /// XP que da el duelo (perder también suma un poco por participar).
  final int xp;

  static DuelOutcome compare(int mine, int rival) => mine > rival
      ? win
      : mine < rival
      ? loss
      : draw;
}

/// Todo lo necesario para jugar un duelo.
class DuelSetup {
  const DuelSetup({
    required this.friend,
    required this.questions,
    required this.rivalAnswers,
    this.pendingId,
  });

  final Friend friend;
  final List<DuelQuestion> questions;
  final List<RivalAnswer> rivalAnswers;

  /// Si es la respuesta a un desafío pendiente.
  final String? pendingId;
}
