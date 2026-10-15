import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/services/storage_service.dart';
import 'package:nee_app/features/progress/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;
  late DateTime now;

  ProgressProvider create() => ProgressProvider(storage, clock: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
    now = DateTime(2026, 10, 14, 10);
  });

  test('arranca vacío', () {
    final p = create();
    expect(p.streak, 0);
    expect(p.xpToday, 0);
    expect(p.practicedToday, isFalse);
    expect(p.isCompleted('u1l1'), isFalse);
  });

  test('completar una lección suma XP, la marca y empieza la racha', () async {
    final p = create();
    await p.completeLesson('u1l1', xp: 15);

    expect(p.isCompleted('u1l1'), isTrue);
    expect(p.xpToday, 15);
    expect(p.totalXp, 15);
    expect(p.streak, 1);
    expect(p.practicedToday, isTrue);
    expect(p.dailyGoalProgress, 0.75);
  });

  test('dos lecciones el mismo día no duplican la racha', () async {
    final p = create();
    await p.completeLesson('u1l1', xp: 10);
    await p.completeLesson('u1l2', xp: 15);

    expect(p.streak, 1);
    expect(p.xpToday, 25);
    expect(p.dailyGoalReached, isTrue);
    expect(p.dailyGoalProgress, 1.0);
  });

  test('días seguidos suman racha y el XP del día se reinicia', () async {
    final p = create();
    await p.completeLesson('u1l1', xp: 10);

    now = DateTime(2026, 10, 15, 22);
    expect(p.xpToday, 0);
    expect(p.streak, 1, reason: 'todavía puede practicar hoy');
    expect(p.practicedToday, isFalse);

    await p.completeLesson('u1l2', xp: 10);
    expect(p.streak, 2);
    expect(p.xpToday, 10);
    expect(p.totalXp, 20);
  });

  test('la racha cruza fin de mes', () async {
    now = DateTime(2026, 10, 31, 23, 59);
    final p = create();
    await p.completeLesson('a', xp: 10);
    now = DateTime(2026, 11, 1, 0, 1);
    await p.completeLesson('b', xp: 10);
    expect(p.streak, 2);
  });

  test('saltear un día corta la racha', () async {
    final p = create();
    await p.completeLesson('u1l1', xp: 10);

    now = DateTime(2026, 10, 16, 9);
    expect(p.streak, 0);

    await p.completeLesson('u1l2', xp: 10);
    expect(p.streak, 1);
  });

  test('el progreso se guarda y se recupera', () async {
    await create().completeLesson('u1l1', xp: 15);

    final reloaded = create();
    expect(reloaded.isCompleted('u1l1'), isTrue);
    expect(reloaded.xpToday, 15);
    expect(reloaded.totalXp, 15);
    expect(reloaded.streak, 1);
  });
}
