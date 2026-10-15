import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/dates.dart';
import '../duels/data/duel_models.dart';
import '../duels/duel_provider.dart';
import '../league/league_provider.dart';
import '../progress/progress_provider.dart';
import 'messages.dart';
import 'notification_models.dart';

/// Avisos de la app (simulados: todavía no hay notificaciones push).
///
/// Se generan según lo que pasa en la app, con textos al azar de
/// `assets/data/mensajes.json`:
/// - Duelos: desafío recibido, duelo ganado / perdido / empatado.
/// - Racha: en peligro (hoy no practicaste), perdida, activa del día (o
///   "kavaju resa" desde 7 días) y meta diaria cumplida.
/// - Liga: subiste, bajaste o te mantuviste al cerrar la semana.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(
    this._storage, {
    required this._messages,
    required this._progress,
    required this._duels,
    required this._league,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random() {
    _items = [
      for (final s in _storage.getStringList(_kItems) ?? const <String>[])
        AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    _handled = (_storage.getStringList(_kHandled) ?? const []).toSet();
    if (_storage.getBool(_kSeeded) != true) {
      _seed();
      _save();
    }
    sync();
    for (final source in [_progress, _duels, _league]) {
      source.addListener(sync);
    }
  }

  static const _kItems = 'notifications.items';
  static const _kHandled = 'notifications.handled';
  static const _kSeeded = 'notifications.seeded';
  static const _kRecent = 'notifications.recent';

  static const maxItems = 50;
  static const _maxHandled = 300;

  final StorageService _storage;
  final Messages _messages;
  final ProgressProvider _progress;
  final DuelProvider _duels;
  final LeagueProvider _league;
  final DateTime Function() _clock;
  final Random _random;

  late List<AppNotification> _items;

  /// Eventos que ya generaron aviso (para no avisar dos veces).
  late Set<String> _handled;

  /// Avisos del más nuevo al más viejo.
  List<AppNotification> get items => List.unmodifiable(_items);

  List<AppNotification> ofType(NotificationType? type) =>
      type == null ? items : _items.where((n) => n.type == type).toList();

  int get unreadCount => _items.where((n) => !n.read).length;
  int unreadOf(NotificationType? type) =>
      ofType(type).where((n) => !n.read).length;

  @override
  void dispose() {
    for (final source in [_progress, _duels, _league]) {
      source.removeListener(sync);
    }
    super.dispose();
  }

  /// Avisos de bienvenida la primera vez, para que la pantalla no arranque
  /// vacía.
  void _seed() {
    final league = _league.league;
    _emit(
      'welcome-league',
      NotificationType.league,
      MessageKind.welcomeLeague,
      {'liga': league.label, 'emoji': league.emoji},
    );
    _emit(
      'welcome-streak',
      NotificationType.streak,
      MessageKind.welcomeStreak,
      const {},
    );
    _storage.setBool(_kSeeded, true);
  }

  /// Crea un aviso para el evento [key] si todavía no se avisó. Devuelve
  /// si se creó.
  bool _emit(
    String key,
    NotificationType type,
    MessageKind kind,
    Map<String, Object> vars, {
    DateTime? at,
  }) {
    if (_handled.contains(key)) return false;
    _handled.add(key);

    final index = _pickMessage(kind);
    final text = _messages.render(kind, index, vars);
    _items.add(
      AppNotification(
        id: key,
        type: type,
        title: text.title,
        body: text.body,
        createdAt: at ?? _clock(),
      ),
    );
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
    return true;
  }

  /// Elige un mensaje al azar sin repetir los últimos usados de ese tipo.
  int _pickMessage(MessageKind kind) {
    final key = '$_kRecent.${kind.key}';
    final recent = [
      for (final s in _storage.getStringList(key) ?? const <String>[])
        int.parse(s),
    ];
    final index = _messages.pick(kind, _random, recent: recent);
    // Se recuerdan los últimos (hasta 3, y siempre dejando al menos uno
    // libre para elegir).
    final keep = min(3, max(0, _messages.of(kind).length - 1));
    final updated = [...recent, index];
    _storage.setStringList(key, [
      for (final i in updated.skip(max(0, updated.length - keep))) '$i',
    ]);
    return index;
  }

  /// Revisa si pasó algo que merezca un aviso nuevo.
  void sync() {
    final now = _clock();
    final today = dayKey(now);
    var changed = false;

    // --- Duelos recibidos. Si ya se jugó, el aviso queda leído.
    final pendingIds = {for (final d in _duels.pending) d.id};
    for (final duel in _duels.pending) {
      changed |= _emit(
        'duel-${duel.id}',
        NotificationType.duel,
        MessageKind.duelReceived,
        {'nombre': duel.friend.name},
        at: duel.receivedAt,
      );
    }
    for (final (i, n) in _items.indexed) {
      if (!n.read &&
          n.id.startsWith('duel-') &&
          !pendingIds.contains(n.id.substring(5))) {
        _items[i] = n.markRead();
        changed = true;
      }
    }

    // --- Duelos jugados.
    for (final r in _duels.history.reversed) {
      changed |= _emit(
        'duelres-${r.id}',
        NotificationType.duel,
        switch (r.outcome) {
          DuelOutcome.win => MessageKind.duelWon,
          DuelOutcome.loss => MessageKind.duelLost,
          DuelOutcome.draw => MessageKind.duelDraw,
        },
        {'nombre': r.friend.name, 'marcador': '${r.myScore} a ${r.rivalScore}'},
        at: r.playedAt,
      );
    }

    // --- Racha.
    String daysText(int d) => d == 1 ? 'día' : 'días';
    final lost = _progress.lostStreak;
    if (lost > 0) {
      changed |= _emit(
        'streak-lost-${_progress.lastActiveDay}',
        NotificationType.streak,
        MessageKind.streakLost,
        {'dias': lost, 'dias_txt': daysText(lost)},
      );
    }
    final streak = _progress.streak;
    if (streak > 0 && !_progress.practicedToday) {
      changed |= _emit(
        'streak-danger-$today',
        NotificationType.streak,
        MessageKind.streakDanger,
        {'dias': streak, 'dias_txt': daysText(streak)},
      );
    }
    if (_progress.practicedToday) {
      changed |= _emit(
        'streak-active-$today',
        NotificationType.streak,
        streak >= 7 ? MessageKind.streakKavaju : MessageKind.streakActive,
        {'dias': streak, 'dias_txt': daysText(streak)},
      );
    }
    if (_progress.dailyGoalReached) {
      changed |= _emit(
        'goal-$today',
        NotificationType.streak,
        MessageKind.goalReached,
        {'meta': _progress.dailyGoal},
      );
    }

    // --- Liga (resultados del más viejo al más nuevo).
    final results = _league.results.reversed.toList();
    for (final (i, r) in results.indexed) {
      changed |= _emit(
        'league-${r.week}-$i',
        NotificationType.league,
        r.promoted
            ? MessageKind.leagueUp
            : r.demoted
            ? MessageKind.leagueDown
            : MessageKind.leagueStay,
        {'liga': r.to.label, 'emoji': r.to.emoji, 'puesto': r.rank},
      );
    }

    if (changed) {
      _save();
      notifyListeners();
    }
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].markRead();
    _save();
    notifyListeners();
  }

  void markAllRead({NotificationType? type}) {
    var changed = false;
    for (final (i, n) in _items.indexed) {
      if (!n.read && (type == null || n.type == type)) {
        _items[i] = n.markRead();
        changed = true;
      }
    }
    if (!changed) return;
    _save();
    notifyListeners();
  }

  void _save() {
    if (_handled.length > _maxHandled) {
      _handled = _handled.skip(_handled.length - _maxHandled).toSet();
    }
    _storage.setStringList(_kItems, [
      for (final n in _items) jsonEncode(n.toJson()),
    ]);
    _storage.setStringList(_kHandled, _handled.toList());
  }
}
