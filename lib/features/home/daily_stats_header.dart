import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../progress/progress_provider.dart';

/// Encabezado de Inicio: racha, XP del día y barra de meta diaria.
class DailyStatsHeader extends StatelessWidget {
  const DailyStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;

    final streak = progress.streak;
    final xp = progress.xpToday;
    const goal = ProgressProvider.dailyGoal;

    final streakText = streak == 1 ? '1 día de racha' : '$streak días de racha';
    final String streakHint;
    if (progress.practicedToday) {
      streakHint = '¡Ya practicaste hoy!';
    } else if (streak > 0) {
      streakHint = 'Hacé una lección hoy para no perderla';
    } else {
      streakHint = 'Hacé una lección para empezar';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: '$streakText. $streakHint',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 36,
                          // Gris hasta que practique hoy, como aviso.
                          color: progress.practicedToday
                              ? colors.fire
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                streakText,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                streakHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: '$xp XP hoy',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 28, color: colors.gold),
                      Text('$xp XP', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              label: progress.dailyGoalReached
                  ? 'Meta diaria cumplida: $xp de $goal XP'
                  : 'Meta diaria: $xp de $goal XP',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progress.dailyGoalReached
                              ? '¡Meta diaria cumplida! 🎉'
                              : 'Meta diaria',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        '${xp.clamp(0, goal)} / $goal XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress.dailyGoalProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        color: colors.gold,
                        backgroundColor: scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
