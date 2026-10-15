import 'dart:math';

import '../../social/friends.dart';

export '../../social/friends.dart';

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

  /// Tiempo que cuenta para el desempate (si no respondió, el máximo).
  int get timeMs => ms ?? 10000;

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

  /// Gana quien tiene más aciertos. Si empatan, gana quien tardó menos en
  /// total ([myMs] y [rivalMs], en milisegundos); si también empatan en
  /// tiempo, es empate.
  static DuelOutcome compare(
    int mine,
    int rival, {
    required int myMs,
    required int rivalMs,
  }) {
    if (mine != rival) return mine > rival ? win : loss;
    if (myMs != rivalMs) return myMs < rivalMs ? win : loss;
    return draw;
  }
}

/// Un duelo ya jugado (para el historial y los avisos).
class DuelRecord {
  const DuelRecord({
    required this.id,
    required this.friendId,
    required this.outcome,
    required this.myScore,
    required this.rivalScore,
    required this.playedAt,
  });

  final String id;
  final String friendId;
  final DuelOutcome outcome;
  final int myScore;
  final int rivalScore;
  final DateTime playedAt;

  Friend get friend => friendById(friendId);

  Map<String, Object> toJson() => {
    'id': id,
    'friend': friendId,
    'outcome': outcome.name,
    'mine': myScore,
    'rival': rivalScore,
    'at': playedAt.toIso8601String(),
  };

  factory DuelRecord.fromJson(Map<String, dynamic> json) => DuelRecord(
    id: json['id'] as String,
    friendId: json['friend'] as String,
    outcome: DuelOutcome.values.byName(json['outcome'] as String),
    myScore: json['mine'] as int,
    rivalScore: json['rival'] as int,
    playedAt: DateTime.parse(json['at'] as String),
  );
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
