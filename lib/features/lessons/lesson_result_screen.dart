import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_links.dart';
import '../../core/theme/app_theme.dart';
import 'data/lesson_models.dart';
import 'lesson_screen.dart';

/// Pantalla final: XP ganado, precisión y botón para compartir.
/// Si se acabaron las vidas, ofrece reintentar.
class LessonResultScreen extends StatelessWidget {
  const LessonResultScreen({
    super.key,
    required this.lesson,
    required this.outcome,
  });

  final Lesson lesson;
  final LessonOutcome outcome;

  String get _shareText =>
      '¡Terminé la lección "${lesson.title}" en Ñe\'ẽ y gané '
      '${outcome.xp} XP! 🧉 Aprendé guaraní conmigo: $appUrl';

  Future<void> _share(BuildContext context) async {
    // En tablets el menú de compartir necesita saber de dónde sale.
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;
    final passed = outcome.passed;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          passed ? '🎉' : '💔',
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          passed
                              ? '¡Lección completada!'
                              : 'Te quedaste sin vidas',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        passed ? lesson.title : 'No pasa nada, cada intento suma. ¡Probá de nuevo!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.bolt,
                              iconColor: colors.gold,
                              value: '+${outcome.xp}',
                              label: 'XP ganado',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.track_changes,
                              iconColor: colors.success,
                              value: '${outcome.accuracy}%',
                              label: 'Precisión',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.favorite,
                              iconColor: colors.error,
                              value: '${outcome.livesLeft}',
                              label: 'Vidas',
                            ),
                          ),
                        ],
                      ),
                      if (passed && outcome.mistakes == 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          '¡Sin errores! +${LessonScreen.perfectBonus} XP de bonus',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (passed)
                    Builder(
                      builder: (buttonContext) => OutlinedButton.icon(
                        onPressed: () => _share(buttonContext),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LessonScreen(lesson: lesson),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuar'),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
