import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lessons/data/lesson_models.dart';
import '../lessons/data/lesson_repository.dart';
import '../lessons/lesson_screen.dart';
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

        for (final (u, unit) in units.indexed) {
          final firstLocked = !previousDone;
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
            } else if (!previousDone) {
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

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: DailyStatsHeader(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                children: children,
              ),
            ),
          ],
        );
      },
    );
  }
}
