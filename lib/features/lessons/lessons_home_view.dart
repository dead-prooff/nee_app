import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/lesson_models.dart';
import 'data/lesson_repository.dart';
import 'lesson_screen.dart';

/// Pestaña Inicio: lista de unidades y sus lecciones.
///
/// Versión simple para poder jugar las lecciones; el camino visual, la
/// racha y el XP acumulado llegan en una fase posterior.
class LessonsHomeView extends StatelessWidget {
  const LessonsHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Unit>>(
      future: context.read<LessonRepository>().loadUnits(),
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (i, unit) in units.indexed) ...[
              _UnitSection(number: i + 1, unit: unit),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }
}

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.number, required this.unit});

  final int number;
  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              ExcludeSemantics(
                child: Text(unit.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unidad $number',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(unit.title, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final lesson in unit.lessons) ...[
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.play_arrow_rounded),
              ),
              title: Text(lesson.title, style: theme.textTheme.titleMedium),
              subtitle: Text(
                '${lesson.exercises.length} ejercicios · ${lesson.xp} XP',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
