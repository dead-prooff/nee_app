import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import 'data/duel_models.dart';
import 'data/duel_questions.dart';

/// Récord de duelos y desafíos pendientes (simulados).
///
/// La primera vez llegan 2 desafíos de amigos. Después, si no queda
/// ninguno pendiente, llega uno nuevo por día, para que siempre haya algo
/// para responder.
class DuelProvider extends ChangeNotifier {
  DuelProvider(this._storage, {Random? random, DateTime Function()? clock})
    : _random = random ?? Random(),
      _clock = clock ?? DateTime.now {
    _wins = _storage.getInt(_kWins) ?? 0;
    _draws = _storage.getInt(_kDraws) ?? 0;
    _losses = _storage.getInt(_kLosses) ?? 0;
    _pending = [
      for (final s in _storage.getStringList(_kPending) ?? const <String>[])
        PendingDuel.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    _history = [
      for (final s in _storage.getStringList(_kHistory) ?? const <String>[])
        DuelRecord.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    _refill();
  }

  static const _kWins = 'duels.wins';
  static const _kDraws = 'duels.draws';
  static const _kLosses = 'duels.losses';
  static const _kPending = 'duels.pending';
  static const _kLastRefill = 'duels.lastRefill';
  static const _kHistory = 'duels.history';

  /// Cuántos duelos jugados se recuerdan.
  static const historySize = 20;

  final StorageService _storage;
  final Random _random;
  final DateTime Function() _clock;

  late int _wins;
  late int _draws;
  late int _losses;
  late List<PendingDuel> _pending;
  late List<DuelRecord> _history;

  int get wins => _wins;
  int get draws => _draws;
  int get losses => _losses;
  int get played => _wins + _draws + _losses;

  /// Duelos jugados, el más reciente primero.
  List<DuelRecord> get history => List.unmodifiable(_history.reversed);

  /// Desafíos recibidos, el más nuevo primero.
  List<PendingDuel> get pending => List.unmodifiable(_pending);

  /// Respuestas simuladas de [friend] para un duelo nuevo.
  List<RivalAnswer> simulateRival(Friend friend) => [
    for (var i = 0; i < DuelQuestionBuilder.questionCount; i++)
      RivalAnswer.simulate(friend, _random),
  ];

  void _refill() {
    final now = _clock();
    final today = '${now.year}-${now.month}-${now.day}';
    final lastRefill = _storage.getString(_kLastRefill);

    if (lastRefill == null) {
      // Primera vez: dos desafíos de ejemplo.
      _addPending(friendById('lucia'), now.subtract(const Duration(hours: 2)));
      _addPending(friendById('mati'), now.subtract(const Duration(days: 1)));
    } else if (_pending.isEmpty && lastRefill != today) {
      final others = [...friends]..shuffle(_random);
      _addPending(others.first, now.subtract(const Duration(minutes: 30)));
    } else {
      return;
    }
    _storage.setString(_kLastRefill, today);
    _savePending();
  }

  void _addPending(Friend friend, DateTime receivedAt) {
    _pending.add(
      PendingDuel(
        id: '${friend.id}-${receivedAt.millisecondsSinceEpoch}',
        friendId: friend.id,
        receivedAt: receivedAt,
        rivalAnswers: simulateRival(friend),
      ),
    );
    _pending.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  Future<void> _savePending() => _storage.setStringList(_kPending, [
    for (final p in _pending) jsonEncode(p.toJson()),
  ]);

  /// Guarda el resultado de un duelo. Si respondía a un desafío
  /// pendiente, lo saca de la lista.
  Future<void> recordResult(
    DuelOutcome outcome, {
    required Friend friend,
    required int myScore,
    required int rivalScore,
    String? pendingId,
  }) async {
    final now = _clock();
    _history.add(
      DuelRecord(
        id: '${friend.id}-${now.microsecondsSinceEpoch}',
        friendId: friend.id,
        outcome: outcome,
        myScore: myScore,
        rivalScore: rivalScore,
        playedAt: now,
      ),
    );
    if (_history.length > historySize) {
      _history.removeRange(0, _history.length - historySize);
    }
    switch (outcome) {
      case DuelOutcome.win:
        _wins++;
      case DuelOutcome.draw:
        _draws++;
      case DuelOutcome.loss:
        _losses++;
    }
    if (pendingId != null) _pending.removeWhere((p) => p.id == pendingId);
    notifyListeners();

    await Future.wait([
      _storage.setInt(_kWins, _wins),
      _storage.setInt(_kDraws, _draws),
      _storage.setInt(_kLosses, _losses),
      _savePending(),
      _storage.setStringList(_kHistory, [
        for (final r in _history) jsonEncode(r.toJson()),
      ]),
    ]);
  }
}
