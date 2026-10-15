import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/services/storage_service.dart';
import '../duels/duel_provider.dart';
import '../league/league_models.dart';
import '../league/league_provider.dart';
import '../onboarding/user_provider.dart';
import '../progress/progress_provider.dart';

/// Una insignia. Los textos vienen de `assets/data/insignias.json`.
class BadgeInfo {
  const BadgeInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.howTo,
    required this.celebration,
  });

  final String id;
  final String name;
  final String emoji;

  /// Cómo conseguirla (se muestra mientras está bloqueada).
  final String howTo;

  /// Texto del festejo al desbloquearla.
  final String celebration;
}

/// Textos de las insignias, editables en `assets/data/insignias.json`.
class BadgeCatalog {
  const BadgeCatalog(this.badges);

  static const path = 'assets/data/insignias.json';

  final List<BadgeInfo> badges;

  static Future<BadgeCatalog> load(AssetBundle bundle) async =>
      BadgeCatalog.fromJsonString(await bundle.loadString(path));

  factory BadgeCatalog.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return BadgeCatalog([
      for (final b in json['insignias'] as List)
        BadgeInfo(
          id: (b as Map<String, dynamic>)['id'] as String,
          name: b['nombre'] as String,
          emoji: b['emoji'] as String,
          howTo: b['como'] as String,
          celebration: b['festejo'] as String,
        ),
    ]);
  }
}

/// Insignias ganadas y festejos pendientes de mostrar.
///
/// Cada insignia se gana según lo que pasa en la app (ver [_isEarned]).
class BadgeProvider extends ChangeNotifier {
  BadgeProvider(
    this._storage, {
    required this.catalog,
    required this._progress,
    required this._duels,
    required this._league,
    required this._user,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _unlocked = {
      for (final e in (jsonDecode(
        _storage.getString(_kUnlocked) ?? '{}',
      ) as Map<String, dynamic>).entries)
        e.key: DateTime.parse(e.value as String),
    };
    // La primera vez (por ejemplo, al actualizar la app) se desbloquea en
    // silencio lo que ya se había ganado, sin una catarata de festejos.
    final firstRun = _storage.getBool(_kInitialized) != true;
    _check(celebrate: !firstRun);
    if (firstRun) _storage.setBool(_kInitialized, true);
    for (final source in [_progress, _duels, _league, _user]) {
      source.addListener(_onChange);
    }
  }

  static const _kUnlocked = 'badges.unlocked';
  static const _kInitialized = 'badges.initialized';

  /// Lecciones del curso (para "Ñe'ẽ porã").
  static const totalLessons = 6;

  final StorageService _storage;
  final BadgeCatalog catalog;
  final ProgressProvider _progress;
  final DuelProvider _duels;
  final LeagueProvider _league;
  final UserProvider _user;
  final DateTime Function() _clock;

  late Map<String, DateTime> _unlocked;
  final List<BadgeInfo> _toCelebrate = [];

  List<BadgeInfo> get all => catalog.badges;
  bool isUnlocked(String id) => _unlocked.containsKey(id);
  DateTime? unlockedAt(String id) => _unlocked[id];
  int get unlockedCount => all.where((b) => isUnlocked(b.id)).length;

  /// Próxima insignia recién ganada para festejar, o null.
  BadgeInfo? get nextCelebration =>
      _toCelebrate.isEmpty ? null : _toCelebrate.first;

  /// Se llama después de mostrar el festejo de [nextCelebration].
  void celebrationShown() {
    if (_toCelebrate.isEmpty) return;
    _toCelebrate.removeAt(0);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final source in [_progress, _duels, _league, _user]) {
      source.removeListener(_onChange);
    }
    super.dispose();
  }

  void _onChange() => _check(celebrate: true);

  bool _isEarned(String id) => switch (id) {
    'primer_mborayhu' => _progress.completedCount >= 1,
    'hendy_hina' => _progress.longestStreak >= 3,
    'kavaju_resa' => _progress.longestStreak >= 7,
    'rey_terere' => _progress.goalDays >= 5,
    'mbarete' => _duels.wins >= 5,
    'dona_rosa' => _duels.hasBeaten('rosa'),
    'liga_oro' => _league.bestLeague == League.gold,
    'che_raa' => _user.invitedFriend,
    'chipa_caliente' => _progress.perfectLessons >= 1,
    'jasy_jatere' => _progress.practicedAtSiesta,
    'nee_pora' => _progress.completedCount >= totalLessons,
    'pya_e' => _duels.hasPerfectWin,
    _ => false,
  };

  void _check({required bool celebrate}) {
    var changed = false;
    for (final badge in all) {
      if (isUnlocked(badge.id) || !_isEarned(badge.id)) continue;
      _unlocked[badge.id] = _clock();
      if (celebrate) _toCelebrate.add(badge);
      changed = true;
    }
    if (!changed) return;
    _storage.setString(
      _kUnlocked,
      jsonEncode({
        for (final e in _unlocked.entries) e.key: e.value.toIso8601String(),
      }),
    );
    notifyListeners();
  }
}
