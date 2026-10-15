import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/celebration.dart';
import 'league_models.dart';

/// Festejo al subir de liga: la medalla nueva aparece con un rebote.
class LeagueUpDialog extends StatelessWidget {
  const LeagueUpDialog({super.key, required this.result});

  final LeagueResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final league = result.to;

    return AlertDialog(
      // Con letra grande el contenido puede no entrar: se scrollea.
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Text('🎊', style: TextStyle(fontSize: 32)),
          ),
          PopIn(
            duration: const Duration(milliseconds: 900),
            child: ExcludeSemantics(
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondaryContainer,
                  border: Border.all(color: colors.gold, width: 4),
                ),
                child: Text(league.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Text(
                  'Upéicha!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¡Subiste a Liga ${league.label}!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Terminaste la semana en el puesto ${result.rank}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('¡Vamos!'),
        ),
      ],
    );
  }
}
