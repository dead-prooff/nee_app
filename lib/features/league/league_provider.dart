import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/dates.dart';
import '../progress/progress_provider.dart';
import 'league_models.dart';

/// Liga semanal: en qué liga está el usuario, la tabla de la semana y los
/// resultados de semanas anteriores.
///
/// Al abrir la app en una semana nueva se cierra la anterior: los 3
/// primeros suben de liga y los 2 últimos bajan.
class LeagueProvider extends ChangeNotifier {
  LeagueProvider(this._storage, this._progress, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _league =
        League.values
            .where((l) => l.name == _storage.getString(_kLeague))
            .firstOrNull ??
        League.bronze;
    _week = _storage.getString(_kWeek);
    _closedWeek = _storage.getString(_kClosedWeek);
    _results = [
      for (final s in _storage.getStringList(_kResults) ?? const <String>[])
        LeagueResult.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    _best =
        League.values
            .where((l) => l.name == _storage.getString(_kBest))
            .firstOrNull ??
        _league;
    _rollover();
    // La tabla depende del XP de la semana: se actualiza al ganar XP.
    _progress.addListener(_onProgress);
  }

  static const _kLeague = 'league.current';
  static const _kWeek = 'league.week';
  static const _kClosedWeek = 'league.closedWeek';
  static const _kResults = 'league.results';
  static const _kBest = 'league.best';

  final StorageService _storage;
  final ProgressProvider _progress;
  final DateTime Function() _clock;

  late League _league;
  String? _week;

  /// Semana ya cerrada a mano (con "Simular cierre"), para no cerrarla dos
  /// veces cuando termine de verdad.
  String? _closedWeek;
  late List<LeagueResult> _results;
  late League _best;

  League get league => _league;

  /// La liga más alta a la que llegó alguna vez.
  League get bestLeague => _league.index > _best.index ? _league : _best;

  /// Resultados de semanas cerradas, el más reciente primero.
  List<LeagueResult> get results => List.unmodifiable(_results.reversed);

  int get daysLeft => daysLeftInWeek(_clock());

  List<LeagueEntry> standings({required String myName}) => buildStandings(
    league: _league,
    week: weekKey(_clock()),
    progress: weekProgress(_clock()),
    myXp: _progress.weekXp,
    myName: myName,
  );

  void _onProgress() {
    _rollover();
    notifyListeners();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    super.dispose();
  }

  /// Si cambió la semana, cierra la anterior.
  void _rollover() {
    final current = weekKey(_clock());
    final previous = _week;
    if (previous == current) return;

    if (previous != null && previous != _closedWeek) {
      _close(week: previous, myXp: _progress.xpOfWeek(previous), progress: 1);
    }
    _week = current;
    _storage.setString(_kWeek, current);
  }

  LeagueResult _close({
    required String week,
    required int myXp,
    required double progress,
  }) {
    final table = buildStandings(
      league: _league,
      week: week,
      progress: progress,
      myXp: myXp,
      myName: '',
    );
    final me = table.firstWhere((e) => e.isMe);
    final to = switch (me.zone) {
      Zone.promotion => _league.next ?? _league,
      Zone.demotion => _league.previous ?? _league,
      Zone.safe => _league,
    };
    final result = LeagueResult(
      week: week,
      from: _league,
      to: to,
      rank: me.rank,
    );

    _league = to;
    if (to.index > _best.index) {
      _best = to;
      _storage.setString(_kBest, to.name);
    }
    _results.add(result);
    _storage.setString(_kLeague, to.name);
    _storage.setStringList(_kResults, [
      for (final r in _results) jsonEncode(r.toJson()),
    ]);
    return result;
  }

  /// Para probar sin esperar al domingo: cierra la semana actual con la
  /// tabla tal como está ahora.
  LeagueResult closeWeekNow() {
    final now = _clock();
    final week = weekKey(now);
    final result = _close(
      week: week,
      myXp: _progress.weekXp,
      progress: weekProgress(now),
    );
    _closedWeek = week;
    _storage.setString(_kClosedWeek, week);
    notifyListeners();
    return result;
  }
}
