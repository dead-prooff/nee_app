import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lessons/data/lesson_models.dart';
import '../lessons/data/lesson_repository.dart';
import '../lessons/lesson_screen.dart';
import '../onboarding/user_provider.dart';
import '../progress/progress_provider.dart';
import 'daily_stats_header.dart';
import 'lesson_path.dart';

/// Pestaña Inicio: racha y meta diaria arriba, y el camino de lecciones
/// por unidades abajo.
///
/// Las lecciones se desbloquean en orden: cada una requiere haber
/// completado la anterior (aunque sea de otra unidad).
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final Future<List<Unit>> _units = context
      .read<LessonRepository>()
      .loadUnits();

  final _currentNodeKey = GlobalKey();
  bool _scrolledToCurrent = false;

  void _open(Lesson lesson) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
  }

  void _showLocked() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Completá la lección anterior para desbloquear esta.'),
        ),
      );
  }

  /// Al abrir, lleva el camino hasta la lección que sigue.
  void _scrollToCurrentOnce() {
    if (_scrolledToCurrent) return;
    _scrolledToCurrent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentNodeKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final level = context.select<UserProvider, StartLevel?>((u) => u.level);

    return FutureBuilder<List<Unit>>(
      future: _units,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No se pudieron cargar las lecciones.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final units = snapshot.data;
        if (units == null) {
          return const Center(child: CircularProgressIndicator());
        }
        _scrollToCurrentOnce();

        final children = <Widget>[];
        var index = 0; // posición global en el camino
        var previousDone = true; // la primera lección siempre está abierta
        var currentFound = false;
        // El nivel elegido en el registro abre de entrada las primeras
        // lecciones (ver StartLevel.unlockedLessons).
        final openByLevel = level?.unlockedLessons ?? 1;

        for (final (u, unit) in units.indexed) {
          final firstLocked = !previousDone && index >= openByLevel;
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: UnitBanner(
                number: u + 1,
                unit: unit,
                completed: unit.lessons
                    .where((l) => progress.isCompleted(l.id))
                    .length,
                locked: firstLocked,
              ),
            ),
          );

          for (final lesson in unit.lessons) {
            final done = progress.isCompleted(lesson.id);
            final NodeState state;
            if (done) {
              state = NodeState.completed;
            } else if (!previousDone && index >= openByLevel) {
              state = NodeState.locked;
            } else if (!currentFound) {
              state = NodeState.current;
              currentFound = true;
            } else {
              state = NodeState.unlocked;
            }
            previousDone = done;

            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Align(
                  alignment: Alignment(PathNode.sway(index) * 0.55, 0),
                  child: PathNode(
                    key: state == NodeState.current ? _currentNodeKey : null,
                    lesson: lesson,
                    number: index + 1,
                    state: state,
                    onTap: state == NodeState.locked
                        ? _showLocked
                        : () => _open(lesson),
                  ),
                ),
              ),
            );
            index++;
          }
          children.add(const SizedBox(height: 8));
        }

        // El encabezado va dentro de la lista: con letra muy grande ocupa
        // mucho y fijo arriba no dejaría lugar al camino.
        // Se arma completo (no una lista "perezosa"): el camino es corto y
        // así el salto automático a la lección que sigue siempre la encuentra.
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DailyStatsHeader(),
              ),
              ...children,
            ],
          ),
        );
      },
    );
  }
}
