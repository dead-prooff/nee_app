import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/dates.dart';

/// Metas diarias que se pueden elegir: minutos por día y su equivalente en
/// XP (una lección de ~5 minutos da unos 10 XP).
enum DailyGoal {
  relaxed('Tranqui', 5, 10),
  regular('Normal', 10, 20),
  intense('Intenso', 15, 30);

  const DailyGoal(this.label, this.minutes, this.xp);

  final String label;
  final int minutes;
  final int xp;
}

/// Progreso del usuario: lecciones completadas, XP, XP del día y racha.
///
/// Todo se guarda en shared_preferences. Las fechas se guardan como día
/// local (`2026-10-14`), así la racha no depende de la hora.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _completed = (_storage.getStringList(_kCompleted) ?? const []).toSet();
    _totalXp = _storage.getInt(_kTotalXp) ?? 0;
    _xpToday = _storage.getInt(_kXpToday) ?? 0;
    _xpDate = _storage.getString(_kXpDate);
    _streak = _storage.getInt(_kStreak) ?? 0;
    _lastActive = _storage.getString(_kLastActive);
    _weekXp = _storage.getInt(_kWeekXp) ?? 0;
    _weekKey = _storage.getString(_kWeekKey);
    _prevWeekXp = _storage.getInt(_kPrevWeekXp) ?? 0;
    _prevWeekKey = _storage.getString(_kPrevWeekKey);
    _goal = DailyGoal.values.firstWhere(
      (g) => g.name == _storage.getString(_kDailyGoal),
      orElse: () => DailyGoal.regular,
    );
  }

  static const _kCompleted = 'progress.completedLessons';
  static const _kTotalXp = 'progress.totalXp';
  static const _kXpToday = 'progress.xpToday';
  static const _kXpDate = 'progress.xpDate';
  static const _kStreak = 'progress.streak';
  static const _kLastActive = 'progress.lastActiveDate';
  static const _kDailyGoal = 'progress.dailyGoal';
  static const _kWeekXp = 'progress.weekXp';
  static const _kWeekKey = 'progress.weekKey';
  static const _kPrevWeekXp = 'progress.prevWeekXp';
  static const _kPrevWeekKey = 'progress.prevWeekKey';

  final StorageService _storage;
  final DateTime Function() _clock;

  late Set<String> _completed;
  late int _totalXp;
  late int _xpToday;
  String? _xpDate;
  late int _streak;
  String? _lastActive;
  late DailyGoal _goal;

  // XP de la semana actual y de la anterior (para cerrar la liga).
  late int _weekXp;
  String? _weekKey;
  late int _prevWeekXp;
  String? _prevWeekKey;

  String get _today => dayKey(_clock());
  String get _yesterday {
    final now = _clock();
    return dayKey(DateTime(now.year, now.month, now.day - 1));
  }

  bool isCompleted(String lessonId) => _completed.contains(lessonId);
  int get completedCount => _completed.length;

  int get totalXp => _totalXp;

  /// XP ganado hoy (vuelve a 0 al cambiar el día).
  int get xpToday => _xpDate == _today ? _xpToday : 0;

  /// XP ganado esta semana (de lunes a domingo), para la liga.
  int get weekXp => xpOfWeek(weekKey(_clock()));

  /// XP ganado en la semana [key] (solo se recuerdan la actual y la
  /// anterior; para otras devuelve 0).
  int xpOfWeek(String key) {
    if (key == _weekKey) return _weekXp;
    if (key == _prevWeekKey) return _prevWeekXp;
    return 0;
  }

  DailyGoal get goal => _goal;

  /// XP que hay que ganar por día para cumplir la meta.
  int get dailyGoal => _goal.xp;

  void setDailyGoal(DailyGoal goal) {
    _goal = goal;
    _storage.setString(_kDailyGoal, goal.name);
    notifyListeners();
  }

  /// Avance hacia la meta diaria, de 0 a 1.
  double get dailyGoalProgress => (xpToday / dailyGoal).clamp(0.0, 1.0);
  bool get dailyGoalReached => xpToday >= dailyGoal;

  /// Si ya hizo al menos una lección hoy.
  bool get practicedToday => _lastActive == _today;

  /// Días seguidos con al menos una lección o duelo. Si ayer no practicó
  /// (y hoy tampoco), la racha se cortó y vale 0.
  int get streak =>
      _lastActive == _today || _lastActive == _yesterday ? _streak : 0;

  /// Si la racha se cortó (pasó un día entero sin practicar), cuántos días
  /// tenía. 0 si no se perdió ninguna racha.
  int get lostStreak => _lastActive != null && streak == 0 ? _streak : 0;

  /// Último día con práctica (`2026-10-14`), o null si nunca practicó.
  String? get lastActiveDay => _lastActive;

  /// Registra una lección terminada: la marca como completada y suma XP.
  Future<void> completeLesson(String lessonId, {required int xp}) async {
    _completed.add(lessonId);
    await Future.wait([
      _storage.setStringList(_kCompleted, _completed.toList()),
      addXp(xp),
    ]);
  }

  /// Suma XP (de una lección o un duelo) y actualiza la racha.
  Future<void> addXp(int xp) async {
    final today = _today;

    _totalXp += xp;
    _xpToday = xpToday + xp;
    _xpDate = today;

    final week = weekKey(_clock());
    if (_weekKey != week) {
      // Empezó otra semana: la que terminó pasa a ser "la anterior".
      if (_weekKey != null) {
        _prevWeekKey = _weekKey;
        _prevWeekXp = _weekXp;
      }
      _weekKey = week;
      _weekXp = 0;
    }
    _weekXp += xp;

    if (_lastActive != today) {
      _streak = _lastActive == _yesterday ? _streak + 1 : 1;
      _lastActive = today;
    }
    notifyListeners();

    await Future.wait([
      _storage.setInt(_kTotalXp, _totalXp),
      _storage.setInt(_kXpToday, _xpToday),
      _storage.setString(_kXpDate, today),
      _storage.setInt(_kStreak, _streak),
      _storage.setString(_kLastActive, today),
      _storage.setInt(_kWeekXp, _weekXp),
      _storage.setString(_kWeekKey, week),
      _storage.setInt(_kPrevWeekXp, _prevWeekXp),
      if (_prevWeekKey != null)
        _storage.setString(_kPrevWeekKey, _prevWeekKey!),
    ]);
  }
}
